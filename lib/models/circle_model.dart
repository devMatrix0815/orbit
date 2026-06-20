import 'package:cloud_firestore/cloud_firestore.dart';

class Circle {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final int memberCount;
  final DateTime createdAt;
  final String? imageBase64;

  Circle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.memberCount,
    required this.createdAt,
    this.imageBase64,
  });

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
    );
  }
}
