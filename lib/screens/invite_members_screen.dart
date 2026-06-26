import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invite_model.dart';
import '../widgets/user_badges.dart';
import 'user_profile_screen.dart';

const _kJoinBaseUrl = 'https://orbit-download.vercel.app/join';

const _kVercelNotifyUrl = 'https://orbit-notification.vercel.app/api/notify';

class InviteMembersScreen extends StatefulWidget {
  final String circleId;
  final String circleName;
  final String? circleImageBase64;
  final String? circleImageUrl;
  final List<String> members;

  const InviteMembersScreen({
    super.key,
    required this.circleId,
    required this.circleName,
    this.circleImageBase64,
    this.circleImageUrl,
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

  Future<void> _searchUser() async {
    final l10n = AppLocalizations.of(context)!;
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
        setState(() => _searchError = l10n.userNotFound(input));
        return;
      }

      final doc = snapshot.docs.first;
      setState(() => _foundUser = {'uid': doc.id, ...doc.data()});
    } catch (e) {
      setState(() => _searchError = AppLocalizations.of(context)!.errorSearching);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendInvite() async {
    if (_foundUser == null) return;
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final targetUid = _foundUser!['uid'] as String;
    final targetDisplayName = _foundUser!['displayName'] as String? ?? '';

    if (targetUid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cantInviteYourself)),
      );
      return;
    }

    if (widget.members.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.alreadyMember(targetDisplayName))),
      );
      return;
    }

    final alreadyInvited = _invites.any(
      (inv) => inv.invitedUserId == targetUid && inv.status == 'pending',
    );
    if (alreadyInvited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.alreadyInvited(targetDisplayName))),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('invites').add({
        'invitedUserId': targetUid,
        'invitedDisplayName': targetDisplayName,
        if (_foundUser!['profileImageBase64'] != null)
          'invitedProfileImageBase64': _foundUser!['profileImageBase64'],
        if (_foundUser!['profileImageUrl'] != null)
          'invitedProfileImageUrl': _foundUser!['profileImageUrl'],
        'invitedBy': currentUid,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'circleId': widget.circleId,
        'circleName': widget.circleName,
        if (widget.circleImageBase64 != null)
          'circleImageBase64': widget.circleImageBase64,
        if (widget.circleImageUrl != null)
          'circleImageUrl': widget.circleImageUrl,
      });

      // Push notification to invited user
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final idToken = await user.getIdToken();
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        final senderName =
            senderDoc.data()?['displayName'] as String? ?? '';
        await Dio().post(_kVercelNotifyUrl, data: {
          'recipients': [
            {'uid': targetUid, 'type': 'invite'}
          ],
          'senderName': senderName,
          'circleName': widget.circleName,
          'idToken': idToken,
        });
      } catch (_) {}

      _nameController.clear();
      setState(() => _foundUser = null);

      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n2.inviteSent(targetDisplayName))),
        );
      }
      await _loadInvites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSendingInvite),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

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

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    switch (status) {
      case 'accepted':
        return Chip(
          label: Text(l10n.accepted),
          avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
          labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      case 'declined':
        return Chip(
          label: Text(l10n.declined),
          avatar: const Icon(Icons.cancel, size: 16, color: Colors.red),
          labelStyle: const TextStyle(color: Colors.red, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      default:
        return Chip(
          label: Text(l10n.pending),
          avatar: const Icon(Icons.schedule, size: 16, color: Colors.orange),
          labelStyle: const TextStyle(color: Colors.orange, fontSize: 12),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
    }
  }

  String get _inviteLink =>
      '$_kJoinBaseUrl?circle=${widget.circleId}&name=${Uri.encodeComponent(widget.circleName)}';

  Future<void> _copyInviteLink() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _inviteLink));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
  }

  void _showQrBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QrSheet(
        link: _inviteLink,
        circleName: widget.circleName,
      ),
    );
  }

  Widget _buildInviteLinkCard(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.inviteLink,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.inviteLinkHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _copyInviteLink,
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(l10n.copyLink),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: OutlinedButton(
                    onPressed: _showQrBottomSheet,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageInvites)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInviteLinkCard(l10n),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.enterName,
                      hintText: l10n.nameHint,
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
                  leading: GestureDetector(
                    onTap: () => openUserProfile(
                      context,
                      _foundUser!['uid'] as String,
                    ),
                    child: _buildUserAvatar(_foundUser!),
                  ),
                  title: GestureDetector(
                    onTap: () => openUserProfile(
                      context,
                      _foundUser!['uid'] as String,
                    ),
                    child: nameWithBadges(
                      _foundUser!['displayName'] as String? ?? '',
                      badges: List<String>.from(_foundUser!['badges'] ?? []),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                        : Text(l10n.invite),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Text(
              l10n.invitedPeople,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _invites.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noneInvitedYet,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _invites.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final invite = _invites[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: GestureDetector(
                                onTap: () => openUserProfile(
                                  context,
                                  invite.invitedUserId,
                                ),
                                child: _buildUserAvatar({
                                  'profileImageBase64':
                                      invite.invitedProfileImageBase64,
                                  'profileImageUrl':
                                      invite.invitedProfileImageUrl,
                                }),
                              ),
                              title: Text(invite.invitedDisplayName),
                              trailing: _buildStatusChip(invite.status, l10n),
                              onTap: () =>
                                  openUserProfile(context, invite.invitedUserId),
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

// ── QR Code Bottom Sheet ──────────────────────────────────────────────────────

class _QrSheet extends StatefulWidget {
  final String link;
  final String circleName;

  const _QrSheet({required this.link, required this.circleName});

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  final _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareAsImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/orbit_qr.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Orbit – ${widget.circleName}',
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrFg = isDark ? Colors.white : Colors.black;
    final qrBg = isDark ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.qrCode,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.circleName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // QR code – wrapped in RepaintBoundary for image capture
          GestureDetector(
            onLongPress: _shareAsImage,
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: qrBg,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: widget.link,
                  version: QrVersions.auto,
                  size: 220,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: qrFg,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: qrFg,
                  ),
                  backgroundColor: qrBg,
                  embeddedImage: const AssetImage('assets/icon.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            l10n.qrLongPressHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // Share button
          FilledButton.icon(
            onPressed: _sharing ? null : _shareAsImage,
            icon: _sharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share, size: 18),
            label: Text(l10n.qrShared.replaceFirst('!', '')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
