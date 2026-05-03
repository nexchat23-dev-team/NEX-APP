import 'package:flutter/material.dart';
import '../main.dart';

class TerminalScreen extends StatefulWidget {
  static const routeName = '/terminal';
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final List<Map<String, dynamic>> _output = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addOutput('welcome', 'NEX TERMINAL v1.0.0');
    _addOutput('info', 'Type "help" for available commands.');
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addOutput(String type, String message) {
    setState(() {
      _output.add({
        'type': type,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeCommand(String command) {
    final cmd = command.trim().toLowerCase();
    
    if (cmd.isEmpty) return;

    // Add command to output
    _addOutput('command', '\$ $command');

    final parts = cmd.split(' ');
    final mainCmd = parts[0];

    switch (mainCmd) {
      case 'help':
        _addOutput('info', '''
Available commands:
  help          - Show this help message
  clear         - Clear terminal
  status        - Show app status
  balance       - Show token balance
  version       - Show app version
  whoami        - Show current user
  date          - Show current date/time
  echo <text>   - Echo text back
  apps          - List available screens
  goto <screen> - Navigate to screen
  logout        - Logout from app
''');
        break;
        
      case 'clear':
        setState(() {
          _output.clear();
        });
        _addOutput('info', 'Terminal cleared.');
        break;
        
      case 'status':
        _addOutput('success', 'NEX-APP Status:');
        _addOutput('info', '  • Firebase: Connected');
        _addOutput('info', '  • Auth: Active');
        _addOutput('info', '  • Database: Online');
        _addOutput('info', '  • Tokens: Available');
        break;
        
      case 'balance':
        _addOutput('success', 'Token Balance: 1,250 NEX');
        break;
        
      case 'version':
        _addOutput('info', 'NEX-APP v1.0.0');
        _addOutput('info', 'NEXCHAT Framework');
        _addOutput('info', 'Build: 2024.1');
        break;
        
      case 'whoami':
        _addOutput('info', 'Current User: demo@nexchat.com');
        _addOutput('info', 'User ID: user_123456');
        _addOutput('info', 'Role: Premium Member');
        break;
        
      case 'date':
        _addOutput('info', 'Current Date: ${DateTime.now().toString().split('.')[0]}');
        break;
        
      case 'echo':
        if (parts.length > 1) {
          _addOutput('info', command.substring(5));
        } else {
          _addOutput('error', 'Usage: echo <text>');
        }
        break;
        
      case 'apps':
        _addOutput('info', 'Available screens:');
        _addOutput('info', '  • home (Home Screen)');
        _addOutput('info', '  • chat (Chat Screen)');
        _addOutput('info', '  • group (Group Chat)');
        _addOutput('info', '  • calls (Calls Screen)');
        _addOutput('info', '  • bet (Bet/Games)');
        _addOutput('info', '  • market (Marketplace)');
        _addOutput('info', '  • profile (Profile)');
        _addOutput('info', '  • settings (Settings)');
        _addOutput('info', '  • ai (AI Chat)');
        _addOutput('info', 'Use: goto <screen>');
        break;
        
      case 'goto':
        if (parts.length > 1) {
          final screen = parts[1];
          _addOutput('info', 'Navigating to $screen...');
          _navigateToScreen(screen);
        } else {
          _addOutput('error', 'Usage: goto <screen>');
          _addOutput('info', 'Type "apps" to see available screens.');
        }
        break;
        
      case 'logout':
        _addOutput('warning', 'Logging out...');
        Navigator.pushReplacementNamed(context, '/login');
        break;
        
      default:
        _addOutput('error', 'Command not found: $mainCmd');
        _addOutput('info', 'Type "help" for available commands.');
    }
  }

  void _navigateToScreen(String screen) {
    final routes = {
      'home': '/home',
      'chat': '/chat',
      'group': '/group',
      'calls': '/calls',
      'bet': '/bet',
      'market': '/marketplace',
      'profile': '/profile',
      'settings': '/settings',
      'ai': '/ai-chat',
      'terminal': '/terminal',
    };
    
    final route = routes[screen];
    if (route != null) {
      Navigator.pushNamed(context, route);
    } else {
      _addOutput('error', 'Screen not found: $screen');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'command':
        return kNeonBlue; // Changed to neon blue
      case 'success':
        return kNeonBlue;
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange;
      case 'info':
        return kNeonBlue;
      case 'welcome':
        return kNeonBlue;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1E36), // Blue-tinted app bar
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kNeonBlue, kNeonBlue.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kNeonBlue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.terminal, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Terminal', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: kNeonBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kNeonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: kNeonBlue),
              onPressed: () {
                setState(() {
                  _output.clear();
                });
                _addOutput('info', 'Terminal cleared.');
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Terminal output
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF0D1E36),
                  ],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  final item = _output[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item['message'] as String,
                      style: TextStyle(
                        color: _getTypeColor(item['type'] as String),
                        fontSize: 13,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1E36),
              border: Border(
                top: BorderSide(color: kNeonBlue.withValues(alpha: 0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: kNeonBlue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const Text(
                    '\$ ',
                    style: TextStyle(
                      color: kNeonBlue,
                      fontSize: 16,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter command...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        _executeCommand(value);
                        _commandController.clear();
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kNeonBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: kNeonBlue),
                      onPressed: () {
                        _executeCommand(_commandController.text);
                        _commandController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
