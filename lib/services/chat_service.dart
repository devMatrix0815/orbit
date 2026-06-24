import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatMessage>> getMessages(String circleId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> sendMessage(
    String circleId,
    String text, {
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
    List<String> mentionedUids = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final message = ChatMessage(
      id: '',
      circleId: circleId,
      senderId: user.uid,
      senderName: userData['displayName'] ?? 'Unbekannt',
      text: text,
      timestamp: DateTime.now().toUtc(),
      senderProfileImageBase64: userData['profileImageBase64'],
      senderProfileImageUrl: userData['profileImageUrl'],
      senderBadges: List<String>.from(userData['badges'] ?? []),
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      mentionedUids: mentionedUids,
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .add(message.toMap());

    if (mentionedUids.isNotEmpty) {
      final batch = _firestore.batch();
      for (final uid in mentionedUids) {
        batch.set(
          _firestore.collection('users').doc(uid),
          {'circlesWithMentions': FieldValue.arrayUnion([circleId])},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }

    await _firestore.collection('circles').doc(circleId).update({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': userData['displayName'] ?? 'Unbekannt',
    });
  }

  Future<void> markMentionsSeen(String circleId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set(
      {'circlesWithMentions': FieldValue.arrayRemove([circleId])},
      SetOptions(merge: true),
    );
  }

  Future<void> sendWidgetMessage(
    String circleId, {
    required String widgetType,
    required String widgetHtml,
    required Map<String, dynamic> initialState,
    required String previewText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final message = ChatMessage(
      id: '',
      circleId: circleId,
      senderId: user.uid,
      senderName: userData['displayName'] ?? 'Unbekannt',
      text: previewText,
      timestamp: DateTime.now().toUtc(),
      senderProfileImageBase64: userData['profileImageBase64'],
      senderProfileImageUrl: userData['profileImageUrl'],
      senderBadges: List<String>.from(userData['badges'] ?? []),
      type: MessageType.widget,
      widgetHtml: widgetHtml,
      widgetState: initialState,
      widgetType: widgetType,
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .add(message.toMap());

    await _firestore.collection('circles').doc(circleId).update({
      'lastMessage': previewText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': userData['displayName'] ?? 'Unbekannt',
    });
  }

  Future<void> updateWidgetState(
    String circleId,
    String messageId,
    String widgetType,
    Map<String, dynamic> action,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;

      final current = Map<String, dynamic>.from(doc.data()?['widgetState'] ?? {});

      final updated = switch (widgetType) {
        'poll' => _applyPollAction(current, action, user.uid),
        'todo' => _applyTodoAction(current, action, user.uid),
        _ => _applyCustomAction(current, action),
      };

      tx.update(ref, {'widgetState': updated});
    });
  }

  Map<String, dynamic> _applyPollAction(
    Map<String, dynamic> state,
    Map<String, dynamic> action,
    String userId,
  ) {
    if (action['action'] != 'vote') return state;
    final idx = action['optionIndex'];
    if (idx is! int) return state;

    final newState = Map<String, dynamic>.from(state);
    final options = List<dynamic>.from(newState['options'] ?? []);
    if (idx < 0 || idx >= options.length) return state;

    final isMultiple = newState['multipleChoice'] as bool? ?? false;

    if (!isMultiple) {
      for (int i = 0; i < options.length; i++) {
        final opt = Map<String, dynamic>.from(options[i]);
        final votes = List<String>.from(opt['votes'] ?? []);
        votes.remove(userId);
        opt['votes'] = votes;
        options[i] = opt;
      }
    }

    final opt = Map<String, dynamic>.from(options[idx]);
    final votes = List<String>.from(opt['votes'] ?? []);
    if (votes.contains(userId)) {
      votes.remove(userId);
    } else {
      votes.add(userId);
    }
    opt['votes'] = votes;
    options[idx] = opt;
    newState['options'] = options;
    return newState;
  }

  Map<String, dynamic> _applyTodoAction(
    Map<String, dynamic> state,
    Map<String, dynamic> action,
    String userId,
  ) {
    final newState = Map<String, dynamic>.from(state);
    final items = List<dynamic>.from(newState['items'] ?? []);

    switch (action['action']) {
      case 'addItem':
        final text = action['text'];
        if (text is! String || text.trim().isEmpty || text.length > 200) break;
        items.add({'text': text.trim(), 'done': false, 'addedBy': userId});
      case 'toggleItem':
        final index = action['index'];
        if (index is! int || index < 0 || index >= items.length) break;
        final item = Map<String, dynamic>.from(items[index]);
        item['done'] = !(item['done'] as bool? ?? false);
        items[index] = item;
      case 'removeItem':
        final index = action['index'];
        if (index is! int || index < 0 || index >= items.length) break;
        items.removeAt(index);
    }

    newState['items'] = items;
    return newState;
  }

  Map<String, dynamic> _applyCustomAction(
    Map<String, dynamic> state,
    Map<String, dynamic> action,
  ) {
    if (action['action'] != 'setState') return state;
    final newData = action['state'];
    if (newData == null || newData is! Map) return state;
    if (jsonEncode(newData).length > 10240) return state;
    return Map<String, dynamic>.from(newData);
  }

  Future<void> deleteMessage(String circleId, String messageId) async {
    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> deleteMessages(String circleId, List<String> messageIds) async {
    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.delete(
        _firestore
            .collection('circles')
            .doc(circleId)
            .collection('messages')
            .doc(id),
      );
    }
    await batch.commit();
  }

  Future<List<ChatMessage>> loadMoreMessages(
    String circleId,
    DateTime lastTimestamp,
  ) async {
    final snapshot = await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastTimestamp.toUtc().toIso8601String()])
        .limit(30)
        .get();

    return snapshot.docs.map((doc) {
      return ChatMessage.fromMap(doc.id, doc.data());
    }).toList();
  }

  Stream<int> getUnreadCount(String circleId, String userId) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('messages')
        .where('readBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

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
