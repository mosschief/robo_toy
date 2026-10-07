// The control page served to the phone. Plain HTML/JS, no internet needed.
#pragma once
const char PAGE_HTML[] = R"HTML(<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Tank</title>
<style>
:root{--bg:#1b1e26;--panel:#262a35;--fg:#f2efe9;--muted:#9aa1b2;--orange:#ff9f2e;--blue:#4f8df0;--red:#e5533d}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent;user-select:none}
body{margin:0;background:var(--bg);color:var(--fg);font:16px system-ui,sans-serif;padding:10px;display:grid;gap:10px;max-width:900px;margin-inline:auto}
#top{display:grid;grid-template-columns:1fr auto;gap:10px;align-items:start}
#cam{width:100%;border-radius:12px;background:#000;aspect-ratio:4/3;object-fit:cover}
#info{font:14px ui-monospace,monospace;color:var(--muted);display:grid;gap:4px;min-width:110px}
#info b{color:var(--fg);font-size:18px}
#ctl{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:10px}
@media(max-width:600px){#ctl{grid-template-columns:1fr}#top{grid-template-columns:1fr}#info{grid-auto-flow:column}}
#pad{position:relative;aspect-ratio:1;max-width:280px;width:100%;margin:auto;border-radius:50%;background:var(--panel);touch-action:none;border:3px solid #343a49}
#knob{position:absolute;width:34%;height:34%;left:33%;top:33%;border-radius:50%;background:var(--orange);box-shadow:0 4px 12px #0008}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
button{border:0;border-radius:12px;padding:14px 6px;font:600 16px system-ui;background:var(--panel);color:var(--fg)}
button:active{background:var(--blue)}
button.on{background:var(--orange);color:#111}
h3{margin:4px 0;font-size:13px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
input[type=range]{width:100%}
label{font-size:13px;color:var(--muted)}
</style></head><body>
<div id="top">
  <img id="cam" alt="Tank camera">
  <div id="info">
    <span>distance</span><b id="dist">-</b>
    <span>battery</span><b id="batt">-</b>
    <span>mode</span><b id="mode">-</b>
  </div>
</div>
<div id="ctl">
  <div>
    <div id="pad"><div id="knob"></div></div>
    <div class="grid" style="margin-top:8px">
      <button id="slow" class="on">Slow</button><button id="light">Light</button><button id="guard" class="on">Bumper</button>
    </div>
  </div>
  <div style="display:grid;gap:8px;align-content:start">
    <h3>Face</h3>
    <div class="grid" id="faces"></div>
    <h3>Sounds</h3>
    <div class="grid" id="sounds"></div>
    <h3>Arms</h3>
    <div class="grid" id="poses"></div>
    <h3>Modes</h3>
    <div class="grid" id="modes"></div>
    <h3>Turn body</h3>
    <input type="range" id="waist" min="25" max="155" value="90" style="direction:rtl">
  </div>
</div>
<script>
const $=id=>document.getElementById(id);
const host=location.hostname;
$('cam').src='http://'+host+':81/stream';
function send(c){fetch('/cmd?c='+encodeURIComponent(c)).catch(()=>{});}
function buttons(el,list,cmd){list.forEach((n,i)=>{const b=document.createElement('button');b.textContent=n;b.onclick=()=>send(cmd+' '+i);$(el).appendChild(b);});}
buttons('faces',['Calm','Happy','Sad','Wow','Grr','Sleepy','Love','Dizzy','Wink','Silly'],'F');
buttons('sounds',['Beep','Hello','Yay','Aww','Wow','Uh oh','Dance'],'S');
buttons('poses',['Rest','Arms up','Hug','Point','Ta-da','Wave'],'P');
const MODES=['Play','Explore','Dance','My code','Face test'];
buttons('modes',MODES,'M');
$('waist').oninput=e=>send('J 2 '+e.target.value);
let slow=true,guard=true,light=false;
$('slow').onclick=e=>{slow=!slow;e.target.classList.toggle('on',slow);e.target.textContent=slow?'Slow':'Fast';};
$('guard').onclick=e=>{guard=!guard;e.target.classList.toggle('on',guard);send('G '+(guard?1:0));};
$('light').onclick=e=>{light=!light;e.target.classList.toggle('on',light);fetch('/light?on='+(light?1:0));};
// joystick: up = forward, sideways = turn; mixed into left/right track speeds
const pad=$('pad'),knob=$('knob');let jx=0,jy=0,held=false,timer=null;
function setKnob(){knob.style.left=(33+jx*33)+'%';knob.style.top=(33-jy*33)+'%';}
function drive(){const k=slow?55:100;let l=(jy+jx)*k,r=(jy-jx)*k;const m=Math.max(1,Math.abs(l)/100,Math.abs(r)/100);send('D '+Math.round(l/m)+' '+Math.round(r/m));}
function move(e){const b=pad.getBoundingClientRect();let x=(e.clientX-b.left)/b.width*2-1,y=-((e.clientY-b.top)/b.height*2-1);const d=Math.hypot(x,y);if(d>1){x/=d;y/=d;}jx=x;jy=y;setKnob();}
pad.onpointerdown=e=>{pad.setPointerCapture(e.pointerId);held=true;move(e);drive();timer=setInterval(drive,120);};
pad.onpointermove=e=>{if(held)move(e);};
pad.onpointerup=pad.onpointercancel=()=>{held=false;clearInterval(timer);jx=jy=0;setKnob();send('D 0 0');};
setInterval(()=>fetch('/status').then(r=>r.json()).then(s=>{
  $('dist').textContent=s.dist>=9999?'clear':(s.dist/10).toFixed(0)+' cm';
  $('batt').textContent=s.mv>3000?(s.mv/1000).toFixed(1)+' V':'-';
  $('mode').textContent=s.mode==9?'Sleep':(MODES[s.mode]||'-');
}).catch(()=>{}),700);
</script></body></html>)HTML";
