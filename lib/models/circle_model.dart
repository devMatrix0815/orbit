import 'package:cloud_firestore/cloud_firestore.dart';

// circle data model
class Circle {
  final String id;
  final String name;
  final String createdBy; // uid of the creator
  final List<String> members; // uids of all members
  final int memberCount;
  final DateTime createdAt;
  final String? imageBase64; // group image stored as base64
  final List<String> tags;
  final String description;
  final String imageUrl;
  final List<String> operators;
  final List<String> banned;
  // 'open' | 'request' | 'invite_only'
  final String joinMode;

  Circle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.memberCount,
    required this.createdAt,
    this.imageBase64,
    required this.tags,
    required this.description,
    required this.imageUrl,
    this.operators = const [],
    this.banned = const [],
    this.joinMode = 'open',
  });

  // create circle from firestore document
  factory Circle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Circle(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageBase64: data['imageBase64'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      operators: List<String>.from(data['operators'] ?? []),
      banned: List<String>.from(data['banned'] ?? []),
      joinMode: data['joinMode'] as String? ?? 'open',
    );
  }
}
