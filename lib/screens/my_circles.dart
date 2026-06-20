import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/circle_model.dart';
import 'circle_detail_screen.dart';

class MyCircles extends StatefulWidget {
  const MyCircles({super.key});

  @override
  State<MyCircles> createState() => _MyCirclesState();
}

const List<String> _availableTags = [
  'Sport & Fitness', 'Musik', 'Gaming', 'Lesen', 'Kochen', 'Reisen',
  'Fotografie', 'Kunst', 'Film & Serien', 'Technologie', 'Natur', 'Mode',
  'Yoga', 'Tanzen', 'Wissenschaft', 'Geschichte', 'Sprachen', 'Tiere',
  'DIY', 'Finanzen', 'Politik', 'Philosophie', 'Familie', 'Ehrenamt',
  'Ernährung',
];

class _MyCirclesState extends State<MyCircles> {
  final TextEditingController _searchController = TextEditingController();
  List<Circle> _circles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCircleSheet() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool isPicking = false;
    Uint8List? imageBytes;
    String? imageBase64;
    final Set<String> selectedTags = {};

    Future<void> pickImage(StateSetter setSheetState) async {
      if (isPicking) return;
      setSheetState(() => isPicking = true);
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 600,
          imageQuality: 65,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        setSheetState(() {
          imageBytes = bytes;
          imageBase64 = base64Encode(bytes);
        });
      } finally {
        setSheetState(() => isPicking = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Neuen Kreis erstellen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Image picker
                    GestureDetector(
                      onTap: () => pickImage(setSheetState),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          color: const Color(0xFFFF9966),
                          child: imageBytes != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(imageBytes!, fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black26,
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Bild auswählen',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    TextFormField(
                      controller: nameController,
                      autofocus: false,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Kreisname',
                        hintText: 'z.B. Besties, Fotografie, Running...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte einen Namen eingeben.';
                        }
                        if (value.trim().length < 2) {
                          return 'Name muss mindestens 2 Zeichen haben.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tag selection
                    Text(
                      'Kategorie (mind. 1 auswählen)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (selectedTags.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Wähle mindestens eine Kategorie.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() => isSaving = true);

                                try {
                                  final uid =
                                      FirebaseAuth.instance.currentUser!.uid;
                                  final name = nameController.text.trim();

                                  final data = {
                                    'name': name,
                                    'createdBy': uid,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'members': [uid],
                                    'memberCount': 1,
                                    'tags': selectedTags.toList(),
                                    'description': '',
                                    'imageUrl': '',
                                    'imageBase64': ?imageBase64,
                                  };

                                  await FirebaseFirestore.instance
                                      .collection('circles')
                                      .add(data);

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  _loadCircles();
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fehler beim Erstellen des Kreises.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kreis erstellen',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadCircles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('circles')
          .where('members', arrayContains: currentUid)
          .get();

      setState(() {
        _circles = snapshot.docs.map(Circle.fromFirestore).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der Kreise.';
        _isLoading = false;
      });
    }
  }

  Widget _buildCircleCard(Circle circle) {
    final Uint8List? imageBytes = circle.imageBase64 != null
        ? base64Decode(circle.imageBase64!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CircleDetailScreen(circle: circle),
            ),
          );
          _loadCircles();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background: image or orange placeholder
                imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : const ColoredBox(color: Color(0xFFFF9966)),

                // Gradient overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),

                // Name and member count
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${circle.memberCount} Mitglieder',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Colored dot top right
                const Positioned(
                  top: 12,
                  right: 12,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4B9EFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCircles,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Deine Kreise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (_circles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  'Du bist noch in keinem Kreis.\nEntdecke neue Gruppen!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ..._circles.map(_buildCircleCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meine Kreise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateCircleSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Kreise suchen...',
              elevation: const WidgetStatePropertyAll(0),
              textStyle: WidgetStatePropertyAll(
                TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              constraints: const BoxConstraints(
                minHeight: 44.0,
                maxHeight: 44.0,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.0,
                ),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(64.0),
                ),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: null, // SPÄTER: Suchfunktion
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
