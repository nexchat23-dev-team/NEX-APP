import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_bluetooth_service.dart';
import '../utils/constants.dart';

class OfflineChatScreen extends StatefulWidget {
  static const routeName = '/offline-chat';

  const OfflineChatScreen({super.key});

  @override
  State<OfflineChatScreen> createState() => _OfflineChatScreenState();
}

class _OfflineChatScreenState extends State<OfflineChatScreen> {
  final OfflineBluetoothService _bluetoothService = OfflineBluetoothService();
  final TextEditingController _messageController = TextEditingController();
  final List<OfflineMessage> _messages = [];
  bool _discovering = false;
  bool _connected = false;
  bool _advertising = false;
  bool _permissionsGranted = false;
  bool _showOnboardingBanner = false;
  double _transferProgress = 0.0;
  String _transferLabel = '';
  int _nearbyDeviceCount = 0;
  Endpoint? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _bluetoothService.endpointsStream.listen((devices) {
      if (!mounted) return;
      setState(() {
        _nearbyDeviceCount = devices.length;
      });
    });
    _bluetoothService.messageStream.listen((message) {
      setState(() {
        _messages.insert(0, message);
      });
    });
    _bluetoothService.isConnectedStream.listen((connected) {
      setState(() {
        _connected = connected;
        if (!connected) {
          _selectedDevice = null;
        }
      });
    });
    _bluetoothService.transferProgressStream.listen((progress) {
      if (!mounted) return;
      setState(() {
        _transferProgress = progress;
        _transferLabel = progress > 0 && progress < 1
            ? 'Transferring ${(progress * 100).toStringAsFixed(0)}%'
            : '';
      });
    });
    _initializeNearby();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnboardingBannerState();
    });
  }

  Future<void> _initializeNearby() async {
    _permissionsGranted = await _requestPermissions();
    if (_permissionsGranted) {
      _advertising = await _bluetoothService
          .startAdvertising('NEXCHAT_${DateTime.now().millisecondsSinceEpoch}');
    }
    setState(() {});
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.storage,
    ].request();

    return statuses.values
        .every((status) => status.isGranted || status.isLimited);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bluetoothService.dispose();
    super.dispose();
  }

  Future<void> _toggleDiscovery() async {
    if (!_permissionsGranted) {
      _permissionsGranted = await _requestPermissions();
      if (!_permissionsGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions are required.')),
        );
        return;
      }
    }

    if (_discovering) {
      await _bluetoothService.stopDiscovery();
    } else {
      await _bluetoothService.startDiscovery();
    }
    setState(() {
      _discovering = !_discovering;
    });
  }

  Future<void> _connectToDevice(Endpoint device) async {
    final success = await _bluetoothService.requestConnection(
      'NEXCHAT_${DateTime.now().millisecondsSinceEpoch}',
      device.id,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _selectedDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
    }
  }

  Future<void> _stopAdvertising() async {
    await _bluetoothService.stopAdvertising();
    setState(() {
      _advertising = false;
    });
  }

  Future<void> _startAdvertising() async {
    if (!_permissionsGranted) {
      _permissionsGranted = await _requestPermissions();
      if (!_permissionsGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions are required.')),
        );
        return;
      }
    }

    final started = await _bluetoothService
        .startAdvertising('NEXCHAT_${DateTime.now().millisecondsSinceEpoch}');
    setState(() {
      _advertising = started;
    });
  }

  Future<void> _disconnectDevice() async {
    await _bluetoothService.disconnect();
    setState(() {
      _selectedDevice = null;
      _transferProgress = 0.0;
      _transferLabel = '';
    });
  }

  Future<void> _loadOnboardingBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final displayed = prefs.getBool('offline_chat_onboarding_shown') ?? false;
    if (!mounted) return;
    setState(() {
      _showOnboardingBanner = !displayed;
    });
  }

  Future<void> _dismissOnboardingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_chat_onboarding_shown', true);
    if (!mounted) return;
    setState(() {
      _showOnboardingBanner = false;
    });
  }

  Future<void> _showSetupDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101524),
          title: const Text('Offline Chat Setup',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'Allow Bluetooth and location permissions, then start advertising and scan for peers.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                    '1. Tap the Bluetooth icon to start or stop advertising.',
                    style: TextStyle(color: Colors.white70)),
                const Text('2. Tap Scan Devices to discover nearby peers.',
                    style: TextStyle(color: Colors.white70)),
                const Text('3. Connect, then send messages or files offline.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                if (!_permissionsGranted)
                  const Text(
                    'If permissions are missing, use the button below to request them.',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Close', style: TextStyle(color: Colors.white70)),
            ),
            if (!_permissionsGranted)
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final granted = await _requestPermissions();
                  if (!mounted) return;
                  setState(() {
                    _permissionsGranted = granted;
                  });
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(granted
                          ? 'Permissions granted. You can start advertising now.'
                          : 'Permissions still missing. Please enable them in settings.'),
                    ),
                  );
                },
                child: const Text('Request Permissions',
                    style: TextStyle(color: kNeonBlue)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    await _bluetoothService.sendText(text);
    _messageController.clear();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    await _bluetoothService.sendFile(file.path);
  }

  Future<void> _showMessageActions(OfflineMessage message) async {
    if (message.type != OfflineMessageType.file || message.filePath == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101524),
          title: const Text('File received',
              style: TextStyle(color: Colors.white)),
          content: Text(
            'File saved to:\n${message.filePath}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: kNeonBlue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return StreamBuilder<List<Endpoint>>(
      stream: _bluetoothService.endpointsStream,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        if (devices.isEmpty) {
          return const Center(
            child: Text('No devices found yet.',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          itemCount: devices.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12),
          itemBuilder: (context, index) {
            final device = devices[index];
            final isSelected = _selectedDevice?.id == device.id;
            return ListTile(
              tileColor: const Color(0xFF111A33),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              selected: isSelected,
              selectedTileColor: const Color(0xFF1F2E5A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              title: Text(device.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: Text(device.id,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? kNeonPurple : kNeonBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _connected ? null : () => _connectToDevice(device),
                child: Text(isSelected ? 'CONNECTED' : 'CONNECT'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(
      String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No offline messages yet.',
            style: TextStyle(color: Colors.white60, fontSize: 14)),
      );
    }
    return ListView.separated(
      reverse: true,
      itemCount: _messages.length,
      padding: const EdgeInsets.symmetric(vertical: 14),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isSentByMe = message.sender == 'You';
        final backgroundColor =
            isSentByMe ? const Color(0xFF5B3EFF) : const Color(0xFF17213F);
        final textColor = isSentByMe ? Colors.white : Colors.white70;
        final bubbleRadius = BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isSentByMe ? 20 : 4),
          bottomRight: Radius.circular(isSentByMe ? 4 : 20),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Align(
            alignment:
                isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showMessageActions(message),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: bubbleRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == OfflineMessageType.file)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.attach_file_rounded,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "File: ${message.fileName ?? 'unknown'}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    if (message.type == OfflineMessageType.file)
                      const SizedBox(height: 10),
                    Text(message.text,
                        style: TextStyle(
                            color: textColor, height: 1.35, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message.sender,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                        Text(
                          '${message.timestamp.hour.toString().padLeft(2, "0")}:${message.timestamp.minute.toString().padLeft(2, "0")}',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101524),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text('NEX Offline Chat'),
        actions: [
          IconButton(
            icon: Icon(_discovering
                ? Icons.stop_circle_outlined
                : Icons.bluetooth_searching_rounded),
            onPressed: _toggleDiscovery,
            tooltip: _discovering ? 'Stop scanning' : 'Scan for peers',
          ),
          IconButton(
            icon: Icon(_advertising
                ? Icons.bluetooth_disabled
                : Icons.bluetooth_audio),
            onPressed: _advertising ? _stopAdvertising : _startAdvertising,
            tooltip: _advertising ? 'Stop advertising' : 'Start advertising',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF11172B), Color(0xFF0A0E1D)],
            ),
          ),
          child: Column(
            children: [
              if (_showOnboardingBanner)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2745).withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    border: Border.all(color: const Color(0xFF2D4FD3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offline Chat Guide',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            SizedBox(height: 10),
                            Text(
                              'Enable Bluetooth, advertise your device, scan nearby peers, and send secure messages or files offline.',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: _dismissOnboardingBanner,
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF192142),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF24335D)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _connected
                                ? 'Connected to ${_selectedDevice?.name ?? _bluetoothService.connectedEndpointName ?? 'peer'}'
                                : 'Offline Mode',
                            style: TextStyle(
                                color: _connected ? kNeonGreen : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 24),
                          ),
                        ),
                        if (_connected)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kNeonPurple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: _disconnectDevice,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              child: Text('Disconnect',
                                  style: TextStyle(letterSpacing: 0.4)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Peer: ${_selectedDevice?.name ?? _bluetoothService.connectedEndpointName ?? 'No peer selected'}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStatusChip(
                            _permissionsGranted
                                ? 'Permissions granted'
                                : 'Permissions required',
                            _permissionsGranted
                                ? kNeonGreen
                                : Colors.orangeAccent,
                            _permissionsGranted ? Colors.black : Colors.white),
                        _buildStatusChip(
                            _advertising ? 'Advertising' : 'Not advertising',
                            _advertising ? kNeonBlue : const Color(0xFF2F3F5C),
                            Colors.white),
                        _buildStatusChip(
                            _discovering ? 'Scanning' : 'Idle',
                            _discovering
                                ? kNeonPurple
                                : const Color(0xFF2F3F5C),
                            Colors.white),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tap the Bluetooth controls to advertise or scan, then connect to a nearby device to share text and files.',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.white70),
                          onPressed: _showSetupDialog,
                          tooltip: 'Setup help',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_transferLabel.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_transferLabel,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                              '${(_transferProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: _transferProgress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF0D1226),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(kNeonPurple),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nearby devices',
                        style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_nearbyDeviceCount devices',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: _buildDeviceList(),
              ),
              Expanded(
                child: _buildMessages(),
              ),
              Container(
                height: 180,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF141C33),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(
                                color: Colors.white, height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'Write a message or attach a file...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0E1530),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: kNeonPurple,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kNeonPurple.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _connected ? _sendText : null,
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white),
                            tooltip: 'Send message',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file_rounded,
                                color: Colors.white),
                            label: const Text('Send File',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2056C4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _connected ? _sendFile : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      floatingActionButton: _discovering
          ? FloatingActionButton.extended(
              backgroundColor: kNeonPurple,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Scan'),
              onPressed: _toggleDiscovery,
            )
          : FloatingActionButton.extended(
              backgroundColor: const Color.fromARGB(255, 55, 117, 138),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Scan Devices'),
              onPressed: _toggleDiscovery,
            ),
    );
  }
}
