import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/screens/main_screen.dart';
import 'package:orbit/screens/setup_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // 1. Google Sign-In
      print('🔵 Google Sign-In wird gestartet...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('⚠️ User hat Sign-In abgebrochen');
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Google Sign-In erfolgreich: ${googleUser.email}');

      // 2. Get authentication details
      print('🔵 Authentifizierung wird geholt...');
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      print('✅ Auth Details geholt - accessToken: ${googleAuth.accessToken?.substring(0, 20)}...');

      // 3. Firebase Auth
      print('🔵 Firebase Auth wird gestartet...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      print('✅ Firebase Auth erfolgreich - User UID: ${user?.uid}');

      if (user != null && mounted) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (!mounted) return;

        if (data != null && data['profileComplete'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
            (route) => false,
          );
        }
      }
    } on Exception catch (e) {
      print('❌ Fehler: $e');
      print('Fehlertyp: ${e.runtimeType}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Mit Google anmelden'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}