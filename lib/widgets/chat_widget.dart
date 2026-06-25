import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orbit/l10n/app_localizations.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../widgets/user_badges.dart';
import '../screens/user_profile_screen.dart';
import 'orbit_widget/js_widget_bubble.dart';
import 'orbit_widget/widget_template_picker.dart';
import 'dart:convert';

class ChatWidget extends StatefulWidget {
  final String circleId;
  final String circleName;
  final String circleCreatorId;
  final List<String> circleOperators;

  const ChatWidget({
    super.key,
    required this.circleId,
    required this.circleName,
    required this.circleCreatorId,
    required this.circleOperators,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasMore = true;
  DateTime? _lastTimestamp;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  ChatMessage? _replyMessage;
  bool _isAdmin = false;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  List<_MemberInfo> _members = [];
  List<_MemberInfo> _filteredMembers = [];
  bool _showMentionSuggestions = false;
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _isAdmin = uid == widget.circleCreatorId ||
        widget.circleOperators.contains(uid);
    _loadMessages();
    _loadMembers();
    _messageController.addListener(_onTextChanged);
    _chatService.markMentionsSeen(widget.circleId);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final circleDoc = await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .get();
      final memberUids =
          List<String>.from(circleDoc.data()?['members'] ?? []);
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final others =
          memberUids.where((uid) => uid != currentUid).toList();
      if (others.isEmpty) return;
      final docs = await Future.wait(
        others.map(
          (uid) => FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _members = docs
            .where((d) => d.exists)
            .map((d) => _MemberInfo(
                  d.id,
                  d.data()?['displayName'] as String? ?? '',
                ))
            .where((m) => m.name.isNotEmpty)
            .toList();
      });
    } catch (_) {}
  }

  void _onTextChanged() {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;
    if (cursorPos < 0 || _members.isEmpty) {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
      return;
    }
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAt = textBeforeCursor.lastIndexOf('@');
    if (lastAt >= 0) {
      final partial = textBeforeCursor.substring(lastAt + 1);
      if (!partial.contains(' ')) {
        final filtered = _members
            .where((m) =>
                partial.isEmpty ||
                m.name.toLowerCase().startsWith(partial.toLowerCase()))
            .toList();
        if ('everyone'.startsWith(partial.toLowerCase())) {
          filtered.insert(0, _MemberInfo('__everyone__', 'everyone'));
        }
        if (filtered.isNotEmpty) {
          setState(() {
            _showMentionSuggestions = true;
            _filteredMembers = filtered;
            _mentionStartIndex = lastAt;
          });
          return;
        }
      }
    }
    if (_showMentionSuggestions) {
      setState(() => _showMentionSuggestions = false);
    }
  }

