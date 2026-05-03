import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  static const routeName = '/permissions';
  static const firstTimeKey = 'first_time_user';
  
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = true;
  final Map<String, PermissionStatus> _permissions = {};
  final List<Map<String, dynamic>> _permissionList = [
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
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
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
      final status = await (perm['permission'] as Permission).status;
      _permissions[perm['key'] as String] = status;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _requestPermission(String key, Permission permission) async {
    setState(() {
      _permissions[key] = PermissionStatus.limited;
    });

    final status = await permission.request();
    
    setState(() {
      _permissions[key] = status;
    });
    
    // Check if all permissions are now granted
    if (_allPermissionsGranted) {
      await _markFirstTimeComplete();
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);
    
    for (var perm in _permissionList) {
      final key = perm['key'] as String;
      final permission = perm['permission'] as Permission;
      final status = await permission.request();
      _permissions[key] = status;
    }
    
    setState(() => _isLoading = false);
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
                            child: const Icon(Icons.security, color: Colors.white, size: 48),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: kNeonBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$_grantedCount/${_permissionList.length} permissions granted',
                              style: const TextStyle(color: kNeonBlue, fontWeight: FontWeight.w500),
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
                          final status = _permissions[key] ?? PermissionStatus.denied;
                          final isGranted = status.isGranted;
                          final color = perm['color'] as Color;

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
                                child: Icon(perm['icon'] as IconData, color: color),
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
                              trailing: isGranted
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kNeonGreen.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: kNeonGreen, size: 20),
                                    )
                                  : TextButton(
                                      onPressed: () => _requestPermission(key, perm['permission'] as Permission),
                                      child: const Text('Allow'),
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
                                onPressed: () async {
                                  await _requestAllPermissions();
                                  await _markFirstTimeComplete();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                // Mark first time complete and go to home
                                await _markFirstTimeComplete();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _allPermissionsGranted ? 'Continue' : 'Skip for now',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
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
