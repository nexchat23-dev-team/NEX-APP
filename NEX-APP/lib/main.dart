import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
import 'package:nex_app/screens/gaming_hub_screen.dart';
import 'screens/advertisement_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/my_statuses_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/offline_chat_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const NexApp());
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
          return MaterialApp(
            title: 'NEX-APP',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getThemeData(),
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
            },
          );
        },
      ),
    );
  }
}
