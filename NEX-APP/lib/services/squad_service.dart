import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SquadService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> createSquad({
    required String name,
    required String description,
    String? game,
    int maxMembers = 5,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client.from('squads').insert({
        'name': name,
        'description': description,
        'game': game,
        'leaderId': currentUserId,
        'members': [currentUserId],
        'maxMembers': maxMembers,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isActive': true,
      }).select().single();

      if (response is Map<String, dynamic>) {
        return response['id']?.toString() ?? '';
      }
      throw Exception('Unable to create squad');
    } catch (e) {
      debugPrint('Error creating squad: $e');
      rethrow;
    }
  }

  Future<void> joinSquad(String squadId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final squad = await _client.from('squads').select().eq('id', squadId).maybeSingle();
      if (squad == null || squad is! Map<String, dynamic>) {
        throw Exception('Squad not found');
      }

      final members = List<String>.from(squad['members'] ?? []);
      final maxMembers = squad['maxMembers'] ?? 5;

      if (members.contains(currentUserId)) throw Exception('Already a member');
      if (members.length >= maxMembers) throw Exception('Squad is full');

      members.add(currentUserId!);
      await _client.from('squads').update({'members': members}).eq('id', squadId);
    } catch (e) {
      debugPrint('Error joining squad: $e');
      rethrow;
    }
  }

  Future<void> leaveSquad(String squadId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final squad = await _client.from('squads').select().eq('id', squadId).maybeSingle();
      if (squad == null || squad is! Map<String, dynamic>) {
        throw Exception('Squad not found');
      }

      final members = List<String>.from(squad['members'] ?? []);
      final leaderId = squad['leaderId']?.toString();

      if (!members.contains(currentUserId)) throw Exception('Not a member');

      if (currentUserId == leaderId && members.length > 1) {
        members.remove(currentUserId);
        final newLeader = members.first;
        await _client.from('squads').update({'members': members, 'leaderId': newLeader}).eq('id', squadId);
      } else if (members.length == 1) {
        await _client.from('squads').delete().eq('id', squadId);
      } else {
        members.remove(currentUserId);
        await _client.from('squads').update({'members': members}).eq('id', squadId);
      }
    } catch (e) {
      debugPrint('Error leaving squad: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSquads() {
    try {
      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('squads')
            .select()
            .eq('isActive', true)
            .order('createdAt', ascending: false);

        if (response is! List) return <Map<String, dynamic>>[];
        return (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
      }()).handleError((e) {debugPrint('Error getting squads: $e');});
    } catch (e) {
      debugPrint('Error setting up squads stream: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserSquads() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('squads')
            .select()
            .contains('members', [currentUserId!])
            .eq('isActive', true)
            .order('createdAt', ascending: false);

        if (response is! List) return <Map<String, dynamic>>[];
        return (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
      }()).handleError((e) {debugPrint('Error getting user squads: $e');});
    } catch (e) {
      debugPrint('Error setting up user squads stream: $e');
      rethrow;
    }
  }

  Future<void> sendSquadMessage({
    required String squadId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('squadMessages').insert({
        'squadId': squadId,
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending squad message: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSquadMessages(String squadId) {
    try {
      return _client
          .from('squadMessages')
          .stream(primaryKey: ['id'])
          .eq('squadId', squadId)
          .order('timestamp', ascending: false)
          .map((rows) {
            return rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
          })
          .handleError((e) {debugPrint('Error getting squad messages: $e');});
    } catch (e) {
      debugPrint('Error setting up squad messages stream: $e');
      rethrow;
    }
  }

  Future<String> createSquadSession({
    required String squadId,
    required String title,
    required DateTime startTime,
    String? description,
    String? gameMode,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client.from('squadSessions').insert({
        'squadId': squadId,
        'title': title,
        'description': description,
        'gameMode': gameMode,
        'startTime': startTime.toUtc().toIso8601String(),
        'creatorId': currentUserId,
        'participants': [currentUserId],
        'status': 'scheduled',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (response is Map<String, dynamic>) {
        return response['id']?.toString() ?? '';
      }
      throw Exception('Unable to create squad session');
    } catch (e) {
      debugPrint('Error creating squad session: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSquadSessions(String squadId) {
    try {
      return _client
          .from('squadSessions')
          .stream(primaryKey: ['id'])
          .eq('squadId', squadId)
          .order('startTime', ascending: true)
          .map((rows) {
            return rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
          })
          .handleError((e) {debugPrint('Error getting squad sessions: $e');});
    } catch (e) {
      debugPrint('Error setting up squad sessions stream: $e');
      rethrow;
    }
  }
}
