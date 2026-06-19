import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/screens/login_screen.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<void> _editProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};

    final nameController =
        TextEditingController(text: data['displayName'] as String? ?? '');
    final ageController = TextEditingController(
      text: data['age'] != null ? '${data['age']}' : '',
    );

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditProfileSheet(
        nameController: nameController,
        ageController: ageController,
        onSave: (name, age) async {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'displayName': name, 'age': age});
        },
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto löschen'),
        content: const Text(
          'Möchtest du dein Konto wirklich dauerhaft löschen? '
          'Alle deine Daten werden unwiderruflich entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore-Daten löschen
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Firebase Auth Account löschen
        await user.delete();
      }

      // Google Sign-Out
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      // Falls Re-Authentifizierung nötig ist
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bitte melde dich erneut an und versuche es nochmal.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: ${e.message}')),
        );
      }
    }
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
                onTap: () => _editProfile(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10),
                            const Text('Profil bearbeiten'),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Card(
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () => logout(context),
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

            const SizedBox(height: 8),

            Card(
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () => deleteAccount(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Konto löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.error,
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

class _EditProfileSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final Future<void> Function(String name, int age) onSave;

  const _EditProfileSheet({
    required this.nameController,
    required this.ageController,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil bearbeiten',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name darf nicht leer sein' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: widget.ageController,
              decoration: const InputDecoration(
                labelText: 'Alter',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Alter darf nicht leer sein';
                final n = int.tryParse(v);
                if (n == null || n < 13 || n > 120) return 'Bitte ein gültiges Alter eingeben';
                return null;
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        await widget.onSave(
                          widget.nameController.text.trim(),
                          int.parse(widget.ageController.text),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Speichern',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
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
