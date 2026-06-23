import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String circleId;
  final String circleName;
  final String? circleImageBase64;
  final String? circleImageUrl;
  final String requestingUserId;
  final String requestingDisplayName;
  final String? requestingUserImageBase64;
  final String? requestingUserImageUrl;
  final DateTime requestedAt;
  final String status; // pending, accepted, declined
  final String adminId;

  JoinRequest({
    required this.id,
    required this.circleId,
    required this.circleName,
    this.circleImageBase64,
    this.circleImageUrl,
    required this.requestingUserId,
    required this.requestingDisplayName,
    this.requestingUserImageBase64,
    this.requestingUserImageUrl,
    required this.requestedAt,
    required this.status,
    required this.adminId,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      circleName: data['circleName'] ?? '',
      circleImageBase64: data['circleImageBase64'] as String?,
      circleImageUrl: data['circleImageUrl'] as String?,
      requestingUserId: data['requestingUserId'] ?? '',
      requestingDisplayName: data['requestingDisplayName'] ?? '',
      requestingUserImageBase64: data['requestingUserImageBase64'] as String?,
      requestingUserImageUrl: data['requestingUserImageUrl'] as String?,
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      adminId: data['adminId'] ?? '',
    );
  }
}
