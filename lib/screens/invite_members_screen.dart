import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite_model.dart';

class InviteMembersScreen extends StatefulWidget {
  final String circleId;
  final String circleName;

  const InviteMembersScreen({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final TextEditingController _emailController = TextEditingController();
  List<CircleInvite> _invites = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('invites')
        .where('circleId', isEqualTo: widget.circleId)
        .get();

    final sorted = snapshot.docs
        .map((doc) => CircleInvite.fromFirestore(doc))
        .toList()
      ..sort((a, b) => b.invitedAt.compareTo(a.invitedAt));

    setState(() {
      _invites = sorted;
      _isLoading = false;
    });
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine E-Mail-Adresse eingeben.')),
      );
      return;
    }

    final alreadyInvited = _invites.any(
      (inv) => inv.invitedEmail.toLowerCase() == email,
    );
    if (alreadyInvited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email wurde bereits eingeladen.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('invites').add({
        'invitedEmail': email,
        'invitedBy': uid,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'circleId': widget.circleId,
        'circleName': widget.circleName,
      });

      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Einladung gesendet an $email')),
        );
      }
      await _loadInvites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden der Einladung.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case 'accepted':
        return const Chip(
          label: Text('Akzeptiert'),
          avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
          labelStyle: TextStyle(color: Colors.green, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      case 'declined':
        return const Chip(
          label: Text('Abgelehnt'),
          avatar: Icon(Icons.cancel, size: 16, color: Colors.red),
          labelStyle: TextStyle(color: Colors.red, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      default:
        return const Chip(
          label: Text('Ausstehend'),
          avatar: Icon(Icons.schedule, size: 16, color: Colors.orange),
          labelStyle: TextStyle(color: Colors.orange, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einladungen verwalten'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-Mail-Adresse eingeben',
                      hintText: 'person@example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    onSubmitted: (_) => _sendInvite(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSending ? null : _sendInvite,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Eingeladene Personen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _invites.isEmpty
                      ? const Center(
                          child: Text(
                            'Noch niemand eingeladen.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _invites.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final invite = _invites[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(invite.invitedEmail),
                              trailing: _buildStatusChip(invite.status),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
