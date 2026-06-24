import 'dart:convert';

class HtmlSandbox {
  // Outer wrapper: loaded by Flutter WebView. User HTML lives inside a
  // sandboxed <iframe> — no network, no parent DOM access, no storage.
  static String generateWrapper({
    required String userHtml,
    required Map<String, dynamic> state,
  }) {
    final stateJson = jsonEncode(state);
    final escaped = _escapeSrcdoc(userHtml);
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; frame-src blob: data:;">
<style>*{box-sizing:border-box}html,body{margin:0;padding:0;background:transparent;overflow:hidden}#sb{width:100%;border:none;display:block;min-height:60px}</style>
</head>
<body>
<iframe id="sb" sandbox="allow-scripts" srcdoc="$escaped" scrolling="no"></iframe>
<script>
(function(){
  var st=$stateJson;
  var sb=document.getElementById('sb');
  window.addEventListener('message',function(e){
    var m=e.data;if(!m||typeof m!=='object')return;
    if(m.type==='orbitResize'){
      var h=Math.max(60,parseInt(m.height)||100);
      sb.style.height=h+'px';
      OrbitResize.postMessage(String(h));
    }else if(m.type==='orbitAction'){
      if(m.payload&&typeof m.payload==='object')
        OrbitAction.postMessage(JSON.stringify(m.payload));
    }else if(m.type==='orbitGetState'){
      if(sb.contentWindow)sb.contentWindow.postMessage({type:'orbitStateData',state:st},'*');
    }
  });
  sb.addEventListener('load',function(){
    if(sb.contentWindow)sb.contentWindow.postMessage({type:'orbitStateData',state:st},'*');
  });
})();
</script>
</body>
</html>''';
  }

  // Wraps user body content with the OrbitBridge API.
  // Blocks all network APIs; injects currentUser for JS code to use.
  static String wrapUserContent({
    required String userContent,
    required bool isDark,
    required String currentUserId,
    required String currentUserName,
  }) {
    final bg = isDark ? '#1e1e2e' : '#ffffff';
    final fg = isDark ? '#cdd6f4' : '#1a1a2e';
    final safeId = _escJs(currentUserId);
    final safeName = _escJs(currentUserName);
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>*{box-sizing:border-box;margin:0;padding:0}body{padding:10px;background:$bg;color:$fg;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;font-size:14px}button{cursor:pointer}</style>
<script>
var OrbitBridge=(function(){
  var _s=null,_l=[];
  window.addEventListener('message',function(e){
    if(!e.data||e.data.type!=='orbitStateData')return;
    _s=e.data.state;
    _l.forEach(function(cb){try{cb(e.data.state);}catch(x){}});
  });
  window.parent.postMessage({type:'orbitGetState'},'*');
  function rh(){
    var h=Math.max(document.body.scrollHeight,document.documentElement.scrollHeight);
    window.parent.postMessage({type:'orbitResize',height:h},'*');
  }
  setTimeout(rh,100);
  window.addEventListener('load',function(){setTimeout(rh,60);});
  return{
    getState:function(){return _s;},
    setState:function(s){window.parent.postMessage({type:'orbitAction',payload:{action:'setState',state:s}},'*');},
    dispatch:function(a){window.parent.postMessage({type:'orbitAction',payload:a},'*');},
    onStateUpdate:function(cb){_l.push(cb);},
    reportHeight:rh,
    currentUser:{uid:'$safeId',name:'$safeName'}
  };
})();
try{delete window.localStorage;}catch(e){}
try{delete window.sessionStorage;}catch(e){}
try{delete window.XMLHttpRequest;}catch(e){}
try{delete window.fetch;}catch(e){}
try{delete window.WebSocket;}catch(e){}
</script>
</head>
<body>
$userContent
</body>
</html>''';
  }

  // & and " must be escaped for the srcdoc attribute value.
  static String _escapeSrcdoc(String html) =>
      html.replaceAll('&', '&amp;').replaceAll('"', '&quot;');

  static String _escJs(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');
}
