import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/token_provider.dart';
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
import 'screens/ai_chat_screen.dart';
import 'screens/terminal_screen.dart';
import 'screens/gaming_hub_screen.dart';
import 'screens/advertisement_screen.dart';
import 'screens/permission_screen.dart';
import 'services/auth_service.dart';

const kNeonGreen = Color(0xFF25D366);
const kNeonBlue = Color(0xFF00B8F4);
const kNeonPurple = Color(0xFF9D4EDD);
const kPrimaryGreen = Color(0xFF075E54);
const kPrimaryBlue = Color(0xFF054A85);
const kDarkBackground = Color(0xFF0B1410);
const kSurfaceColor = Color(0xFF0F1E1B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      ],
      child: MaterialApp(
        title: 'NEXCHAT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: kPrimaryGreen,
          scaffoldBackgroundColor: kDarkBackground,
          canvasColor: kDarkBackground,
          cardColor: kSurfaceColor,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.dark(
            primary: kNeonGreen,
            secondary: kNeonBlue,
            tertiary: kNeonPurple,
            surface: kSurfaceColor,
            background: kDarkBackground,
            onSurface: Colors.white,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryBlue,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: kNeonBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0D2F49),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicator: UnderlineTabIndicator(borderSide: BorderSide(color: kNeonGreen, width: 3)),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          ChatScreen.routeName: (_) => const ChatScreen(),
          BetScreen.routeName: (_) => const BetScreen(),
          MarketplaceScreen.routeName: (_) => const MarketplaceScreen(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          GroupChatScreen.routeName: (_) => const GroupChatScreen(),
          CallsScreen.routeName: (_) => const CallsScreen(),
          AnnouncementsScreen.routeName: (_) => const AnnouncementsScreen(),
          AIChatScreen.routeName: (_) => const AIChatScreen(),
          TerminalScreen.routeName: (_) => const TerminalScreen(),
          GamingHubScreen.routeName: (_) => const GamingHubScreen(),
          AdvertisementScreen.routeName: (_) => const AdvertisementScreen(),
          PermissionScreen.routeName: (_) => const PermissionScreen(),
        },
      ),
    );
  }
}
