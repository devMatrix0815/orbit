import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite_model.dart';

// notifications screen - shows pending circle invites
class Notifcations extends StatelessWidget {
  const Notifcations({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Benachrichtigungen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // realtime stream of all invites for this user
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invites')
            .where('invitedUserId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Fehler beim Laden der Benachrichtigungen.'),
            );
          }

          // only show pending invites
          final pending = (snapshot.data?.docs ?? [])
              .map((doc) => CircleInvite.fromFirestore(doc))
              .where((inv) => inv.status == 'pending')
              .toList();

          // empty state
          if (pending.isEmpty) {
            return Center(
              child: Text(
                'Keine neuen Benachrichtigungen.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 16,
                ),
              ),
            );
          }

          // invite list
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _InviteCard(invite: pending[index]),
          );
        },
      ),
    );
  }
}

// single invite card with accept and decline buttons
class _InviteCard extends StatefulWidget {
  final CircleInvite invite;
  const _InviteCard({required this.invite});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _isLoading = false;

  Widget _buildCircleAvatar(CircleInvite invite) {
    if (invite.circleImageBase64 != null && invite.circleImageBase64!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: MemoryImage(base64Decode(invite.circleImageBase64!)),
      );
    }
    if (invite.circleImageUrl != null && invite.circleImageUrl!.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(invite.circleImageUrl!));
    }
    return const CircleAvatar(
      backgroundColor: Color(0xFFFF9966),
      child: Icon(Icons.group, color: Colors.white),
    );
  }

  // accept invite - deletes invite and adds user to circle
  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();

      final inviteRef = FirebaseFirestore.instance
          .collection('invites')
          .doc(widget.invite.id);
      batch.delete(inviteRef);

      final circleRef = FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.invite.circleId);
      batch.update(circleRef, {
        'members': FieldValue.arrayUnion([uid]),
        'memberCount': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Du bist jetzt in "${widget.invite.circleName}"!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Annehmen.')),
        );
      }
    }
  }

  // decline invite - only deletes the invite document
  Future<void> _decline() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('invites')
          .doc(widget.invite.id)
          .delete();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Ablehnen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // invite info
            Row(
              children: [
                _buildCircleAvatar(widget.invite),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Einladung zum Kreis "${widget.invite.circleName}"',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Du wurdest in diesen Kreis eingeladen.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // action buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _decline,
                      child: const Text('Ablehnen'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _accept,
                      child: const Text('Annehmen'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
