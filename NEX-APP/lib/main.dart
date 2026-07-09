import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';
import 'providers/token_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/bet_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/calls_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/terminal_screen.dart';
import 'screens/video_feed_screen.dart';
import 'screens/video_post_screen.dart';
import './screens/gaming_hub_screen.dart';
import 'screens/advertisement_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/my_statuses_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/offline_chat_screen.dart';
import 'screens/user_search_screen.dart';
import 'services/auth_service.dart';
import 'services/offline_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Workmanager for background sync tasks
  Workmanager().initialize(
    callbackDispatcher,
  );
  // Register a periodic task to attempt sync every 15 minutes (OS dependent)
  Workmanager().registerPeriodicTask(
    'nex_offline_sync',
    'nexSyncTask',
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

  // Initialize Hive for offline storage
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);
    await Hive.openBox('messages');
    // initialize offline service
    try {
      await OfflineService().init();
    } catch (e) {
      debugPrint('OfflineService init error: $e');
    }
  } catch (e) {
    debugPrint('Hive initialization error: $e');
  }

  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const NexApp());
}

// Top-level callback for Workmanager. Must be a top-level function.
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Ensure Hive is initialized in background isolate
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);
      await Hive.openBox('messages');
      await OfflineService().init();
      await OfflineService().retryFailed();
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
    return Future.value(true);
  });
}

class NexApp extends StatelessWidget {
  const NexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TokenProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Use system theme by default; provider can override to 'light' or 'dark'
          ThemeMode mode = ThemeMode.system;
          if (themeProvider.themeModePref == 'light') mode = ThemeMode.light;
          if (themeProvider.themeModePref == 'dark') mode = ThemeMode.dark;

          return MaterialApp(
            title: 'NEX-APP',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getLightThemeData(),
            darkTheme: themeProvider.getDarkThemeData(),
            themeMode: mode,
            home: const SplashScreen(),
            routes: {
              LoginScreen.routeName: (_) => const LoginScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              ChatScreen.routeName: (_) => const ChatScreen(),
              BettingScreen.routeName: (_) => const BettingScreen(),
              MarketplaceScreen.routeName: (_) => const MarketplaceScreen(),
              ProfileScreen.routeName: (_) => const ProfileScreen(),
              SettingsScreen.routeName: (_) => const SettingsScreen(),
              GroupChatScreen.routeName: (_) => const GroupChatScreen(),
              CallsScreen.routeName: (_) => const CallsScreen(),
              AnnouncementsScreen.routeName: (_) => const AnnouncementsScreen(),
              TerminalScreen.routeName: (_) => const TerminalScreen(),
              VideoFeedScreen.routeName: (_) => const VideoFeedScreen(),
              VideoPostScreen.routeName: (_) => const VideoPostScreen(),
              GamingHubScreen.routeName: (_) => const GamingHubScreen(),
              AdvertisementScreen.routeName: (_) => const AdvertisementScreen(),
              PermissionScreen.routeName: (_) => const PermissionScreen(),
              RegisterScreen.routeName: (_) => const RegisterScreen(),
              ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
              MyStatusesScreen.routeName: (_) => const MyStatusesScreen(),
              JoinGroupScreen.routeName: (_) => const JoinGroupScreen(),
              OfflineChatScreen.routeName: (_) => const OfflineChatScreen(),
              UserSearchScreen.routeName: (_) => const UserSearchScreen(),
            },
          );
        },
      ),
    );
  }
}
