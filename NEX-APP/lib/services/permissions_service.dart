import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  // Check all required permissions
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return {
      Permission.camera: await Permission.camera.status,
      Permission.microphone: await Permission.microphone.status,
      Permission.notification: await Permission.notification.status,
      Permission.storage: await Permission.storage.status,
    };
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request all permissions needed for the app
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // Camera for video calls
    results['camera'] = await requestCameraPermission();

    // Microphone for voice/video calls
    results['microphone'] = await requestMicrophonePermission();

    // Notifications for messages and calls
    results['notification'] = await requestNotificationPermission();

    // Storage for profile pictures and media
    results['storage'] = await requestStoragePermission();

    return results;
  }

  // Check if a specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // Open app settings for manual permission grant
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // Get permission status text
  String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }
}

// Permission enum extension for easy access
extension PermissionExtension on Permission {
  String get displayName {
    switch (this) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.notification:
        return 'Notifications';
      case Permission.storage:
        return 'Storage';
      case Permission.photos:
        return 'Photos';
      default:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case Permission.camera:
        return 'Required for video calls';
      case Permission.microphone:
        return 'Required for voice and video calls';
      case Permission.notification:
        return 'Required for message and call alerts';
      case Permission.storage:
        return 'Required for profile pictures and media';
      case Permission.photos:
        return 'Required for selecting images';
      default:
        return 'Required for app functionality';
    }
  }

  IconData get icon {
    switch (this) {
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.microphone:
        return Icons.mic;
      case Permission.notification:
        return Icons.notifications;
      case Permission.storage:
        return Icons.folder;
      case Permission.photos:
        return Icons.photo;
      default:
        return Icons.lock;
    }
  }
}