  void _insertMention(_MemberInfo member) {
    if (_mentionStartIndex < 0) return;
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;
    if (cursorPos < 0) return;
    final before = text.substring(0, _mentionStartIndex);
    final after =
        cursorPos < text.length ? text.substring(cursorPos) : '';
    final newText = '$before@${member.name} $after';
    final newCursor = before.length + member.name.length + 2;
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {
      _showMentionSuggestions = false;
      _mentionStartIndex = -1;
    });
  }

  void _loadMessages() {
    _chatService.getMessages(widget.circleId).listen(
      (messages) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          if (messages.isNotEmpty) {
            _lastTimestamp = messages.last.timestamp;
          }
        });
        if (messages.isNotEmpty && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorLoadingMessages),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMore || _isLoading || _lastTimestamp == null) return;

    try {
      final olderMessages = await _chatService.loadMoreMessages(
        widget.circleId,
        _lastTimestamp!,
      );

      setState(() {
        if (olderMessages.isEmpty) {
          _hasMore = false;
        } else {
          _messages = [..._messages, ...olderMessages];
          _lastTimestamp = olderMessages.last.timestamp;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorLoadingOlderMessages),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final reply = _replyMessage;

    final mentionedUids = <String>[];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (RegExp(r'@everyone(?:\s|$)', caseSensitive: false).hasMatch(text)) {
      for (final member in _members) {
        if (member.uid != currentUid) mentionedUids.add(member.uid);
      }
    } else {
      for (final member in _members) {
        if (RegExp(
          '@${RegExp.escape(member.name)}(?:\\s|\$)',
        ).hasMatch(text)) {
          mentionedUids.add(member.uid);
        }
      }
    }

    try {
      await _chatService.sendMessage(
        widget.circleId,
        text,
        replyToId: reply?.id,
        replyToText: reply?.text,
        replyToSenderName: reply?.senderName,
        replyToSenderId: reply?.senderId,
        circleName: widget.circleName,
        mentionedUids: mentionedUids,
      );
      _messageController.clear();
      setState(() => _replyMessage = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sendError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showWidgetPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => WidgetTemplatePicker(
        circleId: widget.circleId,
        parentContext: context,
      ),
    );
  }

  void _onMessageLongPress(ChatMessage message) {
    if (!_selectionMode) {
      HapticFeedback.mediumImpact();
      setState(() {
        _selectionMode = true;
        _selectedIds.add(message.id);
      });
    }
  }

  void _onMessageTap(ChatMessage message) {
    setState(() {
      if (_selectedIds.contains(message.id)) {
        _selectedIds.remove(message.id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(message.id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  GlobalKey _keyFor(String messageId) =>
      _messageKeys.putIfAbsent(messageId, () => GlobalKey());

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final List<String> toDelete;

    if (_isAdmin) {
      toDelete = _selectedIds.toList();
    } else {
      toDelete = _selectedIds.where((id) {
        for (final m in _messages) {
          if (m.id == id) return m.senderId == currentUid;
        }
        return false;
      }).toList();
    }

    if (toDelete.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotDeleteOthersMessages)),
        );
      }
      return;
    }

    try {
      await _chatService.deleteMessages(widget.circleId, toDelete);
      if (mounted) {
        setState(() {
          _selectionMode = false;
          _selectedIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sendError(e.toString()))),
        );
      }
    }
  }

  Widget _buildSelectionBar(AppLocalizations l10n) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: _exitSelectionMode,
            iconSize: 22,
          ),
          Expanded(
            child: Text(
              l10n.selectedCount(_selectedIds.length),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onSelected: (value) async {
              if (value == 'delete') await _deleteSelected();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions() {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: _filteredMembers.length,
        itemBuilder: (ctx, i) {
          final m = _filteredMembers[i];
          return ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                m.name[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              '@${m.name}',
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () => _insertMention(m),
          );
        },
      ),
      ),
    );
  }

  Widget _buildReplyBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyMessage!.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _replyMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyMessage = null),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (_selectionMode) _buildSelectionBar(l10n),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noMessages,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.beFirst,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels < 200 && _hasMore) {
                      _loadMoreMessages();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isOwnMessage =
                          message.senderId ==
                          FirebaseAuth.instance.currentUser?.uid;

                      return _MessageBubble(
                        key: _keyFor(message.id),
                        message: message,
                        isOwnMessage: isOwnMessage,
                        isSelected: _selectedIds.contains(message.id),
                        isHighlighted:
                            _highlightedMessageId == message.id,
                        selectionMode: _selectionMode,
                        members: _members,
                        onLongPress: () => _onMessageLongPress(message),
                        onTap: () => _onMessageTap(message),
                        onReply: () =>
                            setState(() => _replyMessage = message),
                        onReplyTap: message.replyToId != null
                            ? () => _scrollToMessage(message.replyToId!)
                            : null,
                      );
                    },
                  ),
                ),
        ),
        if (_showMentionSuggestions) _buildMentionSuggestions(),
        if (_replyMessage != null) _buildReplyBar(l10n),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: _showWidgetPicker,
                  tooltip: 'Widget einfügen',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: l10n.writeMessage,
                    hintStyle: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isSending
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Icon(Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final bool isSelected;
  final bool isHighlighted;
  final bool selectionMode;
  final List<_MemberInfo> members;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final VoidCallback? onReplyTap;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectionMode,
    required this.members,
    required this.onLongPress,
    required this.onTap,
    required this.onReply,
    this.onReplyTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragOffset = 0;
  bool _replyFired = false;
  final List<TapGestureRecognizer> _mentionRecognizers = [];

  @override
  void dispose() {
    for (final r in _mentionRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.primaryDelta ?? 0;
    if (delta <= 0) return;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(0.0, 72.0);
    });
    if (_dragOffset >= 64 && !_replyFired) {
      _replyFired = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    setState(() {
      _dragOffset = 0;
      _replyFired = false;
    });
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ][time.weekday - 1];
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.message.type == MessageType.widget
        ? _buildWidgetContent(context)
        : _buildTextContent(context);

    Widget inner;
    if (widget.selectionMode) {
      inner = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Icon(
              widget.isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              size: 22,
            ),
          ),
          Expanded(child: content),
        ],
      );
      if (widget.isSelected) {
        inner = ColoredBox(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
          child: inner,
        );
      }
    } else {
      inner = content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: widget.onLongPress,
      onTap: widget.selectionMode ? widget.onTap : null,
      onHorizontalDragUpdate:
          widget.selectionMode ? null : _onDragUpdate,
      onHorizontalDragEnd:
          widget.selectionMode ? null : _onDragEnd,
      child: Stack(
        children: [
          if (_dragOffset > 4)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: ((_dragOffset - 4) / 60).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.reply,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: AbsorbPointer(
              absorbing: widget.selectionMode,
              child: inner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyQuote(BuildContext context) {
    final container = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message.replyToSenderName ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            widget.message.replyToText ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
    if (widget.onReplyTap != null) {
      return GestureDetector(onTap: widget.onReplyTap, child: container);
    }
    return container;
  }

  Widget _buildMentionedBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alternate_email,
              size: 11, color: Colors.red),
          const SizedBox(width: 4),
          const Text(
            'Du wurdest erwähnt',
            style: TextStyle(
              fontSize: 11,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          UserBadgesRow(
              badges: widget.message.senderBadges, size: 11),
        ],
      ),
    );
  }

  Widget _buildTextWithMentions(BuildContext context, String text) {
    for (final r in _mentionRecognizers) {
      r.dispose();
    }
    _mentionRecognizers.clear();

    final baseStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
    );
    final mentionStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
    final regex = RegExp(r'@[^\s]+');
    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: baseStyle);

    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
            text: text.substring(lastEnd, m.start), style: baseStyle));
      }
      final mentionName = m.group(0)!.substring(1);
      final member = widget.members.firstWhere(
        (mem) => mem.name == mentionName,
        orElse: () => _MemberInfo('', ''),
      );
      TapGestureRecognizer? rec;
      if (member.uid.isNotEmpty) {
        rec = TapGestureRecognizer()
          ..onTap = () => openUserProfile(context, member.uid);
        _mentionRecognizers.add(rec);
      }
      spans.add(TextSpan(
        text: m.group(0)!,
        style: mentionStyle,
        recognizer: rec,
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(
          TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTextContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMentionedSelf =
        widget.message.mentionedUids.contains(currentUid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: widget.isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!widget.isOwnMessage) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isOwnMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!widget.isOwnMessage) ...[
                  GestureDetector(
                    onTap: () =>
                        openUserProfile(context, widget.message.senderId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        UserBadgesRow(
                            badges: widget.message.senderBadges, size: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isHighlighted
                        ? Theme.of(context).colorScheme.primaryContainer
                        : isMentionedSelf
                            ? Colors.red.withValues(alpha: 0.07)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(16).copyWith(
                      bottomLeft: widget.isOwnMessage
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: widget.isOwnMessage
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isMentionedSelf
                        ? Border.all(
                            color: Colors.red.withValues(alpha: 0.35),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMentionedSelf) _buildMentionedBar(context),
                      if (widget.message.replyToId != null)
                        _buildReplyQuote(context),
                      _buildTextWithMentions(
                          context, widget.message.text),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(widget.message.timestamp, l10n),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isOwnMessage) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildWidgetContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.isOwnMessage ? 16 : 4),
      topRight: Radius.circular(widget.isOwnMessage ? 4 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    final bubble = Container(
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.replyToId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: _buildReplyQuote(context),
              ),
            JsWidgetBubble(
              message: widget.message,
              currentUserId: currentUser?.uid ?? '',
              currentUserName: currentUser?.displayName ?? 'Unbekannt',
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: widget.isOwnMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!widget.isOwnMessage) ...[
            Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      openUserProfile(context, widget.message.senderId),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      UserBadgesRow(
                          badges: widget.message.senderBadges, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (widget.isOwnMessage) const SizedBox(height: 2),
          Row(
            mainAxisAlignment: widget.isOwnMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isOwnMessage)
                const SizedBox(width: 40),
              Flexible(child: bubble),
              if (widget.isOwnMessage) ...[
                const SizedBox(width: 8),
                _buildAvatar(context),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 3,
              left: widget.isOwnMessage ? 0 : 44,
              right: widget.isOwnMessage ? 44 : 0,
            ),
            child: Text(
              _formatTime(widget.message.timestamp, l10n),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    Widget avatar;
    if (widget.message.senderProfileImageBase64 != null &&
        widget.message.senderProfileImageBase64!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 16,
        backgroundImage: MemoryImage(
          base64Decode(widget.message.senderProfileImageBase64!),
        ),
      );
    } else if (widget.message.senderProfileImageUrl != null &&
        widget.message.senderProfileImageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 16,
        backgroundImage:
            NetworkImage(widget.message.senderProfileImageUrl!),
      );
    } else {
      avatar = CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
      );
    }
    return GestureDetector(
      onTap: () => openUserProfile(context, widget.message.senderId),
      child: avatar,
    );
  }
}

class _MemberInfo {
  final String uid;
  final String name;
  _MemberInfo(this.uid, this.name);
}
