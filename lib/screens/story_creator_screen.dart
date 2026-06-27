import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryCreatorScreen extends StatefulWidget {
  final String circleId;
  final String circleName;

  const StoryCreatorScreen({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen> {
  Uint8List? _imageBytes;
  String? _imageBase64;
  final List<TextOverlay> _textOverlays = [];
  int _selectedColorIndex = 0;
  bool _isPosting = false;

  static const _colors = [
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFFF4444),
    Color(0xFFFFDD00),
    Color(0xFFFF9966),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    final l = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.camera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.gallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) {
      if (mounted && _imageBytes == null) Navigator.pop(context);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 70,
    );

    if (picked == null) {
      if (mounted && _imageBytes == null) Navigator.pop(context);
      return;
    }

    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _addText() async {
    final l = AppLocalizations.of(context)!;
    String text = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addText),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: l.textHint),
          onChanged: (v) => text = v,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.add),
          ),
        ],
      ),
    );

    if (confirmed == true && text.trim().isNotEmpty) {
      setState(() {
        _textOverlays.add(TextOverlay(
          text: text.trim(),
          x: 0.5,
          y: 0.5,
          fontSize: 28.0,
          colorValue: _colors[_selectedColorIndex].toARGB32(),
        ));
      });
    }
  }

  Future<void> _postStory() async {
    if (_imageBase64 == null) return;
    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      await StoryService.postStory(
        circleId: widget.circleId,
        imageBase64: _imageBase64!,
        textOverlays: _textOverlays,
        creatorId: user.uid,
        creatorName:
            userData['displayName'] as String? ?? user.displayName ?? '',
        creatorImageBase64: userData['profileImageBase64'] as String?,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.storyPostedSuccess),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.storyPostError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_imageBytes == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image + draggable text overlays
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      ),
                      ..._textOverlays.asMap().entries.map((entry) {
                        final i = entry.key;
                        final overlay = entry.value;
                        return Positioned(
                          left: overlay.x * constraints.maxWidth,
                          top: overlay.y * constraints.maxHeight,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _textOverlays[i] = overlay.copyWith(
                                    x: (overlay.x +
                                            details.delta.dx /
                                                constraints.maxWidth)
                                        .clamp(0.05, 0.95),
                                    y: (overlay.y +
                                            details.delta.dy /
                                                constraints.maxHeight)
                                        .clamp(0.05, 0.95),
                                  );
                                });
                              },
                              onLongPress: () {
                                setState(() => _textOverlays.removeAt(i));
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  overlay.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: overlay.color,
                                    fontSize: overlay.fontSize,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.circleName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _isPosting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilledButton(
                              onPressed: _postStory,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9966),
                              ),
                              child: Text(l.storyPost),
                            ),
                          ),
                  ],
                ),
              ),
            ),

            // Bottom toolbar: colors + add text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Row(
                  children: [
                    ..._colors.asMap().entries.map((entry) {
                      final selected = entry.key == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorIndex = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: selected ? 32 : 26,
                          height: selected ? 32 : 26,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry.value,
                            border: Border.all(
                              color: Colors.white,
                              width: selected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addText,
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      label: Text(
                        l.addText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Long-press hint (only when overlays exist)
            if (_textOverlays.isNotEmpty)
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.storyLongPressHint,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
