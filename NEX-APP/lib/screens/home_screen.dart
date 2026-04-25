import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1410),
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF25D366),
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('NEXCHAT'),
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Status'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChats(context),
            _buildStatus(context),
            _buildCalls(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.chat, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, ChatScreen.routeName),
        ),
      ),
    );
  }

  Widget _buildChats(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {'name': 'Alex', 'message': 'Do you have the new token update?', 'time': '13:45', 'unread': 2},
      {'name': 'NEX Group', 'message': 'New event launching tomorrow!', 'time': '12:30', 'unread': 5},
      {'name': 'Sam', 'message': 'Check the new marketplace pack.', 'time': '08:15', 'unread': 0},
      {'name': 'Support', 'message': 'Your token balance was updated.', 'time': 'Yesterday', 'unread': 1},
    ];
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF25D366).withOpacity(0.20),
            child: Text(chat['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(chat['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(chat['message'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(chat['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              if ((chat['unread'] as int) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(color: Color(0xFF25D366), borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: Text('${chat['unread']}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          onTap: () => Navigator.pushNamed(context, ChatScreen.routeName),
        );
      },
    );
  }

  Widget _buildStatus(BuildContext context) {
    final List<Map<String, dynamic>> statuses = [
      {'name': 'My status', 'subtitle': 'Tap to add status update', 'time': 'Today, 09:00'},
      {'name': 'NEX Community', 'subtitle': '3 new updates', 'time': 'Yesterday'},
      {'name': 'Anna', 'subtitle': '2 new updates', 'time': 'Today, 10:24'},
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: statuses.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
      itemBuilder: (context, index) {
        final status = statuses[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF25D366).withOpacity(0.22),
            child: Text(status['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(status['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(status['subtitle'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          trailing: Text(status['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildCalls(BuildContext context) {
    final List<Map<String, dynamic>> calls = [
      {'name': 'Alex', 'subtitle': 'Incoming', 'time': 'Today, 08:20', 'icon': Icons.call_received},
      {'name': 'NEX Support', 'subtitle': 'Outgoing', 'time': 'Yesterday', 'icon': Icons.call_made},
      {'name': 'Sam', 'subtitle': 'Missed', 'time': 'Monday', 'icon': Icons.call_missed},
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: calls.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
      itemBuilder: (context, index) {
        final call = calls[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF25D366).withOpacity(0.20),
            child: Text(call['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(call['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(call['subtitle'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          trailing: Icon(call['icon'] as IconData, color: const Color(0xFF25D366)),
          onTap: () {},
        );
      },
    );
  }
}
