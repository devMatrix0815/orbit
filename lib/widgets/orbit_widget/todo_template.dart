class TodoTemplate {
  static Map<String, dynamic> createInitialState({String title = 'Todo-Liste'}) {
    return {'title': title, 'items': <Map<String, dynamic>>[]};
  }

  // Body content — injected into HtmlSandbox.wrapUserContent().
  static const String html = r'''<div id="app"></div>
<script>
function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}

function render(st){
  if(!st)return;
  var items=st.items||[];
  var h='<p style="font-size:14px;font-weight:600;margin-bottom:8px">'+esc(st.title||'Liste')+'</p>';
  h+='<div style="display:flex;gap:6px;margin-bottom:8px">';
  h+='<input id="ni" type="text" placeholder="Neuer Eintrag..." maxlength="200" onkeydown="if(event.key===\'Enter\')add()" style="flex:1;padding:6px 10px;border:1.5px solid rgba(0,0,0,0.15);border-radius:8px;font-size:13px;outline:none;min-width:0;background:transparent;color:inherit">';
  h+='<button onclick="add()" style="padding:6px 14px;background:rgba(0,0,0,0.8);color:#fff;border:none;border-radius:8px;font-size:15px;font-weight:700;flex-shrink:0">+</button>';
  h+='</div>';
  items.forEach(function(it,i){
    var done=it.done===true;
    h+='<div style="display:flex;align-items:center;gap:8px;padding:5px 0;border-bottom:1px solid rgba(0,0,0,0.06)">';
    h+='<input type="checkbox" id="cb'+i+'"'+(done?' checked':'')+' onchange="toggle('+i+')" style="width:16px;height:16px;cursor:pointer;flex-shrink:0;accent-color:rgba(0,0,0,0.7)">';
    h+='<label for="cb'+i+'" style="flex:1;font-size:13px;cursor:pointer;word-break:break-word'+(done?';text-decoration:line-through;color:#aaa':'')+'">'+esc(it.text||'')+'</label>';
    h+='</div>';
  });
  document.getElementById('app').innerHTML=h;
  OrbitBridge.reportHeight();
}

function add(){
  var el=document.getElementById('ni');
  if(!el)return;
  var t=el.value.trim();
  if(!t)return;
  OrbitBridge.dispatch({action:'addItem',text:t});
  el.value='';
}

function toggle(i){OrbitBridge.dispatch({action:'toggleItem',index:i});}

OrbitBridge.onStateUpdate(render);
render(OrbitBridge.getState());
</script>''';
}
