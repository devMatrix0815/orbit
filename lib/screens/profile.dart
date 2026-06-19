import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';

// screens
import 'package:orbit/screens/settings.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Ausloggen'),
        ),
      ),
    );
  }
}
