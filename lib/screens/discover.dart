import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/circle_model.dart';
import '../constants/interests.dart';
import 'circle_detail_screen.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
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
          .where((c) =>
              !c.members.contains(uid) &&
              !c.banned.contains(uid) &&
              c.joinMode != 'invite_only')
          .toList();

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
    } else if (_selectedCategory != null) {
      final categoryTags = kInterestCategories[_selectedCategory] ?? [];
      circles = circles.where((c) => c.tags.any(categoryTags.contains)).toList();
    }
    final q = _searchQuery.toLowerCase().trim();
    if (q.isNotEmpty) {
      circles = circles.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return circles;
  }

  List<String> get _sortedCategories {
    final categories = kInterestCategories.keys.toList();
    categories.sort((a, b) {
      final aMatch = (kInterestCategories[a] ?? []).any(_userInterests.contains) ? 0 : 1;
      final bMatch = (kInterestCategories[b] ?? []).any(_userInterests.contains) ? 0 : 1;
      return aMatch.compareTo(bMatch);
    });
    return categories;
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
          final l = AppLocalizations.of(ctx)!;
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
                  Text(
                    l.filterByCategory,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l.all),
                        selected: _selectedTag == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = null;
                            _selectedCategory = null;
                            _showAll = false;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ...kAllInterests.map((tag) => FilterChip(
                        label: Text(getInterestName(tag, l)),
                        selected: _selectedTag == tag,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = tag;
                            _selectedCategory = null;
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

  Widget _buildTagCircle(String category, AppLocalizations l10n) {
    final isSelected = _selectedCategory == category;
    final icon = kCategoryIcons[category] ?? Icons.tag;
    final bgColor = kCategoryColors[category] ?? const Color(0xFFF5F5F5);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = isSelected ? null : category;
        _selectedTag = null;
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
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              getCategoryName(category, l10n),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleCard(Circle circle, AppLocalizations l10n) {
    final imageBytes = circle.imageBase64 != null
        ? base64Decode(circle.imageBase64!)
        : null;

    final accentColor = circle.tags.isNotEmpty
        ? (kTagColors[circle.tags.first] ?? const Color(0xFFFF9966))
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
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                            child: Icon(
                              kTagIcons[circle.tags.isNotEmpty
                                      ? circle.tags.first
                                      : ''] ??
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
                              const Icon(Icons.group,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                l10n.memberCount(circle.memberCount),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: circle.tags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          getInterestName(tag, l10n),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
    final filtered = _filteredCircles;
    final displayed = _showAll ? filtered : filtered.take(4).toList();
    final sortedCategories = _sortedCategories;
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
                    Text(
                      l10n.discover,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: _searchController,
                            hintText: l10n.searchGroups,
                            elevation: const WidgetStatePropertyAll(0),
                            backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            constraints: const BoxConstraints(
                                minHeight: 48, maxHeight: 48),
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
                            leading: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showFilterSheet,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedTag != null
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune,
                              color: _selectedTag != null
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sortedCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) =>
                            _buildTagCircle(sortedCategories[i], l10n),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _selectedTag != null
                          ? getInterestName(_selectedTag!, l10n)
                          : _selectedCategory != null
                              ? getCategoryName(_selectedCategory!, l10n)
                              : l10n.recommendedGroups,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (displayed.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            l10n.noGroupsFound,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 200,
                        ),
                        itemCount: displayed.length,
                        itemBuilder: (_, i) =>
                            _buildCircleCard(displayed[i], l10n),
                      ),

                    if (!_showAll && filtered.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: GestureDetector(
                          onTap: () => setState(() => _showAll = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.showMore,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  color: primaryColor),
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
