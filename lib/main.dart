import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'services/notification_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('de'));

// Circle ID from a deep link that is waiting to be opened in MainScreen
final ValueNotifier<String?> pendingInviteCircleId = ValueNotifier(null);

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

  final savedLocale = prefs.getString('locale') ?? 'de';
  localeNotifier.value = Locale(savedLocale);

  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  try {
    await NotificationService.init();
  } catch (_) {}

  // Handle deep links (orbit://join?circle=CIRCLE_ID)
  final appLinks = AppLinks();
  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null &&
        initialUri.scheme == 'orbit' &&
        initialUri.host == 'join') {
      final id = initialUri.queryParameters['circle'];
      if (id != null && id.isNotEmpty) pendingInviteCircleId.value = id;
    }
  } catch (_) {}
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'orbit' && uri.host == 'join') {
      final id = uri.queryParameters['circle'];
      if (id != null && id.isNotEmpty) pendingInviteCircleId.value = id;
    }
  });

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    try {
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            final locale = prefs.getString('locale') ?? 'de';
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'fcmToken': fcmToken, 'notifLocale': locale}, SetOptions(merge: true));
          }
        } catch (_) {}
      }
    } catch (_) {}
  });

  // FCM Token automatisch updaten wenn er sich ändert
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    }
  });

  // Benachrichtigung anzeigen wenn App vorne ist
  FirebaseMessaging.onMessage.listen(NotificationService.handleForegroundMessage);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) => ValueListenableBuilder<Locale>(
        valueListenable: localeNotifier,
        builder: (context, locale, _) => MaterialApp(
          title: 'Orbit',

          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,

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
              outline: Color(0xFF6E6E6E),
              surface: Color(0xFF1C1C1C),
              surfaceContainer: Color(0xFF2A2A2A),
              surfaceContainerHighest: Color(0xFF3A3A3A),
              onSurfaceVariant: Color(0xFFB0B0B0),
            ),
          ),

          themeMode: mode,

          // homepage
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
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
                    if (docSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data =
                        docSnapshot.data?.data() as Map<String, dynamic>?;
                    if (data != null && data['profileComplete'] == true) {
                      return const MainScreen();
                    }

                    return const SetupProfileScreen();
                  },
                );
              }

              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
