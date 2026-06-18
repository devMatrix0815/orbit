import 'package:flutter/material.dart';

// main screen
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      // light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A1A),
          outline: Color(0xFFE0E0E0),
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
          outline: Color(0xFF2C2C2C),
        ),
      ),

      themeMode: ThemeMode.light,
      home: const MainScreen(),
    );
  }
}
