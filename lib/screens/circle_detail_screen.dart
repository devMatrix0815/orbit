import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/circle_model.dart';
import 'invite_members_screen.dart';

class CircleDetailScreen extends StatefulWidget {
  final Circle circle;

  const CircleDetailScreen({super.key, required this.circle});

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late String _circleName;

  @override
  void initState() {
    super.initState();
    _circleName = widget.circle.name;
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _circleName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppen-Name ändern'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Neuer Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({'name': newName});
      setState(() => _circleName = newName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Umbenennen.')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppe löschen'),
        content: Text(
          'Möchtest du "$_circleName" wirklich löschen? Das kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .delete();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Löschen.')),
        );
      }
    }
  }

  void _showChangeImageInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bild ändern kommt bald!')),
    );
  }

  void _showMembersInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mitgliederliste kommt bald!')),
    );
  }

  Future<void> _leaveGroup() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppe verlassen'),
        content: Text(
          'Möchtest du "$_circleName" wirklich verlassen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circle.id)
          .update({
        'members': FieldValue.arrayRemove([currentUid]),
        'memberCount': FieldValue.increment(-1),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Verlassen der Gruppe.')),
        );
      }
    }
  }

  void _openInviteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteMembersScreen(
          circleId: widget.circle.id,
          circleName: _circleName,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final Uint8List? imageBytes = widget.circle.imageBase64 != null
        ? base64Decode(widget.circle.imageBase64!)
        : null;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: imageBytes != null
          ? Image.memory(imageBytes, fit: BoxFit.cover)
          : const ColoredBox(
              color: Color(0xFFFF9966),
              child: Center(
                child: Icon(Icons.group, size: 64, color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildInfoSection() {
    final tags = widget.circle.tags;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 18),
              const SizedBox(width: 8),
              Text(
                '${widget.circle.memberCount} Mitglieder',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.label_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUid == widget.circle.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(_circleName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDialog();
                case 'image':
                  _showChangeImageInfo();
                case 'invites':
                  _openInviteScreen();
                case 'members':
                  _showMembersInfo();
                case 'delete':
                  _showDeleteDialog();
                case 'leave':
                  _leaveGroup();
              }
            },
            itemBuilder: (context) => isCreator
                ? [
                    const PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Namen ändern'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'image',
                      child: ListTile(
                        leading: Icon(Icons.image_outlined),
                        title: Text('Bild ändern'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'invites',
                      child: ListTile(
                        leading: Icon(Icons.person_add_outlined),
                        title: Text('Einladungen verwalten'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people_outline),
                        title: Text('Mitglieder anzeigen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          'Gruppe löschen',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ]
                : [
                    const PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: Icon(Icons.people_outline),
                        title: Text('Mitglieder anzeigen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.red),
                        title: Text(
                          'Gruppe verlassen',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: Text(
                'Diese Gruppe ist noch leer.\nNachrichten und Events kommen bald!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          _buildInfoSection(),
        ],
      ),
    );
  }
}
