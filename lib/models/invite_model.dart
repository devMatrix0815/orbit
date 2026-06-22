import 'package:cloud_firestore/cloud_firestore.dart';

// invite data model for joining a circle
class CircleInvite {
  final String id;
  final String circleId;
  final String circleName;
  final String invitedUserId;
  final String invitedDisplayName;
  final String invitedBy; // uid of the user who sent the invite
  final DateTime invitedAt;
  final String status; // pending, accepted or declined

  CircleInvite({
    required this.id,
    required this.circleId,
    required this.circleName,
    required this.invitedUserId,
    required this.invitedDisplayName,
    required this.invitedBy,
    required this.invitedAt,
    required this.status,
  });

  // create invite from firestore document
  factory CircleInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CircleInvite(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      circleName: data['circleName'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      invitedDisplayName: data['invitedDisplayName'] ?? '',
      invitedBy: data['invitedBy'] ?? '',
      invitedAt: (data['invitedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}
