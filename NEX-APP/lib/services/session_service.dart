import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SessionService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> createSession({
    required String title,
    required DateTime startTime,
    String? description,
    String? game,
    String? gameMode,
    int maxParticipants = 10,
    bool isPublic = true,
    String? squadId,
    String? clanId,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client.from('sessions').insert({
        'title': title,
        'description': description,
        'game': game,
        'gameMode': gameMode,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': null,
        'creatorId': currentUserId,
        'participants': [currentUserId],
        'maxParticipants': maxParticipants,
        'isPublic': isPublic,
        'status': 'scheduled',
        'squadId': squadId,
        'clanId': clanId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (response is Map<String, dynamic>) {
        return response['id']?.toString() ?? '';
      }
      throw Exception('Unable to create session');
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }

  Future<void> joinSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final participants = List<String>.from(session['participants'] ?? []);
      final maxParticipants = session['maxParticipants'] ?? 10;
      final status = session['status']?.toString() ?? 'scheduled';

      if (status != 'scheduled') {
        throw Exception('Session is not open for joining');
      }
      if (participants.contains(currentUserId)) {
        throw Exception('Already joined');
      }
      if (participants.length >= maxParticipants) {
        throw Exception('Session is full');
      }

      participants.add(currentUserId!);
      await _client.from('sessions').update({'participants': participants}).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error joining session: $e');
      rethrow;
    }
  }

  Future<void> leaveSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final participants = List<String>.from(session['participants'] ?? []);
      final creatorId = session['creatorId']?.toString();

      if (!participants.contains(currentUserId)) {
        throw Exception('Not a participant');
      }

      participants.remove(currentUserId);

      if (participants.isEmpty) {
        await _client.from('sessions').update({
          'participants': participants,
          'status': 'cancelled',
        }).eq('id', sessionId);
      } else {
        String newCreatorId = creatorId ?? participants.first;
        if (currentUserId == creatorId) {
          newCreatorId = participants.first;
        }
        await _client.from('sessions').update({'participants': participants, 'creatorId': newCreatorId}).eq('id', sessionId);
      }
    } catch (e) {
      debugPrint('Error leaving session: $e');
      rethrow;
    }
  }

  Future<void> startSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final creatorId = session['creatorId']?.toString();
      if (currentUserId != creatorId) {
        throw Exception('Only creator can start session');
      }

      await _client.from('sessions').update({
        'status': 'active',
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final creatorId = session['creatorId']?.toString();
      if (currentUserId != creatorId) {
        throw Exception('Only creator can end session');
      }

      await _client.from('sessions').update({
        'status': 'completed',
        'endedAt': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSessions({bool publicOnly = false}) {
    try {
      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = publicOnly
            ? await _client
                .from('sessions')
                .select()
                .eq('isPublic', true)
                .inFilter('status', ['scheduled', 'active'])
                .order('startTime', ascending: true)
            : await _client
                .from('sessions')
                .select()
                .inFilter('status', ['scheduled', 'active'])
                .order('startTime', ascending: true);

        if (response is! List) return <Map<String, dynamic>>[];

        return (response as List<dynamic>).map((row) {
          final data = Map<String, dynamic>.from(row as Map<String, dynamic>);
          return {
            'id': data['id']?.toString() ?? '',
            'title': data['title'] ?? 'Unknown Session',
            'game': data['game'] ?? 'Unknown Game',
            'status': data['status'] ?? 'scheduled',
            'participants': List<String>.from(data['participants'] ?? []),
            'maxParticipants': data['maxParticipants'] ?? 10,
            'startTime': data['startTime'],
            'isPublic': data['isPublic'] ?? true,
          };
        }).toList();
      }()).handleError((e) {debugPrint('Error getting sessions: $e');});
    } catch (e) {
      debugPrint('Error setting up sessions stream: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserSessions() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('sessions')
            .select()
            .contains('participants', [currentUserId!])
            .order('startTime', ascending: true);

        if (response is! List) return <Map<String, dynamic>>[];

        return (response as List<dynamic>).map((row) {
          final data = Map<String, dynamic>.from(row as Map<String, dynamic>);
          return {
            'id': data['id']?.toString() ?? '',
            'title': data['title'] ?? 'Unknown Session',
            'game': data['game'] ?? 'Unknown Game',
            'status': data['status'] ?? 'scheduled',
            'participants': List<String>.from(data['participants'] ?? []),
            'maxParticipants': data['maxParticipants'] ?? 10,
            'startTime': data['startTime'],
            'isPublic': data['isPublic'] ?? true,
          };
        }).toList();
      }()).handleError((e) {debugPrint('Error getting user sessions: $e');});
    } catch (e) {
      debugPrint('Error setting up user sessions stream: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublicSessions() async {
    try {
      final response = await _client
          .from('sessions')
          .select()
          .eq('isPublic', true)
          .inFilter('status', ['scheduled', 'active'])
          .order('startTime', ascending: true);

      return (response as List<dynamic>).map((row) {
        final data = Map<String, dynamic>.from(row as Map<String, dynamic>);
        return {
          'id': data['id']?.toString() ?? '',
          'title': data['title'] ?? 'Unknown Session',
          'game': data['game'] ?? 'Unknown Game',
          'status': data['status'] ?? 'scheduled',
          'participants': List<String>.from(data['participants'] ?? []),
          'maxParticipants': data['maxParticipants'] ?? 10,
          'startTime': data['startTime'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching public sessions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    try {
      final response = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (response == null) return null;
      final data = Map<String, dynamic>.from(response as Map<String, dynamic>);
      return {
        'id': data['id']?.toString() ?? '',
        'title': data['title'] ?? 'Unknown Session',
        'game': data['game'] ?? 'Unknown Game',
        'description': data['description'] ?? '',
        'status': data['status'] ?? 'scheduled',
        'participants': List<String>.from(data['participants'] ?? []),
        'maxParticipants': data['maxParticipants'] ?? 10,
        'isPublic': data['isPublic'] ?? true,
        'startTime': data['startTime'],
        'creatorId': data['creatorId'],
      };
    } catch (e) {
      debugPrint('Error getting session by ID: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchPublicSessions(String query) async {
    try {
      final searchQuery = query.toLowerCase().trim();
      final response = await _client
          .from('sessions')
          .select()
          .eq('isPublic', true)
          .inFilter('status', ['scheduled', 'active'])
          .order('startTime', ascending: true);

      final sessions = (response as List<dynamic>).map((row) {
        final data = Map<String, dynamic>.from(row as Map<String, dynamic>);
        return {
          'id': data['id']?.toString() ?? '',
          'title': data['title'] ?? 'Unknown Session',
          'game': data['game'] ?? 'Unknown Game',
          'status': data['status'] ?? 'scheduled',
          'participants': List<String>.from(data['participants'] ?? []),
          'maxParticipants': data['maxParticipants'] ?? 10,
          'startTime': data['startTime'],
        };
      }).where((session) {
        final title = (session['title'] as String).toLowerCase();
        final game = (session['game'] as String).toLowerCase();
        return title.contains(searchQuery) || game.contains(searchQuery);
      }).toList();

      return sessions;
    } catch (e) {
      debugPrint('Error searching public sessions: $e');
      rethrow;
    }
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _client.from('sessions').update(updates).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error updating session: $e');
      rethrow;
    }
  }

  Future<void> sendSessionMessage({
    required String sessionId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('sessionMessages').insert({
        'sessionId': sessionId,
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending session message: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSessionMessages(String sessionId) {
    try {
      return _client
          .from('sessionMessages')
          .stream(primaryKey: ['id'])
          .eq('sessionId', sessionId)
          .order('timestamp', ascending: false)
          .map((rows) {
            return rows.map((row) => Map<String, dynamic>.from(row)).toList();
          })
          .handleError((e) {debugPrint('Error getting session messages: $e');});
    } catch (e) {
      debugPrint('Error setting up session messages stream: $e');
      rethrow;
    }
  }

  Future<void> addParticipant(String sessionId, String userId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final participants = List<String>.from(session['participants'] ?? []);
      final maxParticipants = session['maxParticipants'] ?? 10;
      final creatorId = session['creatorId']?.toString();

      if (currentUserId != creatorId) {
        throw Exception('Only creator can add participants');
      }
      if (participants.contains(userId)) {
        throw Exception('User already a participant');
      }
      if (participants.length >= maxParticipants) {
        throw Exception('Session is full');
      }

      participants.add(userId);
      await _client.from('sessions').update({'participants': participants}).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error adding participant: $e');
      rethrow;
    }
  }

  Future<void> removeParticipant(String sessionId, String userId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final session = await _client.from('sessions').select().eq('id', sessionId).maybeSingle();
      if (session == null || session is! Map<String, dynamic>) {
        throw Exception('Session not found');
      }

      final participants = List<String>.from(session['participants'] ?? []);
      final creatorId = session['creatorId']?.toString();

      if (currentUserId != creatorId && currentUserId != userId) {
        throw Exception('Only creator or the participant can remove');
      }
      if (!participants.contains(userId)) {
        throw Exception('User is not a participant');
      }

      participants.remove(userId);
      if (participants.isEmpty) {
        await _client.from('sessions').update({
          'participants': participants,
          'status': 'cancelled',
        }).eq('id', sessionId);
      } else {
        await _client.from('sessions').update({'participants': participants}).eq('id', sessionId);
      }
    } catch (e) {
      debugPrint('Error removing participant: $e');
      rethrow;
    }
  }
}
