import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import 'html_sandbox.dart';

class JsWidgetBubble extends StatefulWidget {
  final ChatMessage message;
  final String currentUserId;
  final String currentUserName;

  const JsWidgetBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<JsWidgetBubble> createState() => _JsWidgetBubbleState();
}

class _JsWidgetBubbleState extends State<JsWidgetBubble> {
  late final WebViewController _controller;
  double _height = 60;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // Block all external navigation — only our local data load is allowed.
        onNavigationRequest: (request) {
          final url = request.url;
          if (url == 'about:blank' || url.startsWith('data:')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..addJavaScriptChannel(
        'OrbitResize',
        onMessageReceived: (msg) {
          if (!mounted) return;
          final h = double.tryParse(msg.message) ?? 60.0;
          setState(() => _height = h.clamp(60.0, double.infinity));
        },
      )
      ..addJavaScriptChannel(
        'OrbitAction',
        onMessageReceived: (msg) {
          try {
            final action = jsonDecode(msg.message) as Map<String, dynamic>;
            _handleAction(action);
          } catch (_) {}
        },
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _controller.loadHtmlString(_buildHtml(isDark));
    }
  }

  @override
  void didUpdateWidget(JsWidgetBubble old) {
    super.didUpdateWidget(old);
    // Push new Firestore state into the running WebView without reloading.
    if (old.message.widgetState != widget.message.widgetState) {
      _pushState(widget.message.widgetState ?? {});
    }
  }

  void _pushState(Map<String, dynamic> state) {
    final json = jsonEncode(state);
    _controller.runJavaScript('''
(function(){
  var sb=document.getElementById('sb');
  if(sb&&sb.contentWindow)sb.contentWindow.postMessage({type:'orbitStateData',state:$json},'*');
})();
''');
  }

  String _buildHtml(bool isDark) {
    final inner = HtmlSandbox.wrapUserContent(
      userContent: widget.message.widgetHtml ?? '',
      isDark: isDark,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
    );
    return HtmlSandbox.generateWrapper(
      userHtml: inner,
      state: widget.message.widgetState ?? {},
    );
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    try {
      await ChatService().updateWidgetState(
        widget.message.circleId,
        widget.message.id,
        widget.message.widgetType ?? 'custom',
        action,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(
          key: ValueKey(widget.message.id),
          controller: _controller,
        ),
      ),
    );
  }
}
