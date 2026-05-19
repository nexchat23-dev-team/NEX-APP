import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Generate a unique invite code for group
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return code;
  }

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
      
      // Generate unique invite code for groups
      final inviteCode = isGroup ? _generateInviteCode() : null;
      
      await docRef.set({
        'createdBy': currentUserId,
        'participants': participantIds,
        'isGroup': isGroup,
        'groupName': groupName,
        'admins': isGroup ? [currentUserId] : [],
        'inviteCode': inviteCode,
        'inviteLink': isGroup ? 'nex://group/$inviteCode' : null,
        'autoJoinEnabled': isGroup ? false : null, // Default to manual approval
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

  // Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'archived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error archiving conversation: $e');
      rethrow;
    }
  }

  // Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'archived': false,
        'unarchivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error unarchiving conversation: $e');
      rethrow;
    }
  }

  // Pin conversation
  Future<void> pinConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'pinned': true,
        'pinnedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error pinning conversation: $e');
      rethrow;
    }
  }

  // Unpin conversation
  Future<void> unpinConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'pinned': false,
        'unpinnedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error unpinning conversation: $e');
      rethrow;
    }
  }

  // Mute conversation
  Future<void> muteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'muted': true,
        'mutedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error muting conversation: $e');
      rethrow;
    }
  }

  // Unmute conversation
  Future<void> unmuteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .set({
        'muted': false,
        'unmutedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error unmuting conversation: $e');
      rethrow;
    }
  }

  // Block user
  Future<void> blockUser(String userId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      await _firestore.collection('blockedUsers').add({
        'blockerId': currentUserId,
        'blockedId': userId,
        'blockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      final query = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: userId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      if (currentUserId == null) return false;

      final query = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: currentUserId)
          .where('blockedId', isEqualTo: userId)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Get user settings for conversation
  Future<Map<String, dynamic>> getConversationSettings(String conversationId) async {
    try {
      if (currentUserId == null) return {};

      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('userSettings')
          .doc(currentUserId)
          .get();

      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error getting conversation settings: $e');
      return {};
    }
  }

  // Delete conversation (leave group or delete direct chat)
  Future<void> deleteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
      final data = conversationDoc.data();

      if (data == null) throw Exception('Conversation not found');

      final isGroup = data['isGroup'] as bool? ?? false;
      final participants = List<String>.from(data['participants'] ?? []);

      if (isGroup) {
        // For groups, remove user from participants
        participants.remove(currentUserId);
        if (participants.isEmpty) {
          // If no participants left, delete the entire conversation
          await conversationDoc.reference.delete();
        } else {
          // Update participants list
          await conversationDoc.reference.update({
            'participants': participants,
          });

          // Remove from members subcollection
          await conversationDoc.reference.collection('members').doc(currentUserId).delete();
        }
      } else {
        // For direct chats, mark as deleted for this user
        await conversationDoc.reference.collection('userSettings').doc(currentUserId).set({
          'deleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  // Get group invite link by conversation ID
  Future<String?> getGroupInviteLink(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (doc.exists) {
        return doc.data()?['inviteLink'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group invite link: $e');
      return null;
    }
  }

  // Get group invite code by conversation ID
  Future<String?> getGroupInviteCode(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (doc.exists) {
        return doc.data()?['inviteCode'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group invite code: $e');
      return null;
    }
  }

  // Find group by invite code
  Future<Map<String, dynamic>?> findGroupByInviteCode(String inviteCode) async {
    try {
      final query = await _firestore
          .collection('conversations')
          .where('inviteCode', isEqualTo: inviteCode)
          .where('isGroup', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return {
          'id': doc.id,
          'name': doc.data()['groupName'] ?? 'Group',
          'members': doc.data()['participants'] ?? [],
          'autoJoinEnabled': doc.data()['autoJoinEnabled'] as bool? ?? false,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error finding group by invite code: $e');
      return null;
    }
  }

  // Regenerate group invite code
  Future<String> regenerateGroupInviteCode(String conversationId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      // Check if user is admin
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      final admins = List<String>.from(doc.data()?['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can regenerate invite codes');
      }

      final newCode = _generateInviteCode();
      await _firestore.collection('conversations').doc(conversationId).update({
        'inviteCode': newCode,
        'inviteLink': 'nex://group/$newCode',
      });

      return newCode;
    } catch (e) {
      debugPrint('Error regenerating invite code: $e');
      rethrow;
    }
  }

  // Get group auto-join setting
  Future<bool> getAutoJoinSetting(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      return doc.data()?['autoJoinEnabled'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error getting auto-join setting: $e');
      return false;
    }
  }

  // Toggle auto-join setting (admin only)
  Future<void> setAutoJoinSetting(String conversationId, bool enabled) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      final admins = List<String>.from(doc.data()?['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can change group settings');
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'autoJoinEnabled': enabled,
      });
    } catch (e) {
      debugPrint('Error setting auto-join: $e');
      rethrow;
    }
  }

  // Request to join a group
  Future<String> requestToJoinGroup(String conversationId, String? displayName) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      // Check if already a member
      final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
      final participants = List<String>.from(conversationDoc.data()?['participants'] ?? []);

      if (participants.contains(currentUserId)) {
        throw Exception('Already a member of this group');
      }

      // Create join request
      final requestRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('joinRequests')
          .doc(currentUserId);

      await requestRef.set({
        'userId': currentUserId,
        'userEmail': displayName ?? '',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      return currentUserId!;
    } catch (e) {
      debugPrint('Error requesting to join group: $e');
      rethrow;
    }
  }

  // Join group via invite code (handles auto-join and manual join)
  Future<String?> joinGroupByInviteCode(String inviteCode) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final groupData = await findGroupByInviteCode(inviteCode);
      if (groupData == null) {
        throw Exception('Invalid invite code');
      }

      final conversationId = groupData['id'] as String;
      final autoJoinEnabled = groupData['autoJoinEnabled'] as bool? ?? false;

      // Check if already a member
      final members = List<String>.from(groupData['members'] ?? []);
      if (members.contains(currentUserId)) {
        return conversationId;
      }

      if (autoJoinEnabled) {
        // Auto-join: add user directly
        await addMember(conversationId, currentUserId!);
        return conversationId;
      } else {
        // Manual approval: create join request
        await requestToJoinGroup(conversationId, '');
        return null; // Return null to indicate pending request
      }
    } catch (e) {
      debugPrint('Error joining group by invite code: $e');
      rethrow;
    }
  }

  // Get pending join requests for a group (admin only)
  Stream<QuerySnapshot> getPendingJoinRequests(String conversationId) {
    try {
      return _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots();
    } catch (e) {
      debugPrint('Error getting pending join requests: $e');
      return const Stream.empty();
    }
  }

  // Approve join request
  Future<void> approveJoinRequest(String conversationId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      // Check if user is admin
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      final admins = List<String>.from(doc.data()?['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can approve join requests');
      }

      // Update request status
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('joinRequests')
          .doc(userId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUserId,
      });

      // Add user as member
      await addMember(conversationId, userId);
    } catch (e) {
      debugPrint('Error approving join request: $e');
      rethrow;
    }
  }

  // Reject join request
  Future<void> rejectJoinRequest(String conversationId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      // Check if user is admin
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      final admins = List<String>.from(doc.data()?['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can reject join requests');
      }

      // Update request status
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('joinRequests')
          .doc(userId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': currentUserId,
      });
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      rethrow;
    }
  }

  // Check if user has pending join request
  Future<bool> hasPendingJoinRequest(String conversationId) async {
    try {
      if (currentUserId == null) return false;

      final request = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('joinRequests')
          .doc(currentUserId)
          .get();

      return request.exists && request.data()?['status'] == 'pending';
    } catch (e) {
      debugPrint('Error checking join request: $e');
      return false;
    }
  }
}
