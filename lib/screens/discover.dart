import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/circle_model.dart';
import 'circle_detail_screen.dart';

const List<String> _availableTags = [
  'Sport & Fitness', 'Musik', 'Gaming', 'Lesen', 'Kochen', 'Reisen',
  'Fotografie', 'Kunst', 'Film & Serien', 'Technologie', 'Natur', 'Mode',
  'Yoga', 'Tanzen', 'Wissenschaft', 'Geschichte', 'Sprachen', 'Tiere',
  'DIY', 'Finanzen', 'Politik', 'Philosophie', 'Familie', 'Ehrenamt',
  'Ernährung',
];

const Map<String, IconData> _tagIcons = {
  'Sport & Fitness': Icons.directions_run,
  'Musik': Icons.music_note,
  'Gaming': Icons.sports_esports,
  'Lesen': Icons.menu_book,
  'Kochen': Icons.restaurant,
  'Reisen': Icons.flight,
  'Fotografie': Icons.camera_alt,
  'Kunst': Icons.brush,
  'Film & Serien': Icons.movie,
  'Technologie': Icons.computer,
  'Natur': Icons.park,
  'Mode': Icons.checkroom,
  'Yoga': Icons.self_improvement,
  'Tanzen': Icons.accessibility_new,
  'Wissenschaft': Icons.science,
  'Geschichte': Icons.history_edu,
  'Sprachen': Icons.translate,
  'Tiere': Icons.pets,
  'DIY': Icons.construction,
  'Finanzen': Icons.attach_money,
  'Politik': Icons.account_balance,
  'Philosophie': Icons.psychology,
  'Familie': Icons.family_restroom,
  'Ehrenamt': Icons.volunteer_activism,
  'Ernährung': Icons.restaurant_menu,
};

const Map<String, Color> _tagColors = {
  'Sport & Fitness': Color(0xFFFFE0B2),
  'Musik': Color(0xFFE8F5E9),
  'Gaming': Color(0xFFE3F2FD),
  'Lesen': Color(0xFFFCE4EC),
  'Kochen': Color(0xFFFFF8E1),
  'Reisen': Color(0xFFBBDEFB),
  'Fotografie': Color(0xFFF3E5F5),
  'Kunst': Color(0xFFFFEBEE),
  'Film & Serien': Color(0xFFE8EAF6),
  'Technologie': Color(0xFFE0F2F1),
  'Natur': Color(0xFFDCEDC8),
  'Mode': Color(0xFFFCE4EC),
  'Yoga': Color(0xFFEDE7F6),
  'Tanzen': Color(0xFFE0F2F1),
  'Wissenschaft': Color(0xFFE1F5FE),
  'Geschichte': Color(0xFFFFF3E0),
  'Sprachen': Color(0xFFE0F7FA),
  'Tiere': Color(0xFFFFF8E1),
  'DIY': Color(0xFFFBE9E7),
  'Finanzen': Color(0xFFE8F5E9),
  'Politik': Color(0xFFE3F2FD),
  'Philosophie': Color(0xFFEDE7F6),
  'Familie': Color(0xFFFCE4EC),
  'Ehrenamt': Color(0xFFD7F5D7),
  'Ernährung': Color(0xFFFFF9C4),
};

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;
  List<Circle> _allCircles = [];
  List<String> _userInterests = [];
  bool _isLoading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('circles').get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final circlesSnap = results[1] as QuerySnapshot;

      final userData = userDoc.data() as Map<String, dynamic>?;
      final interests = List<String>.from(userData?['interests'] ?? []);

      final circles = circlesSnap.docs
          .map(Circle.fromFirestore)
          .where((c) => !c.members.contains(uid) && !c.banned.contains(uid))
          .toList();

      // Sort by number of matching interests (descending), then by memberCount
      circles.sort((a, b) {
        final aScore = a.tags.where((t) => interests.contains(t)).length;
        final bScore = b.tags.where((t) => interests.contains(t)).length;
        if (bScore != aScore) return bScore.compareTo(aScore);
        return b.memberCount.compareTo(a.memberCount);
      });

      setState(() {
        _allCircles = circles;
        _userInterests = interests;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Circle> get _filteredCircles {
    var circles = _allCircles;
    if (_selectedTag != null) {
      circles = circles.where((c) => c.tags.contains(_selectedTag)).toList();
    }
    final q = _searchQuery.toLowerCase().trim();
    if (q.isNotEmpty) {
      circles = circles.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return circles;
  }

  // User's interests first, then remaining tags
  List<String> get _sortedTags {
    final userTags = _availableTags.where((t) => _userInterests.contains(t)).toList();
    final otherTags = _availableTags.where((t) => !_userInterests.contains(t)).toList();
    return [...userTags, ...otherTags];
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nach Kategorie filtern',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Alle'),
                        selected: _selectedTag == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = null;
                            _showAll = false;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ..._availableTags.map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = tag;
                            _showAll = false;
                          });
                          Navigator.pop(ctx);
                        },
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagCircle(String tag) {
    final isSelected = _selectedTag == tag;
    final icon = _tagIcons[tag] ?? Icons.tag;
    final bgColor = _tagColors[tag] ?? const Color(0xFFF5F5F5);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedTag = isSelected ? null : tag;
        _showAll = false;
      }),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tag,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleCard(Circle circle) {
    final imageBytes = circle.imageBase64 != null
        ? base64Decode(circle.imageBase64!)
        : null;

    final accentColor = circle.tags.isNotEmpty
        ? (_tagColors[circle.tags.first] ?? const Color(0xFFFF9966))
        : const Color(0xFFFF9966);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CircleDetailScreen(circle: circle)),
        );
        _loadData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [accentColor, accentColor.withValues(alpha: 0.5)],
                              ),
                            ),
                            child: Icon(
                              _tagIcons[circle.tags.isNotEmpty ? circle.tags.first : ''] ??
                                  Icons.group,
                              size: 44,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            circle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.group, color: Colors.white70, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '${circle.memberCount} Mitglieder',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tag chips
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: circle.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 10)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCircles;
    final displayed = _showAll ? filtered : filtered.take(4).toList();
    final sortedTags = _sortedTags;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Page title
                    const Text(
                      'Entdecken',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Search bar + filter button
                    Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: _searchController,
                            hintText: 'Suche nach Gruppen...',
                            elevation: const WidgetStatePropertyAll(0),
                            backgroundColor: WidgetStatePropertyAll(Colors.grey[100]),
                            constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onChanged: (v) => setState(() {
                              _searchQuery = v;
                              _showAll = false;
                            }),
                            leading: const Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showFilterSheet,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedTag != null ? primaryColor : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune,
                              color: _selectedTag != null ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category circles (horizontal scroll)
                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sortedTags.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _buildTagCircle(sortedTags[i]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section title
                    Text(
                      _selectedTag ?? 'Empfohlene Gruppen',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Grid of circles
                    if (displayed.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'Keine Gruppen gefunden.',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 200,
                        ),
                        itemCount: displayed.length,
                        itemBuilder: (_, i) => _buildCircleCard(displayed[i]),
                      ),

                    // Mehr anzeigen
                    if (!_showAll && filtered.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: GestureDetector(
                          onTap: () => setState(() => _showAll = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Mehr anzeigen',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
