import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';

class StoryService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> postStory({
    required String circleId,
    required String imageBase64,
    required List<TextOverlay> textOverlays,
    required String creatorId,
    required String creatorName,
    String? creatorImageBase64,
  }) async {
    final now = DateTime.now();
    await _db.collection('stories').add({
      'circleId': circleId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImageBase64': creatorImageBase64,
      'imageBase64': imageBase64,
      'textOverlays': textOverlays.map((o) => o.toMap()).toList(),
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String>[],
    });
  }

  static Future<List<Story>> getActiveStoriesForCircle(String circleId) async {
    final snap = await _db
        .collection('stories')
        .where('circleId', isEqualTo: circleId)
        .get();
    final now = DateTime.now();
    final list = snap.docs
        .map(Story.fromFirestore)
        .where((s) => s.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  static Future<void> markViewed(String storyId, String userId) async {
    await _db.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([userId]),
    });
  }
}
