import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return code;
  }

  Map<String, dynamic> _normalizeConversation(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    data['id'] = data['id'] ?? data['conversation_id'];
    data['createdBy'] = data['created_by'] ?? data['createdBy'];
    data['groupName'] = data['group_name'] ?? data['groupName'];
    data['isGroup'] = data['is_group'] ?? data['isGroup'] ?? false;
    data['lastMessage'] = data['last_message'] ?? data['lastMessage'];
    data['lastMessageTime'] = data['last_message_time'] ?? data['lastMessageTime'];
    data['inviteCode'] = data['invite_code'] ?? data['inviteCode'];
    data['inviteLink'] = data['invite_link'] ?? data['inviteLink'];
    data['autoJoinEnabled'] = data['auto_join_enabled'] ?? data['autoJoinEnabled'] ?? false;
    return data;
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    data['id'] = data['id'];
    data['senderId'] = data['sender_id'] ?? data['senderId'];
    data['conversationId'] = data['conversation_id'] ?? data['conversationId'];
    data['audioUrl'] = data['audio_url'] ?? data['audioUrl'];
    data['replyTo'] = data['reply_to'] ?? data['replyTo'];
    data['replyText'] = data['reply_text'] ?? data['replyText'];
    data['replySender'] = data['reply_sender'] ?? data['replySender'];
    data['timestamp'] = data['created_at'] ?? data['timestamp'];
    return data;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String type = 'text',
    String? audioUrl,
    String? replyTo,
    String? replyText,
    String? replySender,
  }) async {
    try {
      if (currentUserId == null) {
        debugPrint('Error: No current user');
        return;
      }

      final messageData = {
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'text': text,
        'type': type,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (audioUrl != null) messageData['audio_url'] = audioUrl;
      if (replyTo != null) messageData['reply_to'] = replyTo;
      if (replyText != null) messageData['reply_text'] = replyText;
      if (replySender != null) messageData['reply_sender'] = replySender;

      await _client.from('messages').insert(messageData);
      await updateLastMessage(conversationId, text.isNotEmpty ? text : '[Audio message]');
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<String> uploadAudioMessage(String conversationId, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final path = 'audio_messages/$conversationId/$fileName';
      await _client.storage.from('chat-media').upload(path, file);
      return _client.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading audio message: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) {
          final normalized = rows
              .map((row) => _normalizeMessage(Map<String, dynamic>.from(row)))
              .toList();
          normalized.sort((a, b) {
            final aTime = a['timestamp']?.toString() ?? '';
            final bTime = b['timestamp']?.toString() ?? '';
            return aTime.compareTo(bTime);
          });
          return normalized;
        });
  }

  Future<String> createConversation({
    required List<String> participantIds,
    String? groupName,
    bool isGroup = false,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final inviteCode = isGroup ? _generateInviteCode() : null;
      final insertData = <String, dynamic>{
        'created_by': currentUserId,
        'participants': participantIds,
        'is_group': isGroup,
        'group_name': groupName,
        'admins': isGroup ? [currentUserId] : [],
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'last_message': null,
        'last_message_time': null,
        'auto_join_enabled': false,
      };
      if (inviteCode != null) {
        insertData['invite_code'] = inviteCode;
        insertData['invite_link'] = 'nex://group/$inviteCode';
      }

      final response = await _client.from('conversations').insert(insertData).select().single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  Future<String> createOrGetDirectConversation(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('No current user');
    }

    final rows = await _client
        .from('conversations')
        .select()
        .or('participants.cs.{${currentUserId!},${otherUserId}}');

    for (final row in rows) {
      final participants = List<String>.from(row['participants'] ?? []);
      if (participants.length == 2 && participants.contains(currentUserId) && participants.contains(otherUserId)) {
        return row['id'] as String;
      }
    }

    return createConversation(participantIds: [currentUserId!, otherUserId], isGroup: false);
  }

  Stream<List<Map<String, dynamic>>> getConversations() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filtered = rows.where((row) {
            final participants = row['participants'] as List<dynamic>? ?? const [];
            return participants.contains(currentUserId);
          }).map((row) => _normalizeConversation(Map<String, dynamic>.from(row))).toList();
          filtered.sort((a, b) {
            final aTime = a['lastMessageTime']?.toString() ?? '';
            final bTime = b['lastMessageTime']?.toString() ?? '';
            return bTime.compareTo(aTime);
          });
          return filtered;
        });
  }

  Future<void> updateLastMessage(String conversationId, String text) async {
    try {
      await _client.from('conversations').update({
        'last_message': text,
        'last_message_time': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error updating last message: $e');
      rethrow;
    }
  }

  Future<void> addMember(String conversationId, String userId) async {
    try {
      final current = await _client.from('conversations').select().eq('id', conversationId).single();
      final participants = List<String>.from(current['participants'] ?? []);
      if (!participants.contains(userId)) {
        participants.add(userId);
        await _client.from('conversations').update({'participants': participants}).eq('id', conversationId);
      }
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  Future<void> removeMember(String conversationId, String userId) async {
    try {
      final current = await _client.from('conversations').select().eq('id', conversationId).single();
      final participants = List<String>.from(current['participants'] ?? []);
      if (participants.contains(userId)) {
        participants.remove(userId);
        await _client.from('conversations').update({'participants': participants}).eq('id', conversationId);
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      return _normalizeConversation(Map<String, dynamic>.from(row));
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final message = await _client.from('messages').select().eq('id', messageId).single();
      if (message['sender_id'] == currentUserId) {
        await _client.from('messages').delete().eq('id', messageId);
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'archived': true}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error archiving conversation: $e');
      rethrow;
    }
  }

  Future<void> unarchiveConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'archived': false}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error unarchiving conversation: $e');
      rethrow;
    }
  }

  Future<void> pinConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'pinned': true}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error pinning conversation: $e');
      rethrow;
    }
  }

  Future<void> unpinConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'pinned': false}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error unpinning conversation: $e');
      rethrow;
    }
  }

  Future<void> muteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'muted': true}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error muting conversation: $e');
      rethrow;
    }
  }

  Future<void> unmuteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('conversations').update({'muted': false}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error unmuting conversation: $e');
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('blocked_users').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');
      await _client.from('blocked_users').delete().eq('blocker_id', currentUserId!).eq('blocked_id', userId);
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    try {
      if (currentUserId == null) return false;
      final result = await _client.from('blocked_users').select().eq('blocker_id', currentUserId!).eq('blocked_id', userId).limit(1);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getConversationSettings(String conversationId) async {
    try {
      if (currentUserId == null) return {};
      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      return {
        'archived': row['archived'] ?? false,
        'pinned': row['pinned'] ?? false,
        'muted': row['muted'] ?? false,
      };
    } catch (e) {
      debugPrint('Error getting conversation settings: $e');
      return {};
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      if (currentUserId == null) throw Exception('No current user');

      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      final isGroup = row['is_group'] ?? false;
      final participants = List<String>.from(row['participants'] ?? []);

      if (isGroup) {
        participants.remove(currentUserId);
        if (participants.isEmpty) {
          await _client.from('conversations').delete().eq('id', conversationId);
        } else {
          await _client.from('conversations').update({'participants': participants}).eq('id', conversationId);
        }
      } else {
        await _client.from('conversations').update({'deleted_by': [currentUserId]}).eq('id', conversationId);
      }
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<String?> getGroupInviteLink(String conversationId) async {
    try {
      final data = await getConversation(conversationId);
      return data['inviteLink'] as String?;
    } catch (e) {
      debugPrint('Error getting group invite link: $e');
      return null;
    }
  }

  Future<String?> getGroupInviteCode(String conversationId) async {
    try {
      final data = await getConversation(conversationId);
      return data['inviteCode'] as String?;
    } catch (e) {
      debugPrint('Error getting group invite code: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> findGroupByInviteCode(String inviteCode) async {
    try {
      final row = await _client.from('conversations').select().eq('invite_code', inviteCode).eq('is_group', true).limit(1).maybeSingle();
      if (row == null) {
        return null;
      }
      final data = _normalizeConversation(Map<String, dynamic>.from(row));
      return {
        'id': data['id'],
        'name': data['groupName'] ?? 'Group',
        'members': data['participants'] ?? [],
        'autoJoinEnabled': data['autoJoinEnabled'] as bool? ?? false,
      };
    } catch (e) {
      debugPrint('Error finding group by invite code: $e');
      return null;
    }
  }

  Future<String> regenerateGroupInviteCode(String conversationId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      final admins = List<String>.from(row['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can regenerate invite codes');
      }

      final newCode = _generateInviteCode();
      await _client.from('conversations').update({
        'invite_code': newCode,
        'invite_link': 'nex://group/$newCode',
      }).eq('id', conversationId);

      return newCode;
    } catch (e) {
      debugPrint('Error regenerating invite code: $e');
      rethrow;
    }
  }

  Future<bool> getAutoJoinSetting(String conversationId) async {
    try {
      final data = await getConversation(conversationId);
      return data['autoJoinEnabled'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error getting auto-join setting: $e');
      return false;
    }
  }

  Future<void> setAutoJoinSetting(String conversationId, bool enabled) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      final admins = List<String>.from(row['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can change group settings');
      }

      await _client.from('conversations').update({'auto_join_enabled': enabled}).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error setting auto-join: $e');
      rethrow;
    }
  }

  Future<String> requestToJoinGroup(String conversationId, String? displayName) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final conversation = await _client.from('conversations').select().eq('id', conversationId).single();
      final participants = List<String>.from(conversation['participants'] ?? []);

      if (participants.contains(currentUserId)) {
        throw Exception('Already a member of this group');
      }

      await _client.from('join_requests').insert({
        'conversation_id': conversationId,
        'user_id': currentUserId,
        'user_email': displayName ?? '',
        'status': 'pending',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
      });

      return currentUserId!;
    } catch (e) {
      debugPrint('Error requesting to join group: $e');
      rethrow;
    }
  }

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
      final members = List<String>.from(groupData['members'] ?? []);
      if (members.contains(currentUserId)) {
        return conversationId;
      }

      if (autoJoinEnabled) {
        await addMember(conversationId, currentUserId!);
        return conversationId;
      }

      await requestToJoinGroup(conversationId, '');
      return null;
    } catch (e) {
      debugPrint('Error joining group by invite code: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingJoinRequests(String conversationId) {
    StreamController<List<Map<String, dynamic>>>? controller;
    Timer? timer;

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(onCancel: () {
      timer?.cancel();
    });

    Future<void> fetchRequests() async {
      try {
        final rows = await _client.from('join_requests').select();
        final filtered = rows.where((row) => row['conversation_id'] == conversationId && row['status'] == 'pending').map((row) => Map<String, dynamic>.from(row)).toList();
        controller?.add(filtered);
      } catch (e) {
        debugPrint('Error getting pending join requests: $e');
        controller?.addError(e);
      }
    }

    unawaited(fetchRequests());
    timer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(fetchRequests()));

    return controller.stream;
  }

  Future<void> approveJoinRequest(String conversationId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      final admins = List<String>.from(row['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can approve join requests');
      }

      await _client.from('join_requests').update({
        'status': 'approved',
        'approved_at': DateTime.now().toUtc().toIso8601String(),
        'approved_by': currentUserId,
      }).eq('conversation_id', conversationId).eq('user_id', userId);

      await addMember(conversationId, userId);
    } catch (e) {
      debugPrint('Error approving join request: $e');
      rethrow;
    }
  }

  Future<void> rejectJoinRequest(String conversationId, String userId) async {
    try {
      if (currentUserId == null) {
        throw Exception('No current user');
      }

      final row = await _client.from('conversations').select().eq('id', conversationId).single();
      final admins = List<String>.from(row['admins'] ?? []);

      if (!admins.contains(currentUserId)) {
        throw Exception('Only admins can reject join requests');
      }

      await _client.from('join_requests').update({
        'status': 'rejected',
        'rejected_at': DateTime.now().toUtc().toIso8601String(),
        'rejected_by': currentUserId,
      }).eq('conversation_id', conversationId).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      rethrow;
    }
  }

  Future<bool> hasPendingJoinRequest(String conversationId) async {
    try {
      if (currentUserId == null) return false;
      final rows = await _client.from('join_requests').select().eq('conversation_id', conversationId).eq('user_id', currentUserId!).eq('status', 'pending').limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking join request: $e');
      return false;
    }
  }
}
