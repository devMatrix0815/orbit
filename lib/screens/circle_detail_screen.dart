import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/circle_model.dart';
import '../constants/interests.dart';
import 'invite_members_screen.dart';
import '../widgets/chat_widget.dart';
import 'circle_settings_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/user_badges.dart';

class CircleDetailScreen extends StatefulWidget {
  final Circle circle;
  final bool previewMode;

  const CircleDetailScreen({
    super.key,
    required this.circle,
    this.previewMode = false,
  });

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late String _circleName;
  bool _requestSent = false;
  bool _requestLoading = false;
  bool _joinLoading = false;

  @override
  void initState() {
    super.initState();
    _circleName = widget.circle.name;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (!widget.circle.members.contains(uid) &&
        widget.circle.joinMode == 'request') {
      _checkExistingRequest(uid);
    }
  }

  Future<void> _checkExistingRequest(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('joinRequests')
        .where('circleId', isEqualTo: widget.circle.id)
        .where('requestingUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (mounted) setState(() => _requestSent = snap.docs.isNotEmpty);
  }

  Future<void> _joinDirectly() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _joinLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({
            'members': FieldValue.arrayUnion([uid]),
            'memberCount': FieldValue.increment(1),
          });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _joinLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorJoining)),
        );
      }
    }
  }

  Future<void> _sendJoinRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _requestLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('joinRequests').add({
        'circleId': widget.circle.id,
        'circleName': _circleName,
        'circleImageBase64': widget.circle.imageBase64,
        'circleImageUrl': widget.circle.imageUrl.isNotEmpty
            ? widget.circle.imageUrl
            : null,
        'requestingUserId': currentUser.uid,
        'requestingDisplayName':
            userData['displayName'] ?? currentUser.displayName ?? l10n.unknown,
        'requestingUserImageBase64': userData['profileImageBase64'],
        'requestingUserImageUrl': userData['profileImageUrl'],
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'adminId': widget.circle.createdBy,
      });
      if (mounted) setState(() => _requestSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.requestSentSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requestLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSendingRequest)),
        );
      }
    } finally {
      if (mounted) setState(() => _requestLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.confirmLeave(_circleName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.leave),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLeavingGroup)),
        );
      }
    }
  }

  void _openInviteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteMembersScreen(
          circleId: widget.circle.id,
          circleName: _circleName,
          circleImageBase64: widget.circle.imageBase64,
          circleImageUrl: widget.circle.imageUrl.isNotEmpty
              ? widget.circle.imageUrl
              : null,
          members: widget.circle.members,
        ),
      ),
    );
  }

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

  Future<void> _showMembersSheet() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCreator = currentUid == widget.circle.createdBy;

    final doc = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circle.id)
        .get();
    final memberUids = List<String>.from(doc.data()?['members'] ?? []);
    final operatorUids = Set<String>.from(doc.data()?['operators'] ?? []);

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
        initialOperators: operatorUids,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMember = widget.circle.members.contains(currentUid);
    final isCreator = currentUid == widget.circle.createdBy;

    if (!isMember || widget.previewMode) {
      return _buildNonMemberView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_circleName),
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
            itemBuilder: (context) {
              final l = AppLocalizations.of(context)!;
              return isCreator
                  ? [
                      PopupMenuItem(
                        value: 'members',
                        child: ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: Text(l.members),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'invites',
                        child: ListTile(
                          leading: const Icon(Icons.person_add_outlined),
                          title: Text(l.invitePeople),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: Text(l.settings),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ]
                  : [
                      PopupMenuItem(
                        value: 'members',
                        child: ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: Text(l.members),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'leave',
                        child: ListTile(
                          leading: const Icon(Icons.exit_to_app,
                              color: Colors.red),
                          title: Text(
                            l.leaveGroup,
                            style: const TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ];
            },
          ),
        ],
      ),
      body: SizedBox.expand(
        child:
            ChatWidget(circleId: widget.circle.id, circleName: _circleName),
      ),
    );
  }

  Widget _buildNonMemberView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final circle = widget.circle;
    final imageBytes =
        circle.imageBase64 != null ? base64Decode(circle.imageBase64!) : null;
    final primary = Theme.of(context).colorScheme.primary;

    Widget joinButton;
    switch (circle.joinMode) {
      case 'open':
        joinButton = _joinLoading
            ? const CircularProgressIndicator()
            : FilledButton.icon(
                onPressed: _joinDirectly,
                icon: const Icon(Icons.login),
                label: Text(l10n.joinGroup),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              );
      case 'request':
        if (_requestSent) {
          joinButton = OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_top_outlined),
            label: Text(l10n.requestSent),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          );
        } else {
          joinButton = _requestLoading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  onPressed: _sendJoinRequest,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(l10n.sendJoinRequest),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                );
        }
      default:
        joinButton = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock_outline),
          label: Text(l10n.inviteOnly),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_circleName)),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Container(
                    color: primary.withValues(alpha: 0.15),
                    child: Icon(Icons.group, size: 64, color: primary),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _circleName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      l10n.memberCount(circle.memberCount),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      circle.joinMode == 'open'
                          ? Icons.lock_open_outlined
                          : circle.joinMode == 'request'
                              ? Icons.how_to_reg_outlined
                              : Icons.lock_outlined,
                      size: 14,
                      color: circle.joinMode == 'open'
                          ? Colors.green
                          : circle.joinMode == 'request'
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      circle.joinMode == 'open'
                          ? l10n.open
                          : circle.joinMode == 'request'
                              ? l10n.requestMode
                              : l10n.private,
                      style: TextStyle(
                        color: circle.joinMode == 'open'
                            ? Colors.green
                            : circle.joinMode == 'request'
                                ? Colors.orange
                                : Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (circle.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(circle.description),
                ],
                if (circle.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: circle.tags
                        .map((tag) => Chip(
                              label: Text(
                                  getInterestName(tag, l10n),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )),
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),
                joinButton,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersSheet extends StatefulWidget {
  final String circleId;
  final String creatorUid;
  final List<String> memberUids;
  final String currentUid;
  final bool isCreator;
  final Set<String> initialOperators;

  const _MembersSheet({
    required this.circleId,
    required this.creatorUid,
    required this.memberUids,
    required this.currentUid,
    required this.isCreator,
    required this.initialOperators,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  final Set<String> _selected = {};
  late Set<String> _operators;
  late String _creatorUid;
  late bool _isSelfAdmin;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _operators = Set.from(widget.initialOperators);
    _creatorUid = widget.creatorUid;
    _isSelfAdmin = widget.isCreator;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.memberUids.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final docs = await Future.wait(
      widget.memberUids.map(
        (uid) => FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ),
    );
    setState(() {
      _members = docs.map((doc) {
        final data = doc.data() ?? {};
        return {'uid': doc.id, ...data};
      }).toList();

      _members.sort((a, b) {
        if (a['uid'] == _creatorUid) return -1;
        if (b['uid'] == _creatorUid) return 1;
        final aOp = _operators.contains(a['uid']) ? 0 : 1;
        final bOp = _operators.contains(b['uid']) ? 0 : 1;
        if (aOp != bOp) return aOp - bOp;
        return ((a['displayName'] as String?) ?? '').compareTo(
          (b['displayName'] as String?) ?? '',
        );
      });
      _isLoading = false;
    });
  }

  bool _isSelectable(String uid) =>
      uid != widget.currentUid && uid != _creatorUid;

  void _exitSelection() => setState(() {
        _selectionMode = false;
        _selected.clear();
      });

  Future<void> _removeSelected() async {
    setState(() => _isBusy = true);
    try {
      final toRemove = _selected.toList();
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
            'members': FieldValue.arrayRemove(toRemove),
            'memberCount': FieldValue.increment(-toRemove.length),
            'operators': FieldValue.arrayRemove(toRemove),
          });
      setState(() {
        _members.removeWhere((m) => _selected.contains(m['uid'] as String));
        _operators.removeAll(toRemove);
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorRemoving)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _makeOperator() async {
    final uid = _selected.first;
    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
            'operators': FieldValue.arrayUnion([uid]),
          });
      setState(() {
        _operators.add(uid);
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorChangingRole)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removeOperator() async {
    final uid = _selected.first;
    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
            'operators': FieldValue.arrayRemove([uid]),
          });
      setState(() {
        _operators.remove(uid);
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorChangingRole)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _banSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(count == 1 ? l10n.banMember : l10n.banMembers(count)),
        content: Text(
          count == 1
              ? l10n.banConfirmSingle
              : l10n.banConfirmMultiple(count),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.ban),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final toBan = _selected.toList();
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
            'banned': FieldValue.arrayUnion(toBan),
            'members': FieldValue.arrayRemove(toBan),
            'memberCount': FieldValue.increment(-toBan.length),
            'operators': FieldValue.arrayRemove(toBan),
          });
      setState(() {
        _members.removeWhere((m) => _selected.contains(m['uid'] as String));
        _operators.removeAll(toBan);
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorBanning)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _transferAdmin() async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _selected.first;
    final memberData = _members.firstWhere((m) => m['uid'] == uid);
    final name = memberData['displayName'] as String? ?? l10n.unknown;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transferAdminTitle),
        content: Text(l10n.transferAdminConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.transfer),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({
            'createdBy': uid,
            'operators': FieldValue.arrayRemove([uid]),
          });
      setState(() {
        _creatorUid = uid;
        _isSelfAdmin = false;
        _operators.remove(uid);
        _members.sort((a, b) {
          if (a['uid'] == _creatorUid) return -1;
          if (b['uid'] == _creatorUid) return 1;
          final aOp = _operators.contains(a['uid']) ? 0 : 1;
          final bOp = _operators.contains(b['uid']) ? 0 : 1;
          if (aOp != bOp) return aOp - bOp;
          return ((a['displayName'] as String?) ?? '').compareTo(
            (b['displayName'] as String?) ?? '',
          );
        });
        _selected.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorTransferring)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Widget _buildAvatar(
    Map<String, dynamic> member,
    bool isSelected,
    bool selectable,
  ) {
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
      avatar =
          const CircleAvatar(child: Icon(Icons.person_outline, size: 20));
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

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final effectiveColor = onTap == null
        ? Theme.of(context).disabledColor
        : (color ?? Theme.of(context).colorScheme.onSurface);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveColor, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: effectiveColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final singleSelected = _selected.length == 1 ? _selected.first : null;
    final singleIsOperator =
        singleSelected != null && _operators.contains(singleSelected);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_selectionMode) ...[
                Text(
                  l10n.selectedCount(_selected.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _exitSelection,
                  child: Text(l10n.cancel),
                ),
              ] else
                Text(
                  l10n.membersWithCount(_members.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

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
                    member['displayName'] as String? ?? l10n.unknown;
                final badges =
                    List<String>.from(member['badges'] ?? []);
                final isAdmin = uid == _creatorUid;
                final isOperator = _operators.contains(uid);
                final isMe = uid == widget.currentUid;
                final selectable =
                    _isSelectable(uid) && _isSelfAdmin;
                final isSelected = _selected.contains(uid);

                return GestureDetector(
                  onLongPress: selectable && !_selectionMode
                      ? () => setState(() {
                            _selectionMode = true;
                            _selected.add(uid);
                          })
                      : null,
                  onTap: _selectionMode
                      ? (selectable
                          ? () => setState(() {
                                if (isSelected) {
                                  _selected.remove(uid);
                                  if (_selected.isEmpty) _selectionMode = false;
                                } else {
                                  _selected.add(uid);
                                }
                              })
                          : null)
                      : () => openUserProfile(context, uid),
                  child: ListTile(
                    leading: _buildAvatar(member, isSelected, selectable),
                    title: nameWithBadges(name, badges: badges),
                    subtitle: isAdmin
                        ? Text(l10n.admin,
                            style: const TextStyle(fontSize: 12))
                        : isOperator
                        ? Text(
                            l10n.operator,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : isMe
                        ? Text(l10n.you,
                            style: const TextStyle(fontSize: 12))
                        : null,
                    selected: isSelected,
                  ),
                );
              },
            ),
          ),

        if (_selectionMode && _isSelfAdmin && _selected.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                _buildAction(
                  icon: Icons.person_remove_outlined,
                  label: l10n.removeCount(_selected.length),
                  onTap: _isBusy ? null : _removeSelected,
                  color: Colors.red,
                ),
                _buildAction(
                  icon: Icons.block,
                  label: l10n.ban,
                  onTap: _isBusy ? null : _banSelected,
                  color: Colors.orange,
                ),
                if (singleSelected != null) ...[
                  singleIsOperator
                      ? _buildAction(
                          icon: Icons.shield_outlined,
                          label: l10n.removeOperatorLabel,
                          onTap: _isBusy ? null : _removeOperator,
                        )
                      : _buildAction(
                          icon: Icons.shield,
                          label: l10n.makeOperatorLabel,
                          onTap: _isBusy ? null : _makeOperator,
                        ),
                  _buildAction(
                    icon: Icons.admin_panel_settings_outlined,
                    label: l10n.transferAdminLabel,
                    onTap: _isBusy ? null : _transferAdmin,
                  ),
                ],
              ],
            ),
          ),
        ] else
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}
