import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/session_service.dart';

class GamingTerminalScreen extends StatefulWidget {
  static const routeName = '/gaming-terminal';

  const GamingTerminalScreen({super.key});

  @override
  State<GamingTerminalScreen> createState() => _GamingTerminalScreenState();
}

class _GamingTerminalScreenState extends State<GamingTerminalScreen> {
  final SessionService _sessionService = SessionService();
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _terminalOutput = [];
  final String _currentDirectory = '/home/nex-user';
  String _currentGameId = '';
  String _activeGameName = '';
  bool _isInSession = false;
  bool _isBusy = false;
  final List<Map<String, String>> _commandShortcuts = [
    {'label': 'Help', 'command': 'help'},
    {'label': 'Create', 'command': 'cs <game>'},
    {'label': 'List', 'command': 'ls'},
    {'label': 'Info', 'command': 'si'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  void _initializeTerminal() {
    _terminalOutput.add('NEX-APP Gaming Terminal v2.0.1');
    _terminalOutput.add('Type "help" for available commands');
    _terminalOutput.add('');
    _terminalOutput.add(r'nex-user@nex-app:~$ ');
    setState(() {});
  }

  Future<void> _executeCommand(String command) async {
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty) {
      _addOutput('nex-user@nex-app:$_currentDirectory\$ ');
      return;
    }

    setState(() {
      _terminalOutput.add('nex-user@nex-app:$_currentDirectory\$ $command');
      _isBusy = true;
    });

    final parts = trimmedCommand.toLowerCase().split(' ');
    final cmd = parts[0];
    final args = parts.length > 1 ? parts.sublist(1).cast<String>() : <String>[];

    try {
      switch (cmd) {
        case 'help':
          _showHelp();
          break;
        case 'create-session':
        case 'cs':
          await _createGamingSession(args);
          break;
        case 'join-session':
        case 'js':
          await _joinGamingSession(args);
          break;
        case 'list-sessions':
        case 'ls':
          await _listGamingSessions();
          break;
        case 'leave-session':
          _leaveGamingSession();
          break;
        case 'session-info':
        case 'si':
          _showSessionInfo();
          break;
        case 'invite':
          _inviteToSession(args);
          break;
        case 'clear':
          setState(() {
            _terminalOutput.clear();
          });
          break;
        case 'exit':
          Navigator.pop(context);
          return;
        default:
          _addOutput('Command not found: $cmd');
          _addOutput('Type "help" for available commands');
      }
    } finally {
      setState(() {
        _isBusy = false;
      });
    }

    _addOutput('');
    _addOutput('nex-user@nex-app:$_currentDirectory\$ ');
  }

  void _showHelp() {
    _addOutput('Available commands:');
    _addOutput('  help                    - Show this help message');
    _addOutput('  create-session <game>   - Create a new gaming session');
    _addOutput('  cs <game>              - Alias for create-session');
    _addOutput('  join-session <id>       - Join an existing session');
    _addOutput('  js <id>                - Alias for join-session');
    _addOutput('  list-sessions          - List available sessions');
    _addOutput('  ls                     - Alias for list-sessions');
    _addOutput('  leave-session          - Leave current session');
    _addOutput('  session-info           - Show current session info');
    _addOutput('  si                     - Alias for session-info');
    _addOutput('  invite <user>          - Invite user to current session');
    _addOutput('  clear                  - Clear terminal output');
    _addOutput('  exit                   - Exit terminal');
    _addOutput('');
    _addOutput('Gaming session format: NEXCHAT;gameid session;session_id;tme.nex-app');
  }

  Future<void> _createGamingSession(List<String> args) async {
    if (args.isEmpty) {
      _addOutput('Usage: create-session <game_name>');
      return;
    }

    final gameName = args.join(' ');
    _addOutput('Creating gaming session for: $gameName');

    try {
      final sessionId = await _sessionService.createSession(
        title: '$gameName session',
        startTime: DateTime.now().add(const Duration(minutes: 5)),
        game: gameName,
        maxParticipants: 12,
        isPublic: true,
      );

      _currentGameId = sessionId;
      _activeGameName = gameName;
      _isInSession = true;

      _addOutput('Session created successfully!');
      _addOutput('Session ID: $sessionId');
      _addOutput('Share code: NEXCHAT;${gameName.replaceAll(' ', '_')};$sessionId;tme.nex-app');
      _addOutput('Players can join using: join-session $sessionId');
    } catch (e) {
      _addOutput('Error creating session: $e');
    }
  }

  Future<void> _joinGamingSession(List<String> args) async {
    if (args.isEmpty) {
      _addOutput('Usage: join-session <session_id>');
      return;
    }

    final sessionId = args[0];
    _addOutput('Joining session: $sessionId');

    try {
      await _sessionService.joinSession(sessionId);
      _currentGameId = sessionId;
      _isInSession = true;

      _addOutput('Successfully joined session!');
      _addOutput('Use "session-info" to view details');

    } catch (e) {
      _addOutput('Error joining session: $e');
    }
  }

  Future<void> _listGamingSessions() async {
    _addOutput('Fetching available gaming sessions...');

    try {
      final sessions = await _sessionService.fetchPublicSessions();
      if (sessions.isEmpty) {
        _addOutput('No active sessions found.');
        _addOutput('Create one with: create-session <game_name>');
        return;
      }

      _addOutput('Available sessions:');
      for (final session in sessions) {
        final status = session['status'] as String;
        final players = (session['participants'] as List<dynamic>).cast<String>();
        final maxParticipants = session['maxParticipants'] as int;
        final startTime = session['startTime'];
        final startLabel = startTime is Timestamp
            ? (startTime.toDate().toLocal().toString().substring(11, 16))
            : 'TBA';

        _addOutput('  - [${status.toUpperCase()}] ${session['title']}');
        _addOutput('      Game: ${session['game']} • Players: ${players.length}/$maxParticipants • Starts: $startLabel');
        _addOutput('      Join: join-session ${session['id']}');
      }
    } catch (e) {
      _addOutput('Error listing sessions: $e');
    }
  }

  void _leaveGamingSession() {
    if (!_isInSession) {
      _addOutput('You are not in any session');
      return;
    }

    _isInSession = false;
    _currentGameId = '';
    _addOutput('Left gaming session');
  }

  void _showSessionInfo() {
    if (!_isInSession) {
      _addOutput('You are not in any session');
      _addOutput('Use "create-session" or "join-session" to join one');
      return;
    }

    _addOutput('Current Session Info:');
    _addOutput('  Session ID: $_currentGameId');
    _addOutput('  Status: Active');
    _addOutput('  Share Code: NEXCHAT;game_session;$_currentGameId;tme.nex-app');
  }

  void _inviteToSession(List<String> args) {
    if (!_isInSession) {
      _addOutput('You must be in a session to invite others');
      return;
    }

    if (args.isEmpty) {
      _addOutput('Usage: invite <username>');
      return;
    }

    final username = args.join(' ');
    _addOutput('Invitation sent to: $username');
    _addOutput('Share code: NEXCHAT;game_session;$_currentGameId;tme.nex-app');
  }

  void _addOutput(String text) {
    setState(() {
      _terminalOutput.add(text);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121727),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kNeonGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.terminal, color: kNeonGreen, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'NEX Gaming Terminal',
              style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isInSession ? kNeonGreen.withOpacity(0.22) : Colors.red.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInSession ? kNeonGreen : Colors.red,
                width: 1,
              ),
            ),
            child: Text(
              _isInSession ? 'IN SESSION' : 'NO SESSION',
              style: TextStyle(
                color: _isInSession ? kNeonGreen : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF121727),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInSession ? 'Active session: $_activeGameName' : 'No active gaming session',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isInSession
                            ? 'Session ID: $_currentGameId • Ready to invite or share'
                            : 'Create a session with "cs <game>" or browse sessions with "ls"',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_isBusy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kNeonPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(kNeonPurple),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: const Color(0xFF10131B),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _commandShortcuts.map((shortcut) {
                return ActionChip(
                  label: Text(shortcut['label']!, style: const TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFF181B24),
                  avatar: const Icon(Icons.chevron_right, color: kNeonGreen, size: 18),
                  onPressed: () {
                    _commandController.text = shortcut['command']!;
                    _commandController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _commandController.text.length),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF090B12),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _terminalOutput.length,
                itemBuilder: (context, index) {
                  final line = _terminalOutput[index];

                  final isCommand = line.startsWith('nex-user@nex-app:');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: isCommand ? kNeonGreen : Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121727),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (command) async {
                      await _executeCommand(command);
                      _commandController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNeonPurple.withOpacity(0.9), kNeonGreen.withOpacity(0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: _isBusy
                        ? null
                        : () async {
                            if (_commandController.text.isNotEmpty) {
                              await _executeCommand(_commandController.text);
                              _commandController.clear();
                            }
                          },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
