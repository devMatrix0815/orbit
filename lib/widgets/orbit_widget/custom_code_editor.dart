import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

const _example = '''<!-- Beispiel: Emoji-Stimmung -->
<h3>Wie geht es euch?</h3>
<div id="btns" style="display:flex;gap:8px;flex-wrap:wrap;margin:8px 0"></div>
<div id="result" style="font-size:12px;color:#888;margin-top:4px"></div>

<script>
var emojis = ["😊","😐","😔","🤩","😴"];

var btns = document.getElementById("btns");
emojis.forEach(function(e) {
  var b = document.createElement("button");
  b.textContent = e;
  b.style.cssText = "font-size:24px;background:none;border:1.5px solid rgba(0,0,0,0.15);border-radius:8px;padding:4px 10px";
  b.onclick = function() {
    var st = OrbitBridge.getState() || {votes:{}};
    if(!st.votes) st.votes = {};
    st.votes[OrbitBridge.currentUser.uid] = e;
    OrbitBridge.setState(st);
  };
  btns.appendChild(b);
});

OrbitBridge.onStateUpdate(function(st) {
  var counts = {};
  Object.values(st.votes || {}).forEach(function(v){
    counts[v] = (counts[v]||0)+1;
  });
  document.getElementById("result").textContent =
    Object.entries(counts).map(function(e){return e[0]+" "+e[1];}).join("  ") || "Noch keine Stimmen";
  OrbitBridge.reportHeight();
});
</script>''';

class CustomCodeEditor extends StatefulWidget {
  final String circleId;

  const CustomCodeEditor({super.key, required this.circleId});

  @override
  State<CustomCodeEditor> createState() => _CustomCodeEditorState();
}

class _CustomCodeEditorState extends State<CustomCodeEditor> {
  final _ctrl = TextEditingController(text: _example);
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService().sendWidgetMessage(
        widget.circleId,
        widgetType: 'custom',
        widgetHtml: code,
        initialState: {},
        previewText: '🔧 Widget',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eigener Code',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'OrbitBridge API verfügbar — kein <html>/<body> nötig',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Senden'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              'OrbitBridge.getState() · .setState(obj) · .onStateUpdate(fn) · .currentUser.uid · .dispatch({action,…})',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
