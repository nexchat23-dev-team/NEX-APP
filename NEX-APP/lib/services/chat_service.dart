import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    try {
      if (currentUserId == null) {
        debugPrint('Error: No current user');
        return;
      }

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
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for a conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    try {
      return _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting messages: $e');
      });
    } catch (e) {
      debugPrint('Error setting up messages stream: $e');
      return const Stream.empty();
    }
  }

  // Create a new conversation
  Future<String> createConversation({
    required List<String> participantIds,
    String? groupName,
    bool isGroup = false,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

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
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  // Get user's conversations
  Stream<QuerySnapshot> getConversations() {
    try {
      if (currentUserId == null) {
        debugPrint('Error: No current user for conversations');
        return const Stream.empty();
      }

      return _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting conversations: $e');
      });
    } catch (e) {
      debugPrint('Error setting up conversations stream: $e');
      return const Stream.empty();
    }
  }

  // Update last message in conversation
  Future<void> updateLastMessage(String conversationId, String text) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last message: $e');
      rethrow;
    }
  }

  // Add member to group
  Future<void> addMember(String conversationId, String userId) async {
    try {
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
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  // Remove member from group
  Future<void> removeMember(String conversationId, String userId) async {
    try {
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
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  // Get conversation details
  Future<DocumentSnapshot> getConversation(String conversationId) async {
    try {
      return await _firestore.collection('conversations').doc(conversationId).get();
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      rethrow;
    }
  }

  // Delete message (only by sender)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }
      
      final messageDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (messageDoc.data()?['senderId'] == currentUserId) {
        await messageDoc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }
}
