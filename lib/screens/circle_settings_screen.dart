import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/circle_model.dart';
import '../constants/interests.dart';
import '../widgets/user_badges.dart';
import 'circle_detail_screen.dart';

class CircleSettingsScreen extends StatefulWidget {
  final Circle circle;
  final String initialName;

  const CircleSettingsScreen({
    super.key,
    required this.circle,
    required this.initialName,
  });

  @override
  State<CircleSettingsScreen> createState() => _CircleSettingsScreenState();
}

class _CircleSettingsScreenState extends State<CircleSettingsScreen> {
  late String _name;
  late List<String> _tags;
  late String _joinMode;
  Uint8List? _imageBytes;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _tags = List<String>.from(widget.circle.tags);
    _joinMode = widget.circle.joinMode;

    if (widget.circle.imageBase64 != null) {
      _imageBytes = base64Decode(widget.circle.imageBase64!);
    }
  }

  Future<void> _showRenameDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l.changeName),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.newName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l.save),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({'name': newName});
      setState(() => _name = newName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorRenaming)),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
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
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 65,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({'imageBase64': base64Encode(bytes)});
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorChangingImage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _showInterestsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InterestsSheet(
        current: Set<String>.from(_tags),
        onSave: (selected) async {
          await FirebaseFirestore.instance
              .collection('circles')
              .doc(widget.circle.id)
              .update({'tags': selected.toList()});
          setState(() => _tags = selected.toList());
        },
      ),
    );
  }

  Future<void> _showBannedSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BannedSheet(circleId: widget.circle.id),
    );
  }

  Future<void> _deleteGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l.deleteGroup),
          content: Text(l.confirmDeleteGroup(_name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final invites = await FirebaseFirestore.instance
          .collection('invites')
          .where('circleId', isEqualTo: widget.circle.id)
          .get();
      for (final doc in invites.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .delete();

      if (mounted) Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDeleting)),
        );
      }
    }
  }

  Future<void> _setJoinMode(String mode) async {
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({'joinMode': mode});
      setState(() => _joinMode = mode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSaving)),
        );
      }
    }
  }

  void _popWithResult() {
    Navigator.pop(context, {'name': _name, 'tags': _tags});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithResult();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.groupSettings),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _popWithResult,
          ),
        ),
        body: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: Color(0xFFFF9966),
                            child: SizedBox.expand(),
                          ),
                    Container(
                      color: Colors.black38,
                      child: _isPickingImage
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.changeImage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.changeName),
              subtitle: Text(_name),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showRenameDialog,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.interests,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onPressed: _showInterestsSheet,
                        label: Text(
                          l10n.edit,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_tags.isEmpty)
                    Text(
                      l10n.noInterestsAdded,
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          label: Text(
                            getInterestName(tag, l10n),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.joinMode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _JoinModeOption(
              icon: Icons.lock_open_outlined,
              title: l10n.open,
              subtitle: l10n.openSubtitle,
              selected: _joinMode == 'open',
              onTap: () => _setJoinMode('open'),
            ),
            _JoinModeOption(
              icon: Icons.how_to_reg_outlined,
              title: l10n.requestMode,
              subtitle: l10n.requestSubtitle,
              selected: _joinMode == 'request',
              onTap: () => _setJoinMode('request'),
            ),
            _JoinModeOption(
              icon: Icons.lock_outlined,
              title: l10n.private,
              subtitle: l10n.privateSubtitle,
              selected: _joinMode == 'invite_only',
              onTap: () => _setJoinMode('invite_only'),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(l10n.bannedMembers),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showBannedSheet,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.preview_outlined),
              title: Text(l10n.previewDiscoverPage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final previewCircle = Circle(
                  id: widget.circle.id,
                  name: _name,
                  createdBy: widget.circle.createdBy,
                  members: widget.circle.members,
                  memberCount: widget.circle.memberCount,
                  createdAt: widget.circle.createdAt,
                  imageBase64: _imageBytes != null
                      ? base64Encode(_imageBytes!)
                      : widget.circle.imageBase64,
                  tags: _tags,
                  description: widget.circle.description,
                  imageUrl: widget.circle.imageUrl,
                  operators: widget.circle.operators,
                  banned: widget.circle.banned,
                  joinMode: _joinMode,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CircleDetailScreen(
                      circle: previewCircle,
                      previewMode: true,
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.deleteGroup,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _deleteGroup,
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _JoinModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: selected ? primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: selected
          ? Icon(Icons.check_circle, color: primary)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _BannedSheet extends StatefulWidget {
  final String circleId;
  const _BannedSheet({required this.circleId});

  @override
  State<_BannedSheet> createState() => _BannedSheetState();
}

class _BannedSheetState extends State<_BannedSheet> {
  List<Map<String, dynamic>> _banned = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('circles')
        .doc(widget.circleId)
        .get();
    final bannedUids = List<String>.from(doc.data()?['banned'] ?? []);

    if (bannedUids.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final userDocs = await Future.wait(
      bannedUids.map(
        (uid) => FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ),
    );

    setState(() {
      _banned = userDocs
          .map((d) => {'uid': d.id, ...d.data() ?? {}})
          .toList();
      _banned.sort((a, b) =>
          ((a['displayName'] as String?) ?? '')
              .compareTo((b['displayName'] as String?) ?? ''));
      _isLoading = false;
    });
  }

  Future<void> _unban(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .update({'banned': FieldValue.arrayRemove([uid])});
      setState(() => _banned.removeWhere((m) => m['uid'] == uid));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorUnbanning)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              Text(
                l10n.bannedMembers,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
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
        else if (_banned.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.nobodyBanned,
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _banned.length,
              itemBuilder: (context, index) {
                final member = _banned[index];
                final uid = member['uid'] as String;
                final name =
                    member['displayName'] as String? ?? l10n.unknown;
                final badges = List<String>.from(member['badges'] ?? []);
                final base64Str = member['profileImageBase64'] as String?;
                final url = member['profileImageUrl'] as String?;

                Widget avatar;
                if (base64Str != null && base64Str.isNotEmpty) {
                  avatar = CircleAvatar(
                    backgroundImage: MemoryImage(base64Decode(base64Str)),
                  );
                } else if (url != null && url.isNotEmpty) {
                  avatar = CircleAvatar(
                      backgroundImage: NetworkImage(url));
                } else {
                  avatar = const CircleAvatar(
                    child: Icon(Icons.person_outline, size: 20),
                  );
                }

                return ListTile(
                  leading: avatar,
                  title: nameWithBadges(name, badges: badges),
                  trailing: TextButton(
                    onPressed: () => _unban(uid),
                    child: Text(AppLocalizations.of(context)!.unban),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}

class _InterestsSheet extends StatefulWidget {
  final Set<String> current;
  final Future<void> Function(Set<String>) onSave;

  const _InterestsSheet({required this.current, required this.onSave});

  @override
  State<_InterestsSheet> createState() => _InterestsSheetState();
}

class _InterestsSheetState extends State<_InterestsSheet> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.current);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editInterests,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.interestsTip,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAllInterests.map((tag) {
                  final selected = _selected.contains(tag);
                  return FilterChip(
                    showCheckmark: false,
                    label: Text(getInterestName(tag, l10n)),
                    selected: selected,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
                      }
                      return Theme.of(context).colorScheme.surfaceContainerHighest;
                    }),
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: selected
                        ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
                        : BorderSide.none,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selected.add(tag);
                        } else {
                          _selected.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (_selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.pleaseSelectInterest),
                          ),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      await widget.onSave(_selected);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      l10n.save,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
