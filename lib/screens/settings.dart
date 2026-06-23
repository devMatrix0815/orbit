import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/screens/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:orbit/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orbit/main.dart' show themeNotifier;

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _checkingUpdate = false;
  double? _downloadProgress;
  String _currentVersion = '';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeNotifier.value == ThemeMode.dark;
    UpdateService.currentVersion().then((v) {
      if (mounted) setState(() => _currentVersion = v);
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() => _isDarkMode = isDark);
  }

  // load current profile data and show edit sheet
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

  // sign out google and firebase then go to login
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

  // delete account - removes owned circles, invites, firestore data and auth account
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
        // delete owned circles and their invites
        final ownedCircles = await FirebaseFirestore.instance
            .collection('circles')
            .where('createdBy', isEqualTo: user.uid)
            .get();
        for (final doc in ownedCircles.docs) {
          final invites = await FirebaseFirestore.instance
              .collection('invites')
              .where('circleId', isEqualTo: doc.id)
              .get();
          for (final invite in invites.docs) {
            await invite.reference.delete();
          }
          await doc.reference.delete();
        }

        // delete firestore user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // delete firebase auth account
        await user.delete();
      }

      // google sign out
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

      // re-authentication required
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

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);

    try {
      final update = await UpdateService.checkForUpdate();

      if (!mounted) return;

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Du verwendest bereits die neueste Version.')),
        );
        return;
      }

      final install = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Update verfügbar – v${update.version}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (update.releaseNotes.isNotEmpty) ...[
                  const Text(
                    'Änderungen:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(update.releaseNotes),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Später'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Jetzt installieren'),
            ),
          ],
        ),
      );

      if (install != true || !mounted) return;

      setState(() => _downloadProgress = 0.0);
      UpdateService.hasUpdate.value = false;

      await UpdateService.downloadAndInstall(
        update.downloadUrl,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Netzwerkfehler: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Einstellungen'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(18.0),
        child: ListView(
          children: [
            // dark / light mode toggle
            Card(
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Dark Mode')),
                    Switch(
                      value: _isDarkMode,
                      onChanged: _toggleTheme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // edit profile
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

            // app update
            Card(
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: (_checkingUpdate || _downloadProgress != null)
                    ? null
                    : _checkForUpdate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.system_update,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 10),
                                const Text('App-Update'),
                                if (_currentVersion.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'v$_currentVersion',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(150),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_checkingUpdate)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_downloadProgress == null)
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        ],
                      ),
                      if (_downloadProgress != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(_downloadProgress! * 100).toStringAsFixed(0)} %',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // sign out
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

            // delete account
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

// bottom sheet to edit name and age
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

            // name field
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

            // age field
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

            // save button
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
