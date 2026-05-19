import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/call_service.dart';

class CallsScreen extends StatefulWidget {
  static const routeName = '/calls';
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final CallService _callService = CallService();

  // FIX: Helper for the Call UI Buttons
  Widget _buildCallAction(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }

  void _startCall(BuildContext context, String recipientId, String recipientName, bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CallScreen(callerName: recipientName, isVideo: isVideo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A111F),
        title: const Text(
          'COMMUNICATIONS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, color: kNeonBlue)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded, color: kNeonBlue)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _callService.getCallHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('COMM LINK ERROR', style: TextStyle(color: Colors.redAccent)));
          }

          final calls = snapshot.data?.docs ?? [];
          if (calls.isEmpty) return _buildEmptyCalls(context);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final callData = calls[index].data() as Map<String, dynamic>;
              final callerId = callData['callerId'] as String?;
              final recipientId = callData['recipientId'] as String?;
              final isMissed = callData['status'] == 'missed';
              final createdAt = callData['createdAt'] as Timestamp?;

              return FutureBuilder<Map<String, String>>(
                future: _getCallerInfo(callerId == _callService.currentUserId ? recipientId : callerId),
                builder: (context, userSnapshot) {
                  final callerName = userSnapshot.data?['name'] ?? 'Loading...';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMissed ? Colors.red : kNeonGreen,
                        child: Text(callerName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(callerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(createdAt != null ? _formatCallTime(createdAt.toDate()) : 'Now', style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCallAction(Icons.call, kNeonGreen, () => _startCall(context, recipientId ?? '', callerName, false)),
                          const SizedBox(width: 8),
                          _buildCallAction(Icons.videocam, kNeonBlue, () => _startCall(context, recipientId ?? '', callerName, true)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeonGreen,
        onPressed: () => _showNewCallDialog(context),
        child: const Icon(Icons.add_ic_call_rounded, color: Colors.black),
      ),
    );
  }

  // --- Helper Methods inside _CallsScreenState ---

  Widget _buildEmptyCalls(BuildContext context) {
    return const Center(child: Text('No calls logged.', style: TextStyle(color: Colors.white54)));
  }

  void _showNewCallDialog(BuildContext context) {
    // [Dialog logic remains same but ensuring it's a method, not a class]
  }

  String _formatCallTime(DateTime date) {
    return "${date.hour}:${date.minute}";
  }

  Future<Map<String, String>> _getCallerInfo(String? userId) async {
    if (userId == null) return {'name': 'Unknown'};
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return {'name': doc.data()?['name'] ?? 'User'};
  }
} // <--- THIS BRACE CLOSES _CallsScreenState

// --- SEPARATE CLASS (Outside _CallsScreenState) ---

class _CallScreen extends StatefulWidget {
  final String callerName;
  final bool isVideo;

  const _CallScreen({required this.callerName, required this.isVideo});

  @override
  State<_CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<_CallScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF070B14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 40),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}

