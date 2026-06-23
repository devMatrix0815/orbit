import 'package:cloud_firestore/cloud_firestore.dart';

// invite data model for joining a circle
class CircleInvite {
  final String id;
  final String circleId;
  final String circleName;
  final String? circleImageBase64;
  final String? circleImageUrl;
  final String invitedUserId;
  final String invitedDisplayName;
  final String? invitedProfileImageBase64;
  final String? invitedProfileImageUrl;
  final String invitedBy; // uid of the user who sent the invite
  final DateTime invitedAt;
  final String status; // pending, accepted or declined

  CircleInvite({
    required this.id,
    required this.circleId,
    required this.circleName,
    this.circleImageBase64,
    this.circleImageUrl,
    required this.invitedUserId,
    required this.invitedDisplayName,
    this.invitedProfileImageBase64,
    this.invitedProfileImageUrl,
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
      circleImageBase64: data['circleImageBase64'] as String?,
      circleImageUrl: data['circleImageUrl'] as String?,
      invitedUserId: data['invitedUserId'] ?? '',
      invitedDisplayName: data['invitedDisplayName'] ?? '',
      invitedProfileImageBase64: data['invitedProfileImageBase64'] as String?,
      invitedProfileImageUrl: data['invitedProfileImageUrl'] as String?,
      invitedBy: data['invitedBy'] ?? '',
      invitedAt: (data['invitedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}
