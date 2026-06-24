import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../constants/interests.dart';
import '../widgets/user_badges.dart';

void openUserProfile(BuildContext context, String userId) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
  );
}

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  Widget _buildAvatar(String? base64Str, String? url) {
    if (base64Str != null && base64Str.isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: MemoryImage(base64Decode(base64Str)),
      );
    }
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: NetworkImage(url),
      );
    }
    return const CircleAvatar(
      radius: 52,
      child: Icon(Icons.person, size: 48),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.unknown)),
      );
    }

    final data = _userData!;
    final displayName = data['displayName'] as String? ?? l10n.unknown;
    final age = data['age'] as int?;
    final bio = data['bio'] as String? ?? '';
    final link1 = data['link1'] as String? ?? '';
    final link2 = data['link2'] as String? ?? '';
    final interests = List<String>.from(data['interests'] ?? []);
    final badges = List<String>.from(data['badges'] ?? []);
    final profileImageBase64 = data['profileImageBase64'] as String?;
    final profileImageUrl = data['profileImageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        children: [
          Center(child: _buildAvatar(profileImageBase64, profileImageUrl)),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    UserBadgesRow(badges: badges, size: 20),
                  ],
                ),
                if (age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.ageYears(age),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.biography,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          if (bio.isEmpty)
            Text(l10n.noBio, style: TextStyle(color: Colors.grey[600]))
          else
            Text(bio),
          if (link1.isNotEmpty || link2.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (link1.isNotEmpty) _buildLinkTile(link1),
            if (link2.isNotEmpty) _buildLinkTile(link2),
          ],
          const SizedBox(height: 28),
          Text(
            l10n.interests,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (interests.isEmpty)
            Text(l10n.noInterestsAdded, style: TextStyle(color: Colors.grey[600]))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Chip(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  label: Text(
                    getInterestName(interest, l10n),
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
    );
  }
}
