import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/invite_model.dart';
import '../models/join_request_model.dart';

class Notifcations extends StatelessWidget {
  const Notifcations({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: _combinedStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(l10n.errorLoadingNotifications),
            );
          }

          final snapshots = snapshot.data ?? [];
          final invites = snapshots.isNotEmpty
              ? (snapshots[0].docs)
                  .map((doc) => CircleInvite.fromFirestore(doc))
                  .where((inv) => inv.status == 'pending')
                  .toList()
              : <CircleInvite>[];
          final requests = snapshots.length > 1
              ? (snapshots[1].docs)
                  .map((doc) => JoinRequest.fromFirestore(doc))
                  .where((r) => r.status == 'pending')
                  .toList()
              : <JoinRequest>[];

          if (invites.isEmpty && requests.isEmpty) {
            return Center(
              child: Text(
                l10n.noNotifications,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 16,
                ),
              ),
            );
          }

          final items = <Widget>[];
          for (final inv in invites) {
            items.add(_InviteCard(invite: inv));
          }
          for (final req in requests) {
            items.add(_JoinRequestCard(request: req));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => items[i],
          );
        },
      ),
    );
  }

  Stream<List<QuerySnapshot>> _combinedStream(String uid) {
    final inviteStream = FirebaseFirestore.instance
        .collection('invites')
        .where('invitedUserId', isEqualTo: uid)
        .snapshots();
    final requestStream = FirebaseFirestore.instance
        .collection('joinRequests')
        .where('adminId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return inviteStream.asyncMap((inv) async {
      final req = await requestStream.first;
      return [inv, req];
    });
  }
}

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedCircle(widget.invite.circleName)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAccepting)),
        );
      }
    }
  }

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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDeclining)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCircleAvatar(widget.invite),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.inviteToCircle(widget.invite.circleName),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.youWereInvited,
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _decline,
                      child: Text(l10n.decline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _accept,
                      child: Text(l10n.accept),
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

class _JoinRequestCard extends StatefulWidget {
  final JoinRequest request;
  const _JoinRequestCard({required this.request});

  @override
  State<_JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<_JoinRequestCard> {
  bool _isLoading = false;

  Widget _buildUserAvatar() {
    final b64 = widget.request.requestingUserImageBase64;
    final url = widget.request.requestingUserImageUrl;
    if (b64 != null && b64.isNotEmpty) {
      return CircleAvatar(backgroundImage: MemoryImage(base64Decode(b64)));
    }
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    return const CircleAvatar(child: Icon(Icons.person_outline));
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final reqRef = FirebaseFirestore.instance
          .collection('joinRequests')
          .doc(widget.request.id);
      batch.delete(reqRef);

      final circleRef = FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.request.circleId);
      batch.update(circleRef, {
        'members': FieldValue.arrayUnion([widget.request.requestingUserId]),
        'memberCount': FieldValue.increment(1),
      });

      await batch.commit();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.memberAdded(widget.request.requestingDisplayName)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAccepting)),
        );
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('joinRequests')
          .doc(widget.request.id)
          .delete();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDeclining)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.wantsToJoin(widget.request.requestingDisplayName),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.joinRequestFor(widget.request.circleName),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _decline,
                      child: Text(l10n.decline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _accept,
                      child: Text(l10n.accept),
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
