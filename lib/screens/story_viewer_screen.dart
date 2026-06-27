import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final String circleName;
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.circleName,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentIndex;

  static const _storyDuration = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      });
    _startCurrent();
  }

  void _startCurrent() {
    _markViewed();
    _controller.forward(from: 0);
  }

  void _advance() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startCurrent();
    } else {
      Navigator.pop(context);
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrent();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _markViewed() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      StoryService.markViewed(widget.stories[_currentIndex].id, uid);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt, AppLocalizations l) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return l.storyMinutesAgo(diff.inMinutes.clamp(1, 59));
    }
    return l.storyHoursAgo(diff.inHours.clamp(1, 23));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final story = widget.stories[_currentIndex];
    final imageBytes = base64Decode(story.imageBase64);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Tap zones: left = back, right = forward
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final x = details.localPosition.dx;
                  final width = MediaQuery.of(context).size.width;
                  if (x < width / 3) {
                    _goBack();
                  } else {
                    _advance();
                  }
                },
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ),

            // Text overlays (positioned relative to full screen area)
            if (story.textOverlays.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: story.textOverlays
                          .map((overlay) => Positioned(
                                left: overlay.x * constraints.maxWidth,
                                top: overlay.y * constraints.maxHeight,
                                child: FractionalTranslation(
                                  translation: const Offset(-0.5, -0.5),
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
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
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),

            // Top bar: progress + creator info + close
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
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bars
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                      child: Row(
                        children: List.generate(widget.stories.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  double val;
                                  if (i < _currentIndex) {
                                    val = 1.0;
                                  } else if (i == _currentIndex) {
                                    val = _controller.value;
                                  } else {
                                    val = 0.0;
                                  }
                                  return LinearProgressIndicator(
                                    value: val,
                                    minHeight: 2.5,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.35),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Creator row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 4, 8),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFFF9966),
                            backgroundImage: story.creatorImageBase64 != null
                                ? MemoryImage(
                                    base64Decode(story.creatorImageBase64!))
                                : null,
                            child: story.creatorImageBase64 == null
                                ? Text(
                                    story.creatorName.isNotEmpty
                                        ? story.creatorName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  story.creatorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _timeAgo(story.createdAt, l),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

