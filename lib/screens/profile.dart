import 'package:flutter/material.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;

// screens
import 'package:orbit/screens/settings.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mein Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsetsGeometry.all(18.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1000),
                    child: Image.network(
                      photoUrl ?? 'assets/icon.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Column(
                    mainAxisAlignment: .start,
                    crossAxisAlignment: .start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          final displayName = data?['displayName'] as String? ?? '';
                          final age = data?['age'];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (age != null)
                                Text(
                                  '$age Jahre',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
