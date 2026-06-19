import 'package:flutter/material.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(18.0),
        child: ListView(
          children: [
            Card(
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: logout,

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),

                  child: Row(
                    children: [
                      // Text
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),

                            const SizedBox(width: 10),
                            const Text('Abmelden'),
                          ],
                        ),
                      ),

                      // > icon
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
