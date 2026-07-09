import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ClanService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> createClan({
    required String name,
    required String description,
    String? motto,
    String? bannerUrl,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client.from('clans').insert({
        'name': name,
        'description': description,
        'motto': motto,
        'bannerUrl': bannerUrl,
        'founderId': currentUserId,
        'admins': [currentUserId],
        'members': [currentUserId],
        'level': 1,
        'experience': 0,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isActive': true,
      }).select().single();

      if (response is Map<String, dynamic>) {
        return response['id']?.toString() ?? '';
      }
      throw Exception('Unable to create clan');
    } catch (e) {
      debugPrint('Error creating clan: $e');
      rethrow;
    }
  }

  Future<void> requestJoinClan(String clanId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('clanJoinRequests').insert({
        'clanId': clanId,
        'userId': currentUserId,
        'status': 'pending',
        'requestedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error requesting to join clan: $e');
      rethrow;
    }
  }

  Future<void> approveJoinRequest(String requestId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final request = await _client
          .from('clanJoinRequests')
          .select()
          .eq('id', requestId)
          .maybeSingle();

      if (request == null || request is! Map<String, dynamic>) {
        throw Exception('Request not found');
      }

      final clanId = request['clanId']?.toString();
      final userId = request['userId']?.toString();
      if (clanId == null || userId == null) {
        throw Exception('Invalid request data');
      }

      final clan = await _client
          .from('clans')
          .select()
          .eq('id', clanId)
          .maybeSingle();
      if (clan == null || clan is! Map<String, dynamic>) {
        throw Exception('Clan not found');
      }

      final members = List<String>.from(clan['members'] ?? []);
      if (!members.contains(userId)) {
        members.add(userId);
        await _client.from('clans').update({'members': members}).eq('id', clanId);
      }

      await _client.from('clanJoinRequests').update({
        'status': 'approved',
        'approvedAt': DateTime.now().toUtc().toIso8601String(),
        'approvedBy': currentUserId,
      }).eq('id', requestId);
    } catch (e) {
      debugPrint('Error approving join request: $e');
      rethrow;
    }
  }

  Future<void> leaveClan(String clanId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final clan = await _client
          .from('clans')
          .select()
          .eq('id', clanId)
          .maybeSingle();

      if (clan == null || clan is! Map<String, dynamic>) {
        throw Exception('Clan not found');
      }

      final members = List<String>.from(clan['members'] ?? []);
      final admins = List<String>.from(clan['admins'] ?? []);
      final founderId = clan['founderId']?.toString();

      if (!members.contains(currentUserId)) throw Exception('Not a member');

      members.remove(currentUserId);
      admins.remove(currentUserId);

      if (members.isEmpty) {
        await _client.from('clans').delete().eq('id', clanId);
        return;
      }

      String newFounderId = founderId ?? members.first;
      if (currentUserId == founderId) {
        newFounderId = members.first;
        if (!admins.contains(newFounderId)) {
          admins.add(newFounderId);
        }
      }

      await _client.from('clans').update({
        'members': members,
        'admins': admins,
        'founderId': newFounderId,
      }).eq('id', clanId);
    } catch (e) {
      debugPrint('Error leaving clan: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getClans() {
    try {
      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('clans')
            .select()
            .eq('isActive', true)
            .order('createdAt', ascending: false);

        if (response is! List) return <Map<String, dynamic>>[];
        return (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
      }()).handleError((e) {debugPrint('Error getting clans: $e');});
    } catch (e) {
      debugPrint('Error setting up clans stream: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserClans() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('clans')
            .select()
            .contains('members', [currentUserId!])
            .eq('isActive', true)
            .order('createdAt', ascending: false);

        if (response is! List) return <Map<String, dynamic>>[];
        return (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
      }()).handleError((e) {debugPrint('Error getting user clans: $e');});
    } catch (e) {
      debugPrint('Error setting up user clans stream: $e');
      rethrow;
    }
  }

  Future<void> sendClanMessage({
    required String clanId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('clanMessages').insert({
        'clanId': clanId,
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending clan message: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getClanMessages(String clanId) {
    try {
      return _client
          .from('clanMessages')
          .stream(primaryKey: ['id'])
          .eq('clanId', clanId)
          .order('timestamp', ascending: false)
          .map((rows) {
            return rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
          })
          .handleError((e) {debugPrint('Error getting clan messages: $e');});
    } catch (e) {
      debugPrint('Error setting up clan messages stream: $e');
      rethrow;
    }
  }

  Future<String> createClanEvent({
    required String clanId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client.from('clanEvents').insert({
        'clanId': clanId,
        'title': title,
        'description': description,
        'eventDate': eventDate.toUtc().toIso8601String(),
        'location': location,
        'createdBy': currentUserId,
        'attendees': [currentUserId],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (response is Map<String, dynamic>) {
        return response['id']?.toString() ?? '';
      }
      throw Exception('Unable to create clan event');
    } catch (e) {
      debugPrint('Error creating clan event: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getClanEvents(String clanId) {
    try {
      return _client
          .from('clanEvents')
          .stream(primaryKey: ['id'])
          .eq('clanId', clanId)
          .order('eventDate', ascending: true)
          .map((rows) {
            return rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
          })
          .handleError((e) {debugPrint('Error getting clan events: $e');});
    } catch (e) {
      debugPrint('Error setting up clan events stream: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getClanJoinRequests(String clanId) {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('clanJoinRequests')
            .select()
            .eq('clanId', clanId)
            .eq('status', 'pending');

        if (response is! List) return <Map<String, dynamic>>[];
        return (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
      }()).handleError((e) {debugPrint('Error getting clan join requests: $e');});
    } catch (e) {
      debugPrint('Error setting up clan join requests stream: $e');
      rethrow;
    }
  }
}
