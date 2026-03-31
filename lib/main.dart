import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:strangr_app/firebase_options.dart';
import 'package:strangr_app/core/theme.dart';
import 'package:strangr_app/screens/splash_screen.dart';
import 'package:strangr_app/screens/login_screen.dart';
import 'package:strangr_app/screens/search_hub_screen.dart';
import 'package:strangr_app/screens/chat_screen.dart';
import 'package:strangr_app/screens/friends_screen.dart';
import 'package:strangr_app/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase connected successfully.");
  } catch (e) {
    print("CRITICAL: Firebase initialization failed! Error: $e");
  }
  
  runApp(const StrangRApp());
}

class StrangRApp extends StatelessWidget {
  const StrangRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrangR',
      debugShowCheckedModeBanner: false,
      theme: StrangRTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/search_hub': (context) => const SearchHubScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: args['roomId'],
              strangerId: args['strangerId'],
              strangRCode: args['strangRCode'] ?? 'Stranger',
            ),
          );
        }
        return null;
      },
    );
  }
}
