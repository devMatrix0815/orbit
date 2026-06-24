class PollTemplate {
  static Map<String, dynamic> createInitialState({
    required String question,
    required List<String> options,
    bool multipleChoice = false,
  }) {
    return {
      'question': question,
      'options': options
          .map((o) => {'text': o, 'votes': <String>[]})
          .toList(),
      'multipleChoice': multipleChoice,
    };
  }

  // Body content — injected into HtmlSandbox.wrapUserContent().
  // Uses OrbitBridge API which the wrapper injects automatically.
  static const String html = r'''<div id="app"></div>
<script>
function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}

function render(st){
  if(!st)return;
  var opts=st.options||[];
  var me=OrbitBridge.currentUser.uid;
  var total=opts.reduce(function(s,o){return s+(o.votes||[]).length;},0);
  var h='<p style="font-size:14px;font-weight:600;margin-bottom:10px;word-break:break-word">'+esc(st.question||'')+'</p>';
  opts.forEach(function(o,i){
    var v=(o.votes||[]).length;
    var pct=total>0?Math.round(v/total*100):0;
    var mine=(o.votes||[]).indexOf(me)>=0;
    var bg=mine?'rgba(0,0,0,0.08)':'rgba(0,0,0,0.04)';
    var border=mine?'1.5px solid rgba(0,0,0,0.3)':'1.5px solid rgba(0,0,0,0.1)';
    h+='<div onclick="vote('+i+')" style="position:relative;border-radius:8px;padding:8px 12px;margin:4px 0;cursor:pointer;overflow:hidden;background:'+bg+';border:'+border+';transition:opacity .15s">';
    h+='<div style="position:absolute;left:0;top:0;bottom:0;width:'+pct+'%;background:rgba(0,0,0,0.06);pointer-events:none;transition:width .3s"></div>';
    h+='<div style="position:relative;display:flex;justify-content:space-between;align-items:center;gap:8px">';
    h+='<span style="flex:1;word-break:break-word;font-size:13px">'+(mine?'<b>':'')+esc(o.text||'')+(mine?'</b>':'')+'</span>';
    h+='<span style="font-size:11px;color:#888;white-space:nowrap">'+v+' ('+pct+'%)</span>';
    h+='</div></div>';
  });
  h+='<p style="font-size:11px;color:#aaa;margin-top:8px;text-align:right">'+total+' Stimme'+(total!==1?'n':'')+'</p>';
  document.getElementById('app').innerHTML=h;
  OrbitBridge.reportHeight();
}

function vote(i){OrbitBridge.dispatch({action:'vote',optionIndex:i});}

OrbitBridge.onStateUpdate(render);
render(OrbitBridge.getState());
</script>''';
}
