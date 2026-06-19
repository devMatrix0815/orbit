import 'package:flutter/material.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;

// screens
import 'package:orbit/screens/settings.dart';

const List<String> _allInterests = [  
  'Sport & Fitness',
  'Musik',
  'Gaming',
  'Lesen',
  'Kochen',
  'Reisen',
  'Fotografie',
  'Kunst',
  'Film & Serien',
  'Technologie',
  'Natur',
  'Mode',
  'Yoga',
  'Tanzen',
  'Wissenschaft',
  'Geschichte',
  'Sprachen',
  'Tiere',
  'DIY',
  'Finanzen',
  'Politik',
  'Philosophie',
  'Familie',
  'Ehrenamt',
  'Ernährung',
];

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _displayName = '';
  int? _age;
  List<String> _interests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _displayName = data['displayName'] as String? ?? '';
      _age = data['age'] as int?;
      _interests = List<String>.from(data['interests'] ?? []);
      _loading = false;
    });
  }

  Future<void> _saveInterests(List<String> updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'interests': updated});

    setState(() => _interests = updated);
  }

  Future<void> _openAddInterests() async {
    final toAdd = Set<String>.from(_interests);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddInterestsSheet(
        current: toAdd,
        onSave: (selected) async {
          await _saveInterests(selected.toList());
        },
      ),
    );
  }

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
            icon: const Icon(Icons.settings),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(1000),
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : const CircleAvatar(
                                  radius: 30,
                                  child: Icon(Icons.person, size: 30),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (_age != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$_age Jahre',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Interessen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddInterests,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Bearbeiten'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_interests.isEmpty)
                    Text(
                      'Noch keine Interessen hinzugefügt.',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.map((interest) {
                        return Chip(
                          backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                          label: Text(
                            interest,
                            style: const TextStyle(color: Colors.black),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class _AddInterestsSheet extends StatefulWidget {
  final Set<String> current;
  final Future<void> Function(Set<String>) onSave;

  const _AddInterestsSheet({required this.current, required this.onSave});

  @override
  State<_AddInterestsSheet> createState() => _AddInterestsSheetState();
}

class _AddInterestsSheetState extends State<_AddInterestsSheet> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.current);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interessen bearbeiten',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe auf ein Interesse um es hinzuzufügen oder zu entfernen.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allInterests.map((interest) {
                  final selected = _selected.contains(interest);
                  return FilterChip(
                    backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF0FB),
                    label: Text(interest),
                    selected: selected,
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color.fromARGB(255, 83, 52, 141)
                          : Colors.black,
                    ),
                    side: selected
                        ? const BorderSide(color: Color(0xFFC5CAE9), width: 1.5)
                        : BorderSide.none,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selected.add(interest);
                        } else {
                          _selected.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _saving = true);
                      await widget.onSave(_selected);
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
    );
  }
}
