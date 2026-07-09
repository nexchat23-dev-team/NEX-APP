import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StatusService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // Post a new status
  Future<String> postStatus({
    required String text,
    String? mediaUrl,
    String mediaType = 'text', // text, image, video
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final expiresAt = DateTime.now().add(expiresIn).toUtc().toIso8601String();
      final createdAt = DateTime.now().toUtc().toIso8601String();

      final response = await _client.from('statuses').insert({
        'userId': currentUserId,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'expiresAt': expiresAt,
        'createdAt': createdAt,
        'views': 0,
        'isActive': true,
      }).select();

      if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
        return response.first['id'].toString();
      }

      throw Exception('Unable to post status');
    } catch (e) {
      debugPrint('Error posting status: $e');
      rethrow;
    }
  }

  // Get all active statuses
  Stream<List<Map<String, dynamic>>> getStatuses() {
    try {
      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final now = DateTime.now().toUtc().toIso8601String();
        final response = await _client
            .from('statuses')
            .select()
            .eq('isActive', true)
            .gt('expiresAt', now);

        if (response is! List) return <Map<String, dynamic>>[];

        final statuses = (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
        statuses.sort((a, b) {
          final aTime = a['createdAt']?.toString() ?? '';
          final bTime = b['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });
        return statuses;
      }()).handleError((e) {
        debugPrint('Error getting statuses: $e');
      });
    } catch (e) {
      debugPrint('Error setting up statuses stream: $e');
      rethrow;
    }
  }

  // Get user's own statuses
  Stream<List<Map<String, dynamic>>> getUserStatuses() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      return Stream<List<Map<String, dynamic>>>.fromFuture(() async {
        final response = await _client
            .from('statuses')
            .select()
            .eq('userId', currentUserId.toString())
            .eq('isActive', true);

        if (response is! List) return <Map<String, dynamic>>[];

        final statuses = (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
            .toList();
        statuses.sort((a, b) {
          final aTime = a['createdAt']?.toString() ?? '';
          final bTime = b['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });
        return statuses;
      }()).handleError((e) {
        debugPrint('Error getting user statuses: $e');
      });
    } catch (e) {
      debugPrint('Error setting up user statuses stream: $e');
      rethrow;
    }
  }

  // View a status (increment view count)
  Future<void> viewStatus(String statusId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final status = await _client.from('statuses').select().eq('id', statusId).single();
      if (status != null && status is Map<String, dynamic>) {
        final currentViews = status['views'] as int? ?? 0;
        await _client.from('statuses').update({
          'views': currentViews + 1,
        }).eq('id', statusId);
      }

      await _client.from('statusViews').insert({
        'statusId': statusId,
        'userId': currentUserId,
        'viewedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error viewing status: $e');
      rethrow;
    }
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final status = await _client.from('statuses').select().eq('id', statusId).single();
      if (status == null) throw Exception('Status not found');
      if ((status['userId']?.toString() ?? '') != currentUserId) {
        throw Exception('Not authorized');
      }

      await _client.from('statuses').update({'isActive': false}).eq('id', statusId);
    } catch (e) {
      debugPrint('Error deleting status: $e');
      rethrow;
    }
  }

  // Get status viewers
  Stream<List<Map<String, dynamic>>> getStatusViewers(String statusId) {
    try {
      return _client
          .from('statusViews')
          .stream(primaryKey: ['id'])
          .eq('statusId', statusId)
          .map((rows) {
            final viewers = rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
            viewers.sort((a, b) {
              final aTime = a['viewedAt']?.toString() ?? '';
              final bTime = b['viewedAt']?.toString() ?? '';
              return bTime.compareTo(aTime);
            });
            return viewers;
          })
          .handleError((e) {
            debugPrint('Error getting status viewers: $e');
          });
    } catch (e) {
      debugPrint('Error setting up status viewers stream: $e');
      rethrow;
    }
  }

  // React to a status
  Future<void> reactToStatus(String statusId, String reaction) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('statusReactions').insert({
        'statusId': statusId,
        'userId': currentUserId,
        'reaction': reaction,
        'reactedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error reacting to status: $e');
      rethrow;
    }
  }

  // Get user's own statuses (alias for getUserStatuses for clarity)
  Stream<List<Map<String, dynamic>>> getMyStatuses() {
    return getUserStatuses();
  }

  // Update a status
  Future<void> updateStatus(
    String statusId, {
    String? text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final status = await _client.from('statuses').select().eq('id', statusId).single();
      if (status == null) throw Exception('Status not found');
      if ((status['userId']?.toString() ?? '') != currentUserId) {
        throw Exception('Not authorized');
      }

      final updates = <String, dynamic>{};
      if (text != null) updates['text'] = text;
      if (mediaUrl != null) updates['mediaUrl'] = mediaUrl;
      if (mediaType != null) updates['mediaType'] = mediaType;
      updates['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      await _client.from('statuses').update(updates).eq('id', statusId);
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  // Get reactions for a status
  Stream<List<Map<String, dynamic>>> getStatusReactions(String statusId) {
    try {
      return _client
          .from('statusReactions')
          .stream(primaryKey: ['id'])
          .eq('statusId', statusId)
          .map((rows) {
            final reactions = rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
            reactions.sort((a, b) {
              final aTime = a['reactedAt']?.toString() ?? '';
              final bTime = b['reactedAt']?.toString() ?? '';
              return bTime.compareTo(aTime);
            });
            return reactions;
          })
          .handleError((e) {
            debugPrint('Error getting status reactions: $e');
          });
    } catch (e) {
      debugPrint('Error setting up status reactions stream: $e');
      return const Stream.empty();
    }
  }
}
