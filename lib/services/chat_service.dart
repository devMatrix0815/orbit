import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for Chat messages
  Stream<List<ChatMessage>> getMessages(String circleId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // limit to 50 messages per load
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // send new message
  Future<void> sendMessage(String circleId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    // get userdata
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final message = ChatMessage(
      id: '',
      circleId: circleId,
      senderId: user.uid,
      senderName: userData['displayName'] ?? 'Unbekannt',
      text: text,
      timestamp: DateTime.now(),
      senderProfileImageBase64: userData['profileImageBase64'],
      senderProfileImageUrl: userData['profileImageUrl'],
      senderBadges: List<String>.from(userData['badges'] ?? []),
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .add(message.toMap());

    // update last message
    await _firestore.collection('circles').doc(circleId).update({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': userData['displayName'] ?? 'Unbekannt',
    });
  }

  // Load older messages (Pagination)
  Future<List<ChatMessage>> loadMoreMessages(
    String circleId,
    DateTime lastTimestamp,
  ) async {
    final snapshot = await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastTimestamp.toIso8601String()])
        .limit(30)
        .get();

    return snapshot.docs.map((doc) {
      return ChatMessage.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Message count
  Stream<int> getUnreadCount(String circleId, String userId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .where('readBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  Future<void> markAsRead(
    String circleId,
    String messageId,
    String userId,
  ) async {
    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(messageId)
        .update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
  }
}
