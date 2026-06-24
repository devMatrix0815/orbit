import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import 'custom_code_editor.dart';
import 'poll_template.dart';
import 'todo_template.dart';

class WidgetTemplatePicker extends StatelessWidget {
  final String circleId;
  // parentContext stays valid after this bottom sheet closes.
  final BuildContext parentContext;

  const WidgetTemplatePicker({
    super.key,
    required this.circleId,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Widget einfügen',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _Tile(
              icon: Icons.poll_rounded,
              title: 'Umfrage',
              subtitle: 'Alle können abstimmen',
              onTap: () => _createPoll(context),
            ),
            _Tile(
              icon: Icons.checklist_rounded,
              title: 'Todo-Liste',
              subtitle: 'Geteilte Aufgabenliste',
              onTap: () => _createTodo(context),
            ),
            _Tile(
              icon: Icons.code_rounded,
              title: 'Eigener Code',
              subtitle: 'HTML + JavaScript Widget',
              onTap: () => _createCustom(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createPoll(BuildContext context) async {
    // Show dialog BEFORE closing picker — context is still valid here.
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _PollDialog(),
    );
    if (result == null || !context.mounted) return;

    // Capture messenger before popping (ScaffoldMessenger persists across routes).
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    try {
      await ChatService().sendWidgetMessage(
        circleId,
        widgetType: 'poll',
        widgetHtml: PollTemplate.html,
        initialState: PollTemplate.createInitialState(
          question: result['question'] as String,
          options: List<String>.from(result['options']),
        ),
        previewText: '📊 Umfrage: ${result['question']}',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<void> _createTodo(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const _TodoDialog(),
    );
    if (title == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    try {
      await ChatService().sendWidgetMessage(
        circleId,
        widgetType: 'todo',
        widgetHtml: TodoTemplate.html,
        initialState: TodoTemplate.createInitialState(title: title),
        previewText: '✅ Todo-Liste: $title',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<void> _createCustom(BuildContext context) async {
    // Close picker first, then open editor using parentContext (always valid).
    Navigator.pop(context);
    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomCodeEditor(circleId: circleId),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }
}

// --- Poll creation dialog ---

class _PollDialog extends StatefulWidget {
  const _PollDialog();

  @override
  State<_PollDialog> createState() => _PollDialogState();
}

class _PollDialogState extends State<_PollDialog> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _opts = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Umfrage erstellen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                labelText: 'Frage',
                hintText: 'Was ist deine Frage?',
              ),
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            const Text(
              'Optionen',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...List.generate(_opts.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opts[i],
                      decoration: InputDecoration(
                        hintText: 'Option ${i + 1}',
                        isDense: true,
                      ),
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  if (_opts.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => setState(() => _opts.removeAt(i)),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            )),
            if (_opts.length < 6)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _opts.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Option hinzufügen'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final q = _questionCtrl.text.trim();
            final options = _opts
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (q.isEmpty || options.length < 2) return;
            Navigator.pop(context, {'question': q, 'options': options});
          },
          child: const Text('Senden'),
        ),
      ],
    );
  }
}

// --- Todo creation dialog ---

class _TodoDialog extends StatefulWidget {
  const _TodoDialog();

  @override
  State<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<_TodoDialog> {
  final _ctrl = TextEditingController(text: 'Todo-Liste');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Todo-Liste erstellen'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(labelText: 'Titel'),
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final t = _ctrl.text.trim();
            Navigator.pop(context, t.isEmpty ? 'Todo-Liste' : t);
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
