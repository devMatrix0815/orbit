import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/circle_model.dart';
import 'invite_members_screen.dart';
import 'circle_settings_screen.dart';


// circle detail screen with options menu
class CircleDetailScreen extends StatefulWidget {
  final Circle circle;

  const CircleDetailScreen({super.key, required this.circle});

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late String _circleName;

  @override
  void initState() {
    super.initState();
    _circleName = widget.circle.name;
  }

  // leave group with confirmation dialog
  Future<void> _leaveGroup() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppe verlassen'),
        content: Text('Möchtest du "$_circleName" wirklich verlassen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({
        'members': FieldValue.arrayRemove([currentUid]),
        'memberCount': FieldValue.increment(-1),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Verlassen der Gruppe.')),
        );
      }
    }
  }

  // open invite members screen
  void _openInviteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteMembersScreen(
          circleId: widget.circle.id,
          circleName: _circleName,
          circleImageBase64: widget.circle.imageBase64,
          circleImageUrl: widget.circle.imageUrl.isNotEmpty ? widget.circle.imageUrl : null,
          members: widget.circle.members,
        ),
      ),
    );
  }

  // open circle settings and handle return values
  Future<void> _openSettingsScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CircleSettingsScreen(
          circle: widget.circle,
          initialName: _circleName,
        ),
      ),
    );
    if (result == null) return;
    if (result['deleted'] == true) {
      if (mounted) Navigator.pop(context, true);
    } else if (result['name'] != null) {
      setState(() => _circleName = result['name'] as String);
    }
  }

  // show members bottom sheet
  Future<void> _showMembersSheet() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCreator = currentUid == widget.circle.createdBy;

    // fresh member list from firestore
    final doc = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circle.id)
        .get();
    final memberUids = List<String>.from(doc.data()?['members'] ?? []);

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MembersSheet(
        circleId: widget.circle.id,
        creatorUid: widget.circle.createdBy,
        memberUids: memberUids,
        currentUid: currentUid,
        isCreator: isCreator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUid == widget.circle.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(_circleName),

        // options menu - different for creator vs member
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'members':
                  _showMembersSheet();
                case 'invites':
                  _openInviteScreen();
                case 'settings':
                  _openSettingsScreen();
                case 'leave':
                  _leaveGroup();
              }
            },
            itemBuilder: (context) => isCreator
                ? [
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people_outline),
                        title: Text('Mitglieder'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'invites',
                      child: ListTile(
                        leading: Icon(Icons.person_add_outlined),
                        title: Text('Leute einladen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Einstellungen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ]
                : [
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people_outline),
                        title: Text('Mitglieder'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.red),
                        title: Text(
                          'Gruppe verlassen',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
          ),
        ],
      ),
      body: const SizedBox.expand(),
    );
  }
}

// members bottom sheet
class _MembersSheet extends StatefulWidget {
  final String circleId;
  final String creatorUid;
  final List<String> memberUids;
  final String currentUid;
  final bool isCreator;

  const _MembersSheet({
    required this.circleId,
    required this.creatorUid,
    required this.memberUids,
    required this.currentUid,
    required this.isCreator,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  final Set<String> _selected = {};
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // load member profiles from firestore
  Future<void> _loadMembers() async {
    if (widget.memberUids.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final docs = await Future.wait(
      widget.memberUids.map(
        (uid) =>
            FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ),
    );
    setState(() {
      _members = docs.map((doc) {
        final data = doc.data() ?? {};
        return {'uid': doc.id, ...data};
      }).toList();

      // creator first, then alphabetical
      _members.sort((a, b) {
        if (a['uid'] == widget.creatorUid) return -1;
        if (b['uid'] == widget.creatorUid) return 1;
        return ((a['displayName'] as String?) ?? '')
            .compareTo((b['displayName'] as String?) ?? '');
      });
      _isLoading = false;
    });
  }

  bool _isSelectable(String uid) =>
      uid != widget.currentUid && uid != widget.creatorUid;

  // remove selected members from circle
  Future<void> _removeSelected() async {
    setState(() => _isRemoving = true);
    try {
      final toRemove = _selected.toList();
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
        'members': FieldValue.arrayRemove(toRemove),
        'memberCount': FieldValue.increment(-toRemove.length),
      });
      setState(() {
        _members.removeWhere(
          (m) => _selected.contains(m['uid'] as String),
        );
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Entfernen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  // avatar with selection overlay when in selection mode
  Widget _buildAvatar(Map<String, dynamic> member, bool isSelected, bool selectable) {
    final base64Str = member['profileImageBase64'] as String?;
    final url = member['profileImageUrl'] as String?;

    Widget avatar;
    if (base64Str != null && base64Str.isNotEmpty) {
      avatar = CircleAvatar(
        backgroundImage: MemoryImage(base64Decode(base64Str)),
      );
    } else if (url != null && url.isNotEmpty) {
      avatar = CircleAvatar(backgroundImage: NetworkImage(url));
    } else {
      avatar = const CircleAvatar(child: Icon(Icons.person_outline, size: 20));
    }

    if (!_selectionMode || !selectable) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned.fill(
          child: ClipOval(
            child: ColoredBox(
              color: isSelected
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.black.withValues(alpha: 0.25),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // drag handle
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        // header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_selectionMode) ...[
                Text(
                  '${_selected.length} ausgewählt',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectionMode = false;
                    _selected.clear();
                  }),
                  child: const Text('Abbrechen'),
                ),
              ] else
                Text(
                  'Mitglieder (${_members.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // member list
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final uid = member['uid'] as String;
                final name =
                    member['displayName'] as String? ?? 'Unbekannt';
                final isAdmin = uid == widget.creatorUid;
                final isMe = uid == widget.currentUid;
                final selectable = _isSelectable(uid) && widget.isCreator;
                final isSelected = _selected.contains(uid);

                return GestureDetector(
                  onLongPress: selectable && !_selectionMode
                      ? () => setState(() {
                            _selectionMode = true;
                            _selected.add(uid);
                          })
                      : null,
                  onTap: _selectionMode && selectable
                      ? () => setState(() {
                            if (isSelected) {
                              _selected.remove(uid);
                              if (_selected.isEmpty) {
                                _selectionMode = false;
                              }
                            } else {
                              _selected.add(uid);
                            }
                          })
                      : null,
                  child: ListTile(
                    leading: _buildAvatar(member, isSelected, selectable),
                    title: Text(name),
                    subtitle: isAdmin
                        ? const Text(
                            'Admin',
                            style: TextStyle(fontSize: 12),
                          )
                        : isMe
                            ? const Text(
                                'Du',
                                style: TextStyle(fontSize: 12),
                              )
                            : null,
                    selected: isSelected,
                  ),
                );
              },
            ),
          ),

        // remove button
        if (_selectionMode && widget.isCreator && _selected.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: _isRemoving ? null : _removeSelected,
                child: _isRemoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${_selected.length} entfernen',
                      ),
              ),
            ),
          )
        else
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}
