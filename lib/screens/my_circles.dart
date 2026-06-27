import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/circle_model.dart';
import '../constants/interests.dart';
import '../services/story_service.dart';
import 'circle_detail_screen.dart';
import 'story_viewer_screen.dart';

class MyCircles extends StatefulWidget {
  const MyCircles({super.key});

  @override
  State<MyCircles> createState() => _MyCirclesState();
}

class _TopCircleAvatar extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hasMention;
  // Pre-built story indicator widget placed at top-left; null = no story
  final Widget? storyIndicator;

  const _TopCircleAvatar({
    required this.circle,
    required this.onTap,
    required this.onLongPress,
    this.hasMention = false,
    this.storyIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes =
        circle.imageBase64 != null ? base64Decode(circle.imageBase64!) : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasMention ? Colors.red : const Color(0xFFC5CAE9),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFFF9966),
                            alignment: Alignment.center,
                            child: Text(
                              circle.name.isNotEmpty
                                  ? circle.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                if (hasMention)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.alternate_email,
                          color: Colors.white, size: 11),
                    ),
                  ),
                if (storyIndicator != null)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: storyIndicator!,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              circle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCirclesState extends State<MyCircles> {
  final TextEditingController _searchController = TextEditingController();
  List<Circle> _circles = [];
  Set<String> _pinnedIds = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  Set<String> _circlesWithMentions = {};
  StreamSubscription<DocumentSnapshot>? _mentionSub;
  Set<String> _circlesWithStories = {};
  // circleId → top-3 creators sorted: unseen first, newest first
  // each entry: {'image': String?, 'name': String, 'seen': bool, 'at': DateTime}
  Map<String, List<Map<String, dynamic>>> _circleStoryCreators = {};
  StreamSubscription<QuerySnapshot>? _storySub;

  @override
  void initState() {
    super.initState();
    _loadCircles();
    _listenForMentions();
  }

  void _listenForStories() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _storySub?.cancel();

    if (uid == null || _circles.isEmpty) {
      setState(() {
        _circlesWithStories = {};
        _circleStoryCreators = {};
      });
      return;
    }

    final ids = _circles.map((c) => c.id).toList();
    // Firestore whereIn limit is 30; most users have far fewer circles
    final queryIds = ids.length <= 30 ? ids : ids.sublist(0, 30);

    _storySub = FirebaseFirestore.instance
        .collection('stories')
        .where('circleId', whereIn: queryIds)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final now = DateTime.now();
      final withStories = <String>{};
      // circleId → all active stories as raw maps
      final raw = <String, List<Map<String, dynamic>>>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        if (expiresAt == null || expiresAt.isBefore(now)) continue;
        final circleId = data['circleId'] as String;
        withStories.add(circleId);
        final viewedBy = List<String>.from(data['viewedBy'] ?? []);
        final seen = viewedBy.contains(uid);
        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        raw.putIfAbsent(circleId, () => []).add({
          'image': data['creatorImageBase64'] as String?,
          'name': data['creatorName'] as String? ?? '',
          'seen': seen,
          'at': createdAt,
        });
      }

      // Sort each circle: unseen first, then seen; newest first within group
      final creators = <String, List<Map<String, dynamic>>>{};
      for (final entry in raw.entries) {
        final list = entry.value
          ..sort((a, b) {
            final aSeen = a['seen'] as bool;
            final bSeen = b['seen'] as bool;
            if (aSeen != bSeen) return aSeen ? 1 : -1;
            return (b['at'] as DateTime).compareTo(a['at'] as DateTime);
          });
        creators[entry.key] = list.take(3).toList();
      }

      setState(() {
        _circlesWithStories = withStories;
        _circleStoryCreators = creators;
      });
    });
  }

  Future<void> _openStoryViewer(Circle circle) async {
    final allStories = await StoryService.getActiveStoriesForCircle(circle.id);
    if (!mounted) return;
    if (allStories.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CircleDetailScreen(circle: circle),
        ),
      );
      _loadCircles();
      return;
    }
    // Unseen stories first (newest first within group), then seen
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unseen = allStories
        .where((s) => !s.viewedBy.contains(uid))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = allStories
        .where((s) => s.viewedBy.contains(uid))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          circleName: circle.name,
          stories: [...unseen, ...seen],
        ),
      ),
    );
  }

  // Builds a stack of up to 3 overlapping creator avatar circles.
  // Unseen = gradient ring, seen = grey. Newest/unseen is topmost (rightmost).
  Widget _buildStoryIndicator(
    String circleId, {
    required double size,
    required double offset,
    required VoidCallback onTap,
  }) {
    final creators = _circleStoryCreators[circleId] ?? [];
    if (creators.isEmpty) return const SizedBox.shrink();
    final n = creators.length.clamp(1, 3);
    final totalWidth = size + (n - 1) * offset;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: totalWidth,
        height: size + 4,
        child: Stack(
          children: List.generate(n, (renderOrder) {
            // renderOrder 0 = leftmost/oldest (rendered first = bottom z)
            // renderOrder n-1 = rightmost/newest (rendered last = top z)
            final creatorIdx = n - 1 - renderOrder;
            final creator = creators[creatorIdx];
            final left = renderOrder * offset;
            final seen = creator['seen'] as bool? ?? false;
            final imageB64 = creator['image'] as String?;
            final name = creator['name'] as String? ?? '';

            return Positioned(
              left: left,
              top: 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: !seen
                      ? const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFFFF9966), Color(0xFFE91E8C)],
                        )
                      : LinearGradient(colors: [
                          Colors.grey.shade500,
                          Colors.grey.shade500,
                        ]),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: imageB64 != null
                      ? Image.memory(base64Decode(imageB64), fit: BoxFit.cover)
                      : Container(
                          color: !seen
                              ? const Color(0xFFFF9966)
                              : Colors.grey.shade500,
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _listenForMentions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _mentionSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _circlesWithMentions = Set<String>.from(
            (doc.data()?['circlesWithMentions'] as List<dynamic>?) ?? [],
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _mentionSub?.cancel();
    _storySub?.cancel();
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
      setSheetState(() => isPicking = true);
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
            final l = AppLocalizations.of(context)!;
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.createNewCircle,
                              style: const TextStyle(
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
                                      Image.memory(imageBytes!,
                                          fit: BoxFit.cover),
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
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l.selectImage,
                                        style: const TextStyle(
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

                      TextFormField(
                        controller: nameController,
                        autofocus: false,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l.circleNameLabel,
                          hintText: l.circleNameHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l.pleaseEnterCircleName;
                          }
                          if (value.trim().length < 2) {
                            return l.nameTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      Text(
                        l.categorySelectHint,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kAllInterests.map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(getInterestName(tag, l)),
                            selected: isSelected,
                            side: isSelected
                                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                                : BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
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
                                      SnackBar(
                                        content: Text(
                                            l.selectAtLeastOneCategory),
                                      ),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isSaving = true);

                                  try {
                                    final uid = FirebaseAuth
                                        .instance.currentUser!.uid;
                                    final name = nameController.text.trim();

                                    final data = {
                                      'name': name,
                                      'createdBy': uid,
                                      'createdAt':
                                          FieldValue.serverTimestamp(),
                                      'members': [uid],
                                      'memberCount': 1,
                                      'tags': selectedTags.toList(),
                                      'description': '',
                                      'imageUrl': '',
                                      if (imageBase64 != null)
                                        'imageBase64': imageBase64,
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)!
                                                  .errorCreatingCircle),
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
                              : Text(
                                  l.createCircle,
                                  style: const TextStyle(fontSize: 16),
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final circlesFuture = FirebaseFirestore.instance
          .collection('circles')
          .where('members', arrayContains: currentUid)
          .get();
      final userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();

      final results = await Future.wait([circlesFuture, userFuture]);
      final circleSnap = results[0] as QuerySnapshot;
      final userDoc = results[1] as DocumentSnapshot;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final pinned = Set<String>.from(
        (userData?['pinnedCircles'] as List<dynamic>?) ?? [],
      );

      if (!mounted) return;
      setState(() {
        _circles = circleSnap.docs.map(Circle.fromFirestore).toList();
        _pinnedIds = pinned;
        _isLoading = false;
      });
      _listenForStories();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.errorLoadingCircles;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePin(String circleId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isPinned = _pinnedIds.contains(circleId);

    setState(() {
      if (isPinned) {
        _pinnedIds.remove(circleId);
      } else {
        _pinnedIds.add(circleId);
      }
    });

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'pinnedCircles': _pinnedIds.toList()},
      SetOptions(merge: true),
    );
  }

  Widget _buildCircleCard(Circle circle) {
    final l10n = AppLocalizations.of(context)!;
    final Uint8List? imageBytes = circle.imageBase64 != null
        ? base64Decode(circle.imageBase64!)
        : null;
    final isPinned = _pinnedIds.contains(circle.id);
    final hasStory = _circlesWithStories.contains(circle.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SafeArea(
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
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      isPinned ? Icons.star : Icons.star_outline,
                      color: const Color(0xFFFF9966),
                    ),
                    title: Text(
                      isPinned ? l10n.removeFromTop : l10n.addToTop,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _togglePin(circle.id);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
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
                imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : const ColoredBox(color: Color(0xFFFF9966)),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),

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
                        l10n.memberCount(circle.memberCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isPinned)
                  const Positioned(
                    top: 10,
                    right: 12,
                    child: Icon(Icons.star, color: Colors.black, size: 20),
                  ),
                if (_circlesWithMentions.contains(circle.id))
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alternate_email,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Story stack: top-right, up to 3 stacked creator avatars
                if (hasStory)
                  Positioned(
                    top: 10,
                    right: isPinned ? 38 : 12,
                    child: _buildStoryIndicator(
                      circle.id,
                      size: 36,
                      offset: 18,
                      onTap: () => _openStoryViewer(circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCirclesRow(List<Circle> pinned) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            l10n.topCircles,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pinned.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _TopCircleAvatar(
              circle: pinned[i],
              hasMention: _circlesWithMentions.contains(pinned[i].id),
              storyIndicator: _circlesWithStories.contains(pinned[i].id)
                  ? _buildStoryIndicator(
                      pinned[i].id,
                      size: 18,
                      offset: 9,
                      onTap: () => _openStoryViewer(pinned[i]),
                    )
                  : null,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CircleDetailScreen(circle: pinned[i]),
                  ),
                );
                _loadCircles();
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SafeArea(
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
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.star_outline),
                          title: Text(l10n.removeFromTop),
                          onTap: () {
                            Navigator.pop(context);
                            _togglePin(pinned[i].id);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.allCircles,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

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
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final pinnedCircles = _circles
        .where((c) => _pinnedIds.contains(c.id))
        .toList();
    final query = _searchQuery.toLowerCase().trim();
    final unpinnedCircles = _circles
        .where((c) => !_pinnedIds.contains(c.id))
        .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (pinnedCircles.isNotEmpty) _buildTopCirclesRow(pinnedCircles),
          if (pinnedCircles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                l10n.yourCircles,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          if (_circles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  l10n.noCirclesYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else if (unpinnedCircles.isEmpty && _searchQuery.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  l10n.noCirclesFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...unpinnedCircles.map(_buildCircleCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myCircles,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              hintText: l10n.searchCircles,
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
              onChanged: (value) => setState(() => _searchQuery = value),
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
