import 'package:flutter/material.dart';
import '../main.dart';

class CallsScreen extends StatefulWidget {
  static const routeName = '/calls';
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final List<Map<String, dynamic>> _calls = [
    {'name': 'Alex', 'time': 'Today, 2:30 PM', 'type': 'video', 'missed': false},
    {'name': 'NEX Group', 'time': 'Yesterday, 5:00 PM', 'type': 'video', 'missed': false},
    {'name': 'Sam', 'time': 'Yesterday, 12:15 PM', 'type': 'audio', 'missed': true},
    {'name': 'Support', 'time': 'Apr 25, 10:00 AM', 'type': 'audio', 'missed': false},
  ];

  void _startCall(BuildContext context, String name, bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CallScreen(callerName: name, isVideo: isVideo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text('Calls'),
        backgroundColor: kPrimaryBlue,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _calls.length,
        separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
        itemBuilder: (context, index) {
          final call = _calls[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: (call['missed'] as bool) ? Colors.red.withOpacity(0.2) : kNeonGreen.withOpacity(0.2),
              child: Icon(
                call['type'] == 'video' ? Icons.videocam : Icons.call,
                color: (call['missed'] as bool) ? Colors.red : kNeonGreen,
              ),
            ),
            title: Text(
              call['name'] as String,
              style: TextStyle(
                color: (call['missed'] as bool) ? Colors.red : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  (call['missed'] as bool) ? Icons.call_missed : Icons.call_received,
                  size: 14,
                  color: (call['missed'] as bool) ? Colors.red : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(call['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _startCall(context, call['name'] as String, false),
                  icon: const Icon(Icons.call, color: kNeonGreen),
                ),
                IconButton(
                  onPressed: () => _startCall(context, call['name'] as String, true),
                  icon: const Icon(Icons.videocam, color: kNeonBlue),
                ),
              ],
            ),
            onTap: () => _startCall(context, call['name'] as String, call['type'] == 'video'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeonGreen,
        onPressed: () => _showNewCallDialog(context),
        child: const Icon(Icons.add_call, color: Colors.black),
      ),
    );
  }

  void _showNewCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('New Call', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Enter number or name',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: kDarkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startCall(context, 'New Contact', true);
            },
            child: const Text('Call', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _CallScreen extends StatefulWidget {
  final String callerName;
  final bool isVideo;

  const _CallScreen({required this.callerName, required this.isVideo});

  @override
  State<_CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<_CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isVideoOn = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 40),
          CircleAvatar(
            radius: 60,
            backgroundColor: kNeonGreen.withOpacity(0.2),
            child: Text(
              widget.callerName[0],
              style: const TextStyle(color: kNeonGreen, fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Calling...', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCallButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: _isMuted ? 'Unmute' : 'Mute',
                isActive: _isMuted,
                onTap: () => setState(() => _isMuted = !_isMuted),
              ),
              _buildCallButton(
                icon: Icons.volume_up,
                label: 'Speaker',
                isActive: _isSpeaker,
                onTap: () => setState(() => _isSpeaker = !_isSpeaker),
              ),
              if (widget.isVideo)
                _buildCallButton(
                  icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                  label: 'Video',
                  isActive: _isVideoOn,
                  onTap: () => setState(() => _isVideoOn = !_isVideoOn),
                ),
              _buildCallButton(
                icon: Icons.call_end,
                label: 'End',
                isActive: true,
                isEnd: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isEnd = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEnd ? Colors.red : (isActive ? kNeonGreen : Colors.white24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isEnd ? Colors.white : (isActive ? Colors.black : Colors.white), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isEnd ? Colors.red : Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}