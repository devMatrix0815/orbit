import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite_model.dart';

// screen to search and invite users to a circle
class InviteMembersScreen extends StatefulWidget {
  final String circleId;
  final String circleName;
  final List<String> members;

  const InviteMembersScreen({
    super.key,
    required this.circleId,
    required this.circleName,
    required this.members,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<CircleInvite> _invites = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSending = false;
  Map<String, dynamic>? _foundUser;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // load existing invites for this circle
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

  // search user by exact display name (case insensitive)
  Future<void> _searchUser() async {
    final input = _nameController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _searchError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayNameLower', isEqualTo: input.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _searchError = 'Nutzer "$input" nicht gefunden.');
        return;
      }

      final doc = snapshot.docs.first;
      setState(() => _foundUser = {'uid': doc.id, ...doc.data()});
    } catch (e) {
      setState(() => _searchError = 'Fehler bei der Suche.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // send invite with duplicate and membership checks
  Future<void> _sendInvite() async {
    if (_foundUser == null) return;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final targetUid = _foundUser!['uid'] as String;
    final targetDisplayName = _foundUser!['displayName'] as String? ?? '';

    // can't invite yourself
    if (targetUid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du kannst dich nicht selbst einladen.')),
      );
      return;
    }

    // already a member
    if (widget.members.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$targetDisplayName" ist bereits Mitglied.')),
      );
      return;
    }

    // already invited
    final alreadyInvited = _invites.any(
      (inv) => inv.invitedUserId == targetUid && inv.status == 'pending',
    );
    if (alreadyInvited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$targetDisplayName" wurde bereits eingeladen.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('invites').add({
        'invitedUserId': targetUid,
        'invitedDisplayName': targetDisplayName,
        'invitedBy': currentUid,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'circleId': widget.circleId,
        'circleName': widget.circleName,
      });

      _nameController.clear();
      setState(() => _foundUser = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Einladung an "$targetDisplayName" gesendet.')),
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

  // user avatar - base64, url or placeholder
  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final base64 = user['profileImageBase64'] as String?;
    final url = user['profileImageUrl'] as String?;
    if (base64 != null && base64.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: MemoryImage(base64Decode(base64)),
      );
    }
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    return const CircleAvatar(child: Icon(Icons.person_outline));
  }

  // colored status chip for pending / accepted / declined
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
      appBar: AppBar(title: const Text('Einladungen verwalten')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // search row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name eingeben',
                      hintText: 'z.B. Hannes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_search_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _searchUser(),
                    onChanged: (_) => setState(() {
                      _foundUser = null;
                      _searchError = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSearching ? null : _searchUser,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // search result
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _searchError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              )
            else if (_foundUser != null)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _buildUserAvatar(_foundUser!),
                  title: Text(
                    _foundUser!['displayName'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: FilledButton(
                    onPressed: _isSending ? null : _sendInvite,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Einladen'),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // invited users list
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
                              title: Text(invite.invitedDisplayName),
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
