import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:orbit/screens/settings.dart';
import '../constants/interests.dart';
import '../widgets/user_badges.dart';

// profile tab - shows name, avatar and interests
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _displayName = '';
  int? _age;
  List<String> _interests = [];
  List<String> _badges = [];
  bool _loading = true;
  String? _profileImageBase64;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // load profile data from firestore
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _displayName = data['displayName'] as String? ?? '';
      _age = data['age'] as int?;
      _interests = List<String>.from(data['interests'] ?? []);
      _badges = List<String>.from(data['badges'] ?? []);
      _profileImageBase64 = data['profileImageBase64'] as String?;
      _loading = false;
    });
  }

  // save updated interests to firestore
  Future<void> _saveInterests(List<String> updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'interests': updated,
    });

    setState(() => _interests = updated);
  }

  // pick profile image from camera or gallery and save to firestore
  Future<void> _pickProfileImage() async {
    if (_isPickingImage) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
      setState(() => _profileImageBase64 = base64);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Ändern des Profilbildes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // open interests edit sheet
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
          await _saveInterests(selected.toList()); // save
        },
      ),
    );
  }

  // avatar with camera overlay - shows base64, google photo or placeholder
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mein Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        // settings button
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
              _loadProfile();
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                                '$_age Jahre',
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
                      const Text(
                        'Interessen',
                        style: TextStyle(
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
                          'Bearbeiten',
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
                      'Noch keine Interessen hinzugefügt.',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.map((interest) {
                        return Chip(
                          backgroundColor: const Color.fromARGB(
                            255,
                            238,
                            238,
                            238,
                          ),
                          label: Text(
                            interest,
                            style: const TextStyle(color: Colors.black),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

// bottom sheet to edit interests
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
          const Text(
            'Interessen bearbeiten',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe auf ein Interesse um es hinzuzufügen oder zu entfernen.',
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
                    backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF0FB),
                    label: Text(interest),
                    selected: selected,
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color.fromARGB(255, 83, 52, 141)
                          : Colors.black,
                    ),
                    side: selected
                        ? const BorderSide(color: Color(0xFFC5CAE9), width: 1.5)
                        : BorderSide.none,
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
                          const SnackBar(
                            content: Text(
                              'Bitte wähle mindestens ein Interesse.',
                            ),
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
                      'Speichern',
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
