"""Render the research decision report as a self-contained HTML page (pip install markdown)."""
from pathlib import Path
import os
import re
import html
from urllib.parse import quote
import markdown

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'idea-discovery/RESEARCH_DIRECTIONS_新能源切换连续潮流_CN.md'
OUTPUT = SOURCE.with_suffix('.html')
text = SOURCE.read_text()
# Resolve original machine-specific links against this checkout on any machine.
def relative(match):
    path = match[1]
    marker = '/paper-writing/'
    if marker not in path:
        raise ValueError(f'Unmapped local link: {path}')
    target = ROOT / path.split(marker, 1)[1]
    if not target.exists():
        raise FileNotFoundError(target)
    return '(' + quote(os.path.relpath(target, OUTPUT.parent), safe='/') + ')'
text = re.sub(r'\(<?(/[^)>]+)>?\)', relative, text)
md = markdown.Markdown(extensions=['tables', 'fenced_code', 'toc'], extension_configs={'toc': {'toc_depth': '2-3'}})
body = md.convert(text)
body = re.sub(r'<h1>.*?</h1>', '', body, count=1)
body = body.replace('<table>', '<div class="table-wrap" tabindex="0" role="region" aria-label="可横向滚动的数据表格"><table>').replace('</table>', '</table></div>')
# Stable chapter anchors for the overview links and current-section tracking.
body = re.sub(r'<h2 id="[^"]*">(\d+)\.', lambda m: f'<h2 id="chapter-{m[1]}">{m[1]}.', body)
toc = ''.join(f'<a href="#chapter-{n}"><span>0{n}</span>{label}</a>' for n,label in enumerate(['一页速览','输入与证据边界','文献局限性矩阵','方向一 · 危险组合搜索','方向二 · LVRT 预警诊断','两方向的差异与取舍','需要确认的事项','证据与附件']))
css = '''
:root{--bg:#f4f5f1;--paper:#fff;--ink:#192e36;--muted:#61727a;--accent:#087e83;--line:#dfe6e6;--nav:260px}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:32px}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.85 -apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif}a{color:var(--accent);text-underline-offset:3px;overflow-wrap:anywhere}a:focus-visible,button:focus-visible,[tabindex]:focus-visible{outline:3px solid #eea646;outline-offset:3px}.progress{position:fixed;top:0;left:0;height:3px;background:var(--accent);z-index:10;width:0}aside{position:fixed;inset:0 auto 0 0;width:var(--nav);padding:35px 23px;background:#102d35;color:#eaf2f3;overflow:auto}.brand{font-size:13px;letter-spacing:2px;color:#7dc7c8}.nav-title{font-size:23px;font-weight:700;margin:18px 0 30px;line-height:1.5}nav a{display:block;text-decoration:none;color:#bccfd3;font-size:13px;padding:11px 9px;border-radius:6px;margin:3px 0}nav a span{display:inline-block;width:28px;font-size:11px;opacity:.65}nav a:hover,nav a.active{background:#25464e;color:white}.nav-note{font-size:12px;color:#9cb4b9;margin-top:38px}main{margin-left:var(--nav);max-width:1600px;padding:48px 5vw 80px}.eyebrow{color:var(--accent);font-size:12px;font-weight:700;letter-spacing:2px}.hero h1{font-size:clamp(30px,3.7vw,52px);letter-spacing:-1.5px;line-height:1.3;margin:15px 0}.hero p{color:var(--muted);max-width:750px}.meta{display:flex;gap:9px;flex-wrap:wrap;margin:24px 0}.meta span{border:1px solid #cad9d8;border-radius:30px;padding:4px 13px;font-size:12px}.actions{display:flex;gap:12px;align-items:center;margin:20px 0 28px}button,.source{font:inherit;font-size:13px;padding:8px 16px;border:1px solid var(--line);border-radius:6px;background:white;cursor:pointer;text-decoration:none}.cards{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:30px 0}.card{padding:25px;border:1px solid var(--line);border-top:4px solid var(--accent);border-radius:10px;background:white;text-decoration:none;color:var(--ink)}.card:last-child{border-top-color:#b27b3d}.card small{color:var(--accent);font-weight:700;letter-spacing:1px}.card h2{font-size:23px;margin:12px 0}.card p{font-size:14px;color:var(--muted);margin:8px 0}.card strong{font-size:13px}.recommend{background:#e3eeeb;border-left:4px solid var(--accent);padding:17px 23px;margin-bottom:35px;font-size:14px}article{background:var(--paper);border:1px solid var(--line);border-radius:12px;padding:32px clamp(20px,3vw,50px);min-width:0}article h2{font-size:27px;line-height:1.5;margin:60px 0 24px;padding:18px 0;border-top:1px solid var(--line)}article h3{font-size:19px;margin:36px 0 18px;line-height:1.6}article p,article li{font-size:15px}article li{margin:9px 0}article blockquote{margin:16px 0;padding:4px 20px;border-left:3px solid #a7c8c7;color:var(--muted);background:#f7faf9}article strong{color:#174f58}.table-wrap{overflow-x:auto;margin:22px 0;border:1px solid var(--line);border-radius:7px}table{border-collapse:collapse;width:100%;min-width:700px;font-size:13px;line-height:1.75}th{background:#edf3f2;color:#234a50;text-align:left;font-weight:650}th,td{padding:14px 16px;border-bottom:1px solid var(--line);vertical-align:top;min-width:130px}tr:last-child td{border-bottom:0}tbody tr:nth-child(even){background:#fafbf9}td:first-child{font-weight:550}table a{word-break:normal}code{background:#eef2f2;border-radius:3px;padding:2px 5px;font-size:.87em;overflow-wrap:anywhere}footer{color:var(--muted);font-size:12px;margin-top:25px}.mobile-nav{display:none}body.compact td,body.compact th{padding:8px 12px}body.compact article p,body.compact article li{font-size:14px}@media(min-width:1800px){main{margin-right:auto}}@media(max-width:1000px){:root{--nav:210px}aside{padding:28px 15px}main{padding:30px 24px}.cards{gap:12px}.card{padding:18px}}@media(max-width:760px){aside{position:static;width:auto;padding:20px}.nav-title{font-size:18px;margin:7px 0}nav{display:flex;overflow:auto;gap:6px}nav a{white-space:nowrap;padding:6px}.nav-note{display:none}main{margin:0;padding:25px 14px}.cards{grid-template-columns:1fr}.hero h1{font-size:32px}article{padding:18px}article h2{font-size:23px}.meta{gap:6px}}@media print{aside,.progress,.actions,.cards{display:none}main{margin:0;padding:0;max-width:none}body{background:white;font-size:10pt}article{border:0;padding:0}.hero h1{font-size:26pt}article h2{break-after:avoid;margin-top:25px}article h3{break-after:avoid}.table-wrap{overflow:visible;border:0}table{min-width:0;font-size:8pt;table-layout:fixed}th,td{min-width:0;padding:5px;overflow-wrap:anywhere}tr{break-inside:avoid}a{color:inherit}footer{margin-top:15px}}
'''
js = '''
const bar=document.querySelector('.progress');
function progress(){const d=document.documentElement;bar.style.width=(d.scrollHeight>d.clientHeight?100*d.scrollTop/(d.scrollHeight-d.clientHeight):100)+'%'}
window.addEventListener('scroll',progress,{passive:true});progress();
const sections=[...document.querySelectorAll('article h2')];
const links=[...document.querySelectorAll('nav a')];
function active(){let current=sections[0];for(const h of sections){if(h.getBoundingClientRect().top<160)current=h}links.forEach(a=>{const on=a.hash==='#'+current.id;a.classList.toggle('active',on);if(on)a.setAttribute('aria-current','location');else a.removeAttribute('aria-current')})}
window.addEventListener('scroll',active,{passive:true});active();
document.querySelector('#print').addEventListener('click',()=>window.print());
document.querySelector('#density').addEventListener('click',e=>{const on=document.body.classList.toggle('compact');e.target.setAttribute('aria-pressed',on);e.target.textContent=on?'切换宽松排版':'切换紧凑排版'});
'''
OUTPUT.write_text(f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>新能源切换连续潮流 · 研究方向建议</title><meta name="description" content="基于26篇论文已核验证据的两条独立研究路线，含基础方案、深化方案、验证设计与决策依据。"><style>{css}</style></head>
<body><div class="progress" aria-hidden="true"></div><aside><div class="brand">RESEARCH / DECISION BRIEF</div><div class="nav-title">新能源切换<br>连续潮流研究</div><nav aria-label="章节目录">{toc}</nav><div class="nav-note">26 篇纳入文献 · 2 条独立路线<br>证据 → 问题 → 方法 → 验证<br><br>研究建议，不代表已完成的实验结论。</div></aside>
<main><header class="hero"><div class="eyebrow">研究方向决策报告 · 2026.10.11</div><h1>从控制切换出发，<br>寻找下一步研究方向。</h1><p>面向多新能源场站独立出力变化，将文献证据转化为可比较、可验证的研究路线。两条方向均包含基础方案与深化方案。</p><div class="meta"><span>26 篇纳入文献</span><span>2 条独立方向</span><span>基础目标 30 天</span><span>复用既有 CPF 内核</span></div><div class="actions"><button id="print" type="button">打印 / 保存 PDF</button><button id="density" type="button" aria-pressed="false">切换紧凑排版</button><a class="source" href="{quote(SOURCE.name)}">Markdown 原文</a></div></header>
<div class="cards"><a class="card" href="#chapter-3"><small>方向 01 · 搜索方法</small><h2>用有限计算发现危险组合</h2><p>让低裕度、事件变化与全域探索共同决定计算预算，再研究遗漏风险与代理误差。</p><strong>基础：预算分配 → 深化：独立审计与误差校准 ↗</strong></a><a class="card" href="#chapter-4"><small>方向 02 · 诊断与机理</small><h2>识别单站预警的适用边界</h2><p>用多场站配对工况检验 LVRT 阈值预警，再研究切换循环与主导事件替换。</p><strong>基础：配对诊断 → 深化：局部返回映射 ↗</strong></a></div>
<div class="recommend"><strong>建议优先：方向一基础方案。</strong> 更贴合外层独立出力搜索与 30 天目标；若已有动态模型能稳定复现多场站进出切换，且侧重机理解释，可优先考虑方向二。</div>
<article aria-label="完整研究报告">{body}</article><footer>HTML 阅读版保留原报告完整正文。论文与附件使用相对路径，请与仓库目录一同保存；点击引用打开文件，物理页码以正文标注为准。页面无需外部字体、脚本或网络资源。</footer></main><script>{js}</script></body></html>''')
print(OUTPUT)
