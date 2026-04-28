import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Send a message to a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String type = 'text',
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream for a conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Create a new conversation
  Future<String> createConversation({
    required List<String> participantIds,
    String? groupName,
    bool isGroup = false,
  }) async {
    final docRef = _firestore.collection('conversations').doc();
    
    await docRef.set({
      'createdBy': currentUserId,
      'participants': participantIds,
      'isGroup': isGroup,
      'groupName': groupName,
      'admins': isGroup ? [currentUserId] : [],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });

    // Add participants as members subcollection
    for (final uid in participantIds) {
      await docRef.collection('members').doc(uid).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'role': isGroup && uid == currentUserId ? 'admin' : 'member',
      });
    }

    return docRef.id;
  }

  // Get user's conversations
  Stream<QuerySnapshot> getConversations() {
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Update last message in conversation
  Future<void> updateLastMessage(String conversationId, String text) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Add member to group
  Future<void> addMember(String conversationId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('members')
        .doc(userId)
        .set({
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'member',
    });

    // Update participants array
    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(doc.data()?['participants'] ?? []);
    if (!participants.contains(userId)) {
      participants.add(userId);
      await _firestore.collection('conversations').doc(conversationId).update({
        'participants': participants,
      });
    }
  }

  // Remove member from group
  Future<void> removeMember(String conversationId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('members')
        .doc(userId)
        .delete();

    // Update participants array
    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(doc.data()?['participants'] ?? []);
    participants.remove(userId);
    await _firestore.collection('conversations').doc(conversationId).update({
      'participants': participants,
    });
  }

  // Get conversation details
  Future<DocumentSnapshot> getConversation(String conversationId) async {
    return _firestore.collection('conversations').doc(conversationId).get();
  }

  // Delete message (only by sender)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    if (currentUserId == null) return;
    
    final messageDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();
    
    if (messageDoc.data()?['senderId'] == currentUserId) {
      await messageDoc.reference.delete();
    }
  }
}