import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/circle_model.dart';

const List<String> _availableTags = [
  'Sport & Fitness', 'Musik', 'Gaming', 'Lesen', 'Kochen', 'Reisen',
  'Fotografie', 'Kunst', 'Film & Serien', 'Technologie', 'Natur', 'Mode',
  'Yoga', 'Tanzen', 'Wissenschaft', 'Geschichte', 'Sprachen', 'Tiere',
  'DIY', 'Finanzen', 'Politik', 'Philosophie', 'Familie', 'Ehrenamt',
  'Ernährung',
];

// circle settings screen - change image, rename, delete
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
  Uint8List? _imageBytes;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _tags = List<String>.from(widget.circle.tags);

    // decode existing image if available
    if (widget.circle.imageBase64 != null) {
      _imageBytes = base64Decode(widget.circle.imageBase64!);
    }
  }

  // rename circle with a dialog
  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Namen ändern'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Neuer Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
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
          const SnackBar(content: Text('Fehler beim Umbenennen.')),
        );
      }
    }
  }

  // pick new group image from camera or gallery
  Future<void> _pickImage() async {
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
          const SnackBar(content: Text('Fehler beim Ändern des Bildes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // show bottom sheet to manage circle interests/tags — matches profile design
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

  // delete circle and all its invites
  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppe löschen'),
        content: Text(
          'Möchtest du "$_name" wirklich löschen? Das kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // delete all invites first
      final invites = await FirebaseFirestore.instance
          .collection('invites')
          .where('circleId', isEqualTo: widget.circle.id)
          .get();
      for (final doc in invites.docs) {
        await doc.reference.delete();
      }

      // delete the circle
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .delete();

      if (mounted) Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Löschen.')),
        );
      }
    }
  }

  // return updated name when navigating back
  void _popWithResult() {
    Navigator.pop(context, {'name': _name, 'tags': _tags});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithResult();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gruppeneinstellungen'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _popWithResult,
          ),
        ),
        body: ListView(
          children: [
            // image preview / picker
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
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Bild ändern',
                                    style: TextStyle(
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

            // rename
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Namen ändern'),
              subtitle: Text(_name),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showRenameDialog,
            ),

            // interests section — matches profile design
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onPressed: _showInterestsSheet,
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
                  if (_tags.isEmpty)
                    Text(
                      'Noch keine Interessen hinzugefügt.',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          backgroundColor: const Color.fromARGB(
                            255,
                            238,
                            238,
                            238,
                          ),
                          label: Text(
                            tag,
                            style: const TextStyle(color: Colors.black),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const Divider(),

            // delete
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Gruppe löschen',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _deleteGroup,
            ),
          ],
        ),
      ),
    );
  }
}

// bottom sheet to edit circle interests — same design as profile
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
                children: _availableTags.map((tag) {
                  final selected = _selected.contains(tag);
                  return FilterChip(
                    backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF0FB),
                    label: Text(tag),
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
