import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/setup_profile_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // system handles the notification automatically
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) => MaterialApp(
      title: 'Orbit',

      // light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A1A),
          outline: Color(0xFF555555),
        ),
      ),

      // dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          onSurface: Color(0xFFE5E5E5),
          outline: Color(0xFFB8B8B8),
        ),
      ),

      themeMode: mode,

      // homepage
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // loading before data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, docSnapshot) {
                // loading
                if (docSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // main screen
                final data = docSnapshot.data?.data() as Map<String, dynamic>?;
                if (data != null && data['profileComplete'] == true) {
                  return const MainScreen();
                }

                // Setup profile site
                return const SetupProfileScreen();
              },
            );
          }

          // login screen
          return const LoginScreen();
        },
      ),
    ));
  }
}
