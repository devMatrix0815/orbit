import 'package:flutter/material.dart';

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/screens/main_screen.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  // for steps
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // to get input data
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  // Elements
  final List<String> _allInterests = [
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
  final Set<String> _selectedInterests = {};

  // clean up controllers
  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _goToPage2() {
    // to avoid no name input
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen ein.')),
      );
      return;
    }

    // to avoid no age input
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib ein gültiges Alter ein.')),
      );
      return;
    }

    // go to second page
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProfile() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle mindestens ein Interesse.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'googleId': user.uid,
        'email': user.email,
        'displayName': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'profileImageUrl': user.photoURL,
        'interests': _selectedInterests.toList(),
        'score': 0,
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildPage1(), _buildPage2()],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    // for photo url
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // progress bar
          _buildProgress(1),

          // big space
          const SizedBox(height: 32),

          // title - space - subtitle
          Text(
            'Erstelle dein Profil',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
          Text(
            'Wie sollen andere dich sehen?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),

          // big space
          const SizedBox(height: 48),

          // profile picture
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),

          // big space
          const SizedBox(height: 48),

          // name - space - age
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.outline,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Alter',
              prefixIcon: Icon(
                Icons.cake,
                color: Theme.of(context).colorScheme.outline,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),

          // space till bottom
          const Spacer(),

          // next
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: _goToPage2,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Weiter',
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

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              // back to previous step button
              IconButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
              ),

              // small space
              const SizedBox(width: 8),

              // progressbar
              Expanded(child: _buildProgress(2)),
            ],
          ),

          // big space
          const SizedBox(height: 24),

          // title - space - subtitle
          Text(
            'Deine Interessen',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Wähle mindestens ein Interesse aus.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),

          // big space
          const SizedBox(height: 24),

          // elements to select
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allInterests.map((interest) {
                  final selected = _selectedInterests.contains(interest);
                  return FilterChip(
                    backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF0FB),
                    label: Text(interest),
                    selected: selected,

                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return selected
                            ? const Color(0xFFEEF0FB)
                            : const Color.fromARGB(255, 238, 238, 238);
                      }
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFEEF0FB);
                      }
                      return const Color.fromARGB(255, 238, 238, 238);
                    }),

                    side: selected
                        ? const BorderSide(color: Color(0xFFC5CAE9), width: 1.5)
                        : BorderSide.none,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          // finish button
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'Profil erstellen',
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

  Widget _buildProgress(int step) {
    // color theme presets
    final active = Colors.blue[500];
    final inactive = Colors.blue[100];

    return Row(
      children: [
        // first step
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: active,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // space
        const SizedBox(width: 8),

        // second step
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step >= 2 ? active : inactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // space
        const SizedBox(width: 12),

        // step indicator
        Text('$step / 2', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
