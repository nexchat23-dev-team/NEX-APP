import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class PermissionScreen extends StatefulWidget {
  static const routeName = '/permissions';
  static const firstTimeKey = 'first_time_user';

  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isProcessingPermission = false;
  String? _selectedPermissionKey = 'storage'; // Default to storage
  final Map<String, PermissionStatus> _permissions = {};
  final Set<String> _selectedPermissions = {};
  final List<Map<String, dynamic>> _permissionList = [
    // Extended permission list: added contacts and overlay support
    {
      'key': 'camera',
      'permission': Permission.camera,
      'title': 'Camera',
      'subtitle': 'Required for video calls',
      'icon': Icons.videocam,
      'color': kNeonBlue,
    },
    {
      'key': 'microphone',
      'permission': Permission.microphone,
      'title': 'Microphone',
      'subtitle': 'Required for voice & video calls',
      'icon': Icons.mic,
      'color': kNeonPurple,
    },
    {
      'key': 'notification',
      'permission': Permission.notification,
      'title': 'Notifications',
      'subtitle': 'Required for message alerts',
      'icon': Icons.notifications,
      'color': kNeonGreen,
    },
    {
      'key': 'storage',
      'permission': Permission.storage,
      'title': 'Storage',
      'subtitle': 'Required for profile pictures',
      'icon': Icons.folder,
      'color': Colors.orange,
    },
    {
      'key': 'bluetooth',
      'permission': Permission.bluetooth,
      'title': 'Bluetooth',
      'subtitle': 'Required for nearby & offline features',
      'icon': Icons.bluetooth,
      'color': Colors.cyan,
    },
    {
      'key': 'bluetoothScan',
      'permission': Permission.bluetoothScan,
      'title': 'Bluetooth Scan',
      'subtitle': 'Required to discover nearby devices',
      'icon': Icons.wifi_tethering,
      'color': Colors.cyan,
    },
    {
      'key': 'bluetoothConnect',
      'permission': Permission.bluetoothConnect,
      'title': 'Bluetooth Connect',
      'subtitle': 'Required to connect to nearby devices',
      'icon': Icons.usb,
      'color': Colors.cyan,
    },
    {
      'key': 'contacts',
      'permission': Permission.contacts,
      'title': 'Contacts',
      'subtitle': 'Access contacts to invite friends',
      'icon': Icons.contacts,
      'color': kNeonGreen,
    },
    {
      'key': 'overlay',
      'permission': Permission.systemAlertWindow,
      'title': 'Display over other apps',
      'subtitle': 'Required for in-call overlays and persistent UI',
      'icon': Icons.layers,
      'color': Colors.deepPurple,
    },
    {
      'key': 'backgroundData',
      'permission': null, // Special permission handled differently
      'title': 'Background Data',
      'subtitle': 'Required for real-time messaging',
      'icon': Icons.data_usage,
      'color': kNeonPurple,
      'isSpecial': true, // Mark as special permission
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(PermissionScreen.firstTimeKey) ?? true;

    if (!isFirstTime) {
      // Not first time - skip to home directly
      if (mounted) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
      return;
    }

    // First time - check permissions
    _checkPermissions();
  }

  Future<void> _markFirstTimeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionScreen.firstTimeKey, false);
  }

  Future<void> _checkPermissions() async {
    for (var perm in _permissionList) {
      final key = perm['key'] as String;
      final isSpecial = perm['isSpecial'] as bool? ?? false;

      if (isSpecial && key == 'backgroundData') {
        // Special handling for background data permission
        _permissions[key] =
            PermissionStatus.granted; // Assume granted for UI purposes
      } else {
        final permission = perm['permission'] as Permission;
        final status = await permission.status;
        _permissions[key] = status;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _requestPermission(String key, Permission? permission) async {
    if (_isProcessingPermission) return;

    if (key == 'backgroundData') {
      _showBackgroundDataDialog();
      return;
    }

    setState(() {
      _isProcessingPermission = true;
      _selectedPermissionKey = key;
      _selectedPermissions.add(key);
      _permissions[key] = PermissionStatus.limited;
    });

    try {
      final status = await _requestPermissionStatus(key, permission);

      if (!mounted) return;
      setState(() => _permissions[key] = status);

      if (!status.isGranted) {
        await _handleDeniedPermission(key, status);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPermission = false);
      }
    }
  }

  Future<PermissionStatus> _requestPermissionStatus(
    String key,
    Permission? permission,
  ) async {
    if (key == 'overlay') {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        await openAppSettings();
      }
      return status;
    }

    return await permission!.request();
  }

  Future<void> _handleDeniedPermission(
      String key, PermissionStatus status) async {
    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: kSurfaceColor,
          title: const Text('Permission required',
              style: TextStyle(color: Colors.white)),
          content: const Text(
              'This permission is permanently denied. Open app settings to enable it.',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings')),
          ],
        ),
      );
      return;
    }

    if (key == 'overlay') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Open Settings to allow Display over other apps.')),
      );
    }
  }

  Future<void> _requestAllPermissions() async {
    if (_isProcessingPermission) return;

    setState(() => _isProcessingPermission = true);

    try {
      for (var perm in _permissionList) {
        final key = perm['key'] as String;
        final isSpecial = perm['isSpecial'] as bool? ?? false;

        if (isSpecial && key == 'backgroundData') {
          _permissions[key] = PermissionStatus.granted;
          continue;
        }

        final permission = perm['permission'] as Permission?;
        final status = await _requestPermissionStatus(key, permission);
        _permissions[key] = status;
        _selectedPermissions.add(key);

        if (key == 'overlay' && !status.isGranted) {
          await openAppSettings();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPermission = false);
      }
    }
  }

  void _showBackgroundDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kNeonPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.data_usage, color: kNeonPurple),
            ),
            const SizedBox(width: 12),
            const Text(
              'Background Data Usage',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'NEXCHAT needs background data access to:\n\n'
          '• Receive real-time messages\n'
          '• Show instant notifications\n'
          '• Keep you connected with friends\n\n'
          'This permission is usually enabled by default. '
          'If you\'re experiencing connection issues, please check your device\'s data usage settings.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kNeonPurple)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  bool get _allPermissionsGranted {
    return _permissions.values.every((status) => status.isGranted);
  }

  int get _grantedCount {
    return _permissions.values.where((status) => status.isGranted).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kNeonBlue))
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kNeonBlue, kNeonPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: kNeonBlue.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.security,
                                color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Permissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NEXCHAT needs access to provide the best experience',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Progress indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: kNeonBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kNeonBlue.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$_grantedCount/${_permissionList.length} permissions granted',
                              style: const TextStyle(
                                  color: kNeonBlue,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Permission list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final perm = _permissionList[index];
                          final key = perm['key'] as String;
                          final status =
                              _permissions[key] ?? PermissionStatus.denied;
                          final isGranted = status.isGranted;
                          final color = perm['color'] as Color;
                          final isSpecial = perm['isSpecial'] as bool? ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isGranted
                                    ? color.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isGranted ? 2 : 1,
                              ),
                              boxShadow: isGranted
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(perm['icon'] as IconData,
                                    color: color),
                              ),
                              title: Text(
                                perm['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                perm['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              onTap: isGranted
                                  ? null
                                  : () => setState(
                                      () => _selectedPermissionKey = key),
                              selected:
                                  _selectedPermissionKey == key && !isGranted,
                              selectedTileColor: color.withValues(alpha: 0.1),
                              trailing: isGranted
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            kNeonGreen.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          color: kNeonGreen, size: 20),
                                    )
                                  : TextButton(
                                      onPressed: () => _requestPermission(key,
                                          perm['permission'] as Permission?),
                                      child: Text(
                                          isSpecial ? 'Learn More' : 'Allow'),
                                    ),
                            ),
                          );
                        },
                        childCount: _permissionList.length,
                      ),
                    ),
                  ),
                  // Bottom buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Allow current permission button
                          if (_selectedPermissionKey != null &&
                              (_permissions[_selectedPermissionKey] ??
                                      PermissionStatus.denied)
                                  .isDenied) ...[
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kNeonGreen, Color(0xFF00D9A3)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kNeonGreen.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isProcessingPermission
                                    ? null
                                    : () async {
                                        if (_selectedPermissionKey != null) {
                                          final perm =
                                              _permissionList.firstWhere(
                                            (p) =>
                                                p['key'] ==
                                                _selectedPermissionKey,
                                            orElse: () => <String, dynamic>{},
                                          );
                                          if (perm.isNotEmpty) {
                                            await _requestPermission(
                                              _selectedPermissionKey!,
                                              perm['permission'] as Permission?,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.done, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Allow "${_permissionList.firstWhere((p) => p['key'] == _selectedPermissionKey, orElse: () => {
                                              'title': 'Permission'
                                            })['title']}"',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!_allPermissionsGranted) ...[
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kNeonBlue, kNeonPurple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kNeonBlue.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isProcessingPermission
                                    ? null
                                    : () async {
                                        await _requestAllPermissions();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shield, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Grant All Permissions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await _markFirstTimeComplete();
                                if (!mounted) return;
                                navigator.pushReplacementNamed(
                                    ProfileScreen.routeName);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Continue to Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => openAppSettings(),
                            child: const Text(
                              'Open Settings',
                              style: TextStyle(color: kNeonBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
