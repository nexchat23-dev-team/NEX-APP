import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
  bool _startupComplete = false;
  bool _showCursor = true;
  Timer? _cursorTimer;
  Timer? _shootingStarTimer;
  bool _showShootingStar = false;
  double _shootingStartX = 0;
  double _shootingStartY = 0;
  double _shootingEndX = 0;
  double _shootingEndY = 0;
  Color _shootingStarColor = Colors.white;
  Color _shootingFromColor = Colors.white;
  Color _shootingToColor = Colors.white;

  // Professional System Manifest
  final List<String> _startupLines = [
    'BOOT_SEQUENCE: INITIALIZING NEX_CORE...',
    'KERNEL: SPAWNING REALTIME ENGINE [0x42AF]...',
    'NET_LAYER: SECURE CHANNELS OPENED...',
    'MODULES: SYNCING AI & NEX_CHAT LIBRARIES...',
    'QUEUE: LOADING WORK_THREAD_01...',
    'SYSTEM_READY: ENCRYPTION ACTIVE. TYPE "HELP".',
  ];

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
    _scheduleShootingStar();
    _playStartupSequence();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _shootingStarTimer?.cancel();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleShootingStar() {
    _shootingStarTimer?.cancel();
    _shootingStarTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _launchShootingStar();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _launchShootingStar();
    });
  }

  void _launchShootingStar() {
    final size = MediaQuery.of(context).size;
    final startX = Random().nextDouble() * size.width * 0.7;
    final startY = Random().nextDouble() * size.height * 0.16;
    final endX = startX + size.width * 0.35;
    final endY = startY + size.height * 0.12;
    final palette = [Colors.white, const Color(0xFF7DDCFF), const Color(0xFFB23BFF), const Color(0xFFFFD166)];

    setState(() {
      _shootingStartX = startX;
      _shootingStartY = startY;
      _shootingEndX = endX;
      _shootingEndY = endY;
      _shootingFromColor = palette[Random().nextInt(palette.length)];
      _shootingToColor = palette[Random().nextInt(palette.length)];
      _shootingStarColor = _shootingFromColor;
      _showShootingStar = true;
    });
  }

  void _addOutput(String type, String message) {
    if (!mounted) return;
    setState(() {
      _output.add({
        'type': type,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _playStartupSequence() async {
    _addOutput('welcome', '>>> NEX_TERMINAL_OS [v1.0.42] <<<');
    for (final line in _startupLines) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _addOutput('live', line);
    }
    setState(() => _startupComplete = true);
  }

  Future<void> _runCrazyWorkSequence() async {
    final commands = [
      'COMPUTE: DISPATCHING HEURISTIC TASKS...',
      'STREAM: LOGS AGGREGATED FROM NODE_42...',
      'CRYPT: ROTATING PAYLOAD KEYS...',
      'TUNNEL: REACTIVE_PIPELINE_STABLE...',
      'AI_CORE: INFERENCE ENGINE FIRING...',
      'DONE: SESSION LOGGED. TERMINAL REMAINS LIVE.',
    ];

    for (final line in commands) {
      if (!mounted) return;
      _addOutput('live', line);
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  void _executeCommand(String command) {
    final cmd = command.trim().toLowerCase();
    if (cmd.isEmpty) return;

    if (!_startupComplete) {
      _addOutput('warning', 'SYS_BUSY: BOOT_SEQUENCE_IN_PROGRESS');
      return;
    }

    _addOutput('command', '\$ $command');
    final parts = cmd.split(' ');
    final mainCmd = parts[0];

    switch (mainCmd) {
      case 'help':
        _addOutput('info', '''
SYSTEM ACCESS COMMANDS:
  help          - Display system manifest
  clear         - Wipe terminal buffer
  status        - Diagnostics check
  balance       - Token ledger query
  whoami        - Identity verification
  apps          - List active NEX modules
  goto <screen> - Inter-module navigation
  work          - Execute compute simulation
  syslog        - Raw system log dump
  logout        - Terminate session
''');
        break;

      case 'clear':
        setState(() => _output.clear());
        _addOutput('info', 'BUFFER_WIPED');
        break;

      case 'work':
        _addOutput('info', 'INITIATING WORKFLOW_ALPHA...');
        _runCrazyWorkSequence();
        break;

      case 'syslog':
        _addOutput('info', 'RAW_LOG_DUMP:');
        _addOutput('live', '[${DateTime.now().hour}:17] netflow connected.');
        _addOutput(
            'live', '[${DateTime.now().hour}:32] AI_kernel synchronized.');
        _addOutput('live', '[${DateTime.now().hour}:01] handshake complete.');
        break;

      case 'status':
        _addOutput('success', 'NEX_DIAGNOSTICS:');
        _addOutput('info', '  • SUPABASE: READY');
        _addOutput('info', '  • AUTH_PROTOCOL: ACTIVE');
        _addOutput('info', '  • DB_SYNC: ONLINE');
        _addOutput('info', '  • TOKENS: VALIDATED');
        break;

      case 'balance':
        _addOutput('success', 'LEDGER_QUERY: 1,250.42 NEX');
        break;

      case 'whoami':
        _addOutput('info', 'IDENTITY: active_user');
        _addOutput('info', 'ACCESS_LVL: STANDARD');
        break;

      case 'apps':
        _addOutput('info', 'ACTIVE_MODULES:');
        _addOutput('info', '  - home, chat, group, calls, bet');
        _addOutput('info', '  - market, profile, ai, terminal');
        _addOutput('info', 'USE: GOTO <MODULE_ID>');
        break;

      case 'goto':
        if (parts.length > 1) {
          final screen = parts[1];
          _addOutput('info', 'DIVERTING_TRAFFIC TO: $screen...');
          _navigateToScreen(screen);
        } else {
          _addOutput('error', 'ERR: MISSING_MODULE_ID');
        }
        break;

      case 'logout':
        _addOutput('warning', 'SESSION_TERMINATED.');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        break;

      default:
        _addOutput('error', 'SYNTAX_ERR: UNKNOWN_CMD "$mainCmd"');
    }
  }

  void _navigateToScreen(String screen) {
    final routes = {
      'home': '/home',
      'chat': '/chat',
      'group': '/group',
      'calls': '/calls',
      'bet': '/betting',
      'market': '/marketplace',
      'profile': '/profile',
      'settings': '/settings',
      'ai': '/ai-chat',
      'terminal': '/terminal',
    };

    final route = routes[screen];
    if (route != null) {
      if (!mounted) return;
      Navigator.pushNamed(context, route);
    } else {
      _addOutput('error', 'ERR: MODULE_NOT_FOUND "$screen"');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'command':
        return kNeonBlue;
      case 'success':
        return kNeonGreen; // Distinct success color
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.amber;
      case 'live':
        return Colors.lightGreenAccent.withValues(alpha: 0.7);
      case 'info':
        return kNeonBlue.withValues(alpha: 0.8);
      case 'welcome':
        return kNeonBlue;
      default:
        return Colors.white60;
    }
  }

  Widget _buildShootingStarOverlay() {
    if (!_showShootingStar) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final x = _shootingStartX + (_shootingEndX - _shootingStartX) * value;
        final y = _shootingStartY + (_shootingEndY - _shootingStartY) * value;
        final opacity = (1 - value).clamp(0.0, 1.0).toDouble();

        final currentColor = Color.lerp(_shootingFromColor, _shootingToColor, value) ?? _shootingStarColor;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 140,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      currentColor.withValues(alpha: 0.95),
                      _shootingToColor.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () => setState(() => _showShootingStar = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A111F),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kNeonBlue, Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: kNeonBlue.withValues(alpha: 0.3), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.terminal_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            const Text('NEX_TERMINAL',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1)),
          ],
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: kNeonBlue, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_clear_rounded,
                color: kNeonBlue, size: 20),
            onPressed: () {
              setState(() => _output.clear());
              _addOutput('info', 'BUFFER_CLEARED');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // PRO TERMINAL OUTPUT AREA
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF070B14),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  final item = _output[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      item['message'] as String,
                      style: TextStyle(
                        color: _getTypeColor(item['type'] as String),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // INPUT INTERFACE
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A111F),
              border: Border(
                  top: BorderSide(color: kNeonBlue.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const Text('\$ ',
                      style: TextStyle(
                          color: kNeonBlue,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900)),
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      enabled: _startupComplete,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14),
                      cursorColor: kNeonBlue,
                      decoration: InputDecoration(
                        hintText: _startupComplete
                            ? 'Awaiting command...'
                            : 'SYS_BOOTING...',
                        hintStyle: const TextStyle(color: Colors.white12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        _executeCommand(value);
                        _commandController.clear();
                      },
                    ),
                  ),
                  // Blinking Cursor Simulation
                  if (_startupComplete)
                    Opacity(
                      opacity: _showCursor ? 1.0 : 0.0,
                      child: Container(
                          width: 8,
                          height: 18,
                          color: kNeonBlue.withValues(alpha: 0.8)),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      _executeCommand(_commandController.text);
                      _commandController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kNeonBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.subdirectory_arrow_left_rounded,
                          color: kNeonBlue, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildShootingStarOverlay(),
        ],
      ),
    );
  }
}

class _TerminalSpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.4),
        radius: 1.15,
        colors: [Color(0xFF1E3560), Color(0xFF060810)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.9, 0.1),
        radius: 0.75,
        colors: [Color(0xFF6D43FF), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.12), size.width * 0.23, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
