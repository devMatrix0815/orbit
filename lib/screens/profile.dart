import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:orbit/l10n/app_localizations.dart';
import 'package:orbit/screens/settings.dart';
import 'package:orbit/services/update_service.dart';
import '../constants/interests.dart';
import '../widgets/user_badges.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _displayName = '';
  int? _age;
  String _bio = '';
  String _link1 = '';
  String _link2 = '';
  List<String> _interests = [];
  List<String> _badges = [];
  bool _loading = true;
  String? _profileImageBase64;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    UpdateService.checkInBackground();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    if (!mounted) return;
    setState(() {
      _displayName = data['displayName'] as String? ?? '';
      _age = data['age'] as int?;
      _bio = data['bio'] as String? ?? '';
      _link1 = data['link1'] as String? ?? '';
      _link2 = data['link2'] as String? ?? '';
      _interests = List<String>.from(data['interests'] ?? []);
      _badges = List<String>.from(data['badges'] ?? []);
      _profileImageBase64 = data['profileImageBase64'] as String?;
      _loading = false;
    });
  }

  Future<void> _saveInterests(List<String> updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'interests': updated,
    });

    if (!mounted) return;
    setState(() => _interests = updated);
  }

  Future<void> _pickProfileImage() async {
    if (_isPickingImage) return;
    final l10n = AppLocalizations.of(context)!;

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
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageBase64': base64,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _profileImageBase64 = base64);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorChangingProfilePicture)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _openEditBioLinks() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditBioLinksSheet(
        initialBio: _bio,
        initialLink1: _link1,
        initialLink2: _link2,
        onSave: (bio, link1, link2) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'bio': bio, 'link1': link1, 'link2': link2});
          if (mounted) {
            setState(() {
              _bio = bio;
              _link1 = link1;
              _link2 = link2;
            });
          }
        },
      ),
    );
  }

  Widget _buildLinkTile(String url) {
    final uri = Uri.tryParse(url);
    final label = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '');
    return InkWell(
      onTap: () async {
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddInterests() async {
    final toAdd = Set<String>.from(_interests);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddInterestsSheet(
        current: toAdd,
        onSave: (selected) async {
          await _saveInterests(selected.toList());
        },
      ),
    );
  }

  Widget _buildAvatar() {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    Widget image;
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      image = Image.memory(
        base64Decode(_profileImageBase64!),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      );
    } else if (photoUrl != null) {
      image = Image.network(
        photoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      );
    } else {
      image = const CircleAvatar(
        radius: 32,
        child: Icon(Icons.person, size: 32),
      );
    }

    return GestureDetector(
      onTap: _pickProfileImage,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(1000),
              child: image,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(1000),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: _isPickingImage
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myProfile,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: UpdateService.hasUpdate,
            builder: (context, hasUpdate, _) => IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
                _loadProfile();
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.settings),
                  if (hasUpdate)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    child: Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                UserBadgesRow(badges: _badges, size: 18),
                              ],
                            ),
                            if (_age != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.ageYears(_age!),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.biography,
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
                        onPressed: _openEditBioLinks,
                        label: Text(
                          l10n.edit,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  if (_bio.isEmpty)
                    Text(
                      l10n.noBio,
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Text(_bio),

                  if (_link1.isNotEmpty || _link2.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (_link1.isNotEmpty) _buildLinkTile(_link1),
                    if (_link2.isNotEmpty) _buildLinkTile(_link2),
                  ],

                  const SizedBox(height: 24),

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
                        onPressed: _openAddInterests,
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

                  if (_interests.isEmpty)
                    Text(
                      l10n.noInterestsAdded,
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.map((interest) {
                        return Chip(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          label: Text(
                            getInterestName(interest, l10n),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class _EditBioLinksSheet extends StatefulWidget {
  final String initialBio;
  final String initialLink1;
  final String initialLink2;
  final Future<void> Function(String bio, String link1, String link2) onSave;

  const _EditBioLinksSheet({
    required this.initialBio,
    required this.initialLink1,
    required this.initialLink2,
    required this.onSave,
  });

  @override
  State<_EditBioLinksSheet> createState() => _EditBioLinksSheetState();
}

class _EditBioLinksSheetState extends State<_EditBioLinksSheet> {
  late final TextEditingController _bioController;
  late final TextEditingController _link1Controller;
  late final TextEditingController _link2Controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.initialBio);
    _link1Controller = TextEditingController(text: widget.initialLink1);
    _link2Controller = TextEditingController(text: widget.initialLink2);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _link1Controller.dispose();
    _link2Controller.dispose();
    super.dispose();
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
            l10n.editBioAndLinks,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: l10n.bioHint,
              border: const OutlineInputBorder(),
              counterStyle: const TextStyle(fontSize: 11),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _link1Controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.link1Hint,
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _link2Controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.link2Hint,
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _saving = true);
                      try {
                        await widget.onSave(
                          _bioController.text.trim(),
                          _link1Controller.text.trim(),
                          _link2Controller.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.errorSavingBio)),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
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

class _AddInterestsSheet extends StatefulWidget {
  final Set<String> current;
  final Future<void> Function(Set<String>) onSave;

  const _AddInterestsSheet({required this.current, required this.onSave});

  @override
  State<_AddInterestsSheet> createState() => _AddInterestsSheetState();
}

class _AddInterestsSheetState extends State<_AddInterestsSheet> {
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
                children: kAllInterests.map((interest) {
                  final selected = _selected.contains(interest);
                  return FilterChip(
                    showCheckmark: false,
                    label: Text(getInterestName(interest, l10n)),
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
                        ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                        : BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                            width: 1,
                          ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selected.add(interest);
                        } else {
                          _selected.remove(interest);
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
