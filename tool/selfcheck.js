#!/usr/bin/env node
/**
 * 本地自检（无需 Flutter/Dart）
 * 用法：node tool/selfcheck.js
 *
 * 检查项：
 *  1. pubspec.yaml 可被解析
 *  2. 所有 `package:xxx/` import 都在 pubspec 里声明（防 uri_does_not_exist）
 *  3. pubspec 声明的 assets 路径都真实存在
 *  4. 所有 .json 资源可被解析
 *  5. 所有 .dart 文件括号 / 引号配对
 *  6. app_icon.png 头部合法
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
let failed = 0;
const fail = (m) => { failed++; console.log('  ❌ ' + m); };
const ok = (m) => console.log('  ✅ ' + m);

function loadYaml() {
  for (const p of ['js-yaml', '/tmp/node_modules/js-yaml', '/usr/lib/node_modules/js-yaml']) {
    try { return require(p); } catch (_) { /* next */ }
  }
  return null;
}

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (['.dart_tool', 'build', 'node_modules', '.git'].includes(e.name)) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else out.push(p);
  }
  return out;
}

console.log('\n=== ToolBox 本地自检 ===\n');

// ---------- 1. pubspec ----------
console.log('[1] pubspec.yaml');
const yaml = loadYaml();
if (!yaml) { fail('未找到 js-yaml，跳过 YAML 解析'); }
const pubspecRaw = fs.readFileSync(path.join(ROOT, 'pubspec.yaml'), 'utf8');
let pubspec = null;
if (yaml) {
  try { pubspec = yaml.load(pubspecRaw); ok('YAML 解析通过'); }
  catch (e) { fail('YAML 解析失败: ' + e.message); }
}

// ---------- 2. 依赖 vs import ----------
console.log('\n[2] 依赖 / import 对应关系');
const selfName = (pubspec && pubspec.name) || '';
const deps = new Set([
  ...Object.keys((pubspec && pubspec.dependencies) || {}),
  ...Object.keys((pubspec && pubspec.dev_dependencies) || {}),
]);
const dartFiles = walk(path.join(ROOT, 'lib')).filter((f) => f.endsWith('.dart'));
const testFiles = fs.existsSync(path.join(ROOT, 'test'))
  ? walk(path.join(ROOT, 'test')).filter((f) => f.endsWith('.dart'))
  : [];
const used = new Map();
for (const f of [...dartFiles, ...testFiles]) {
  const src = fs.readFileSync(f, 'utf8');
  const re = /^\s*import\s+['"]package:([a-z0-9_]+)\//gm;
  let m;
  while ((m = re.exec(src))) {
    if (!used.has(m[1])) used.set(m[1], path.relative(ROOT, f));
  }
}
for (const [pkg, where] of used) {
  if (pkg === selfName) ok(`${pkg} 是项目自身包名（${where}）`);
  else if (deps.has(pkg)) ok(`${pkg} 已声明（${where}）`);
  else fail(`${pkg} 被 import 但 pubspec 未声明 —— ${where}`);
}
if (used.size === 0) ok('暂无 package: 依赖引用');

// ---------- 2b. 跳文件符号引用（是否漏 import） ----------
console.log('\n[2b] 跳文件符号引用');
{
  // 本工程所有顶层声明都顶格书写，因此只匹配行首（非空白缩进）的声明
  const declPatterns = [
    /^class[ \t]+([A-Za-z_]\w*)/gm,
    /^enum[ \t]+([A-Za-z_]\w*)/gm,
    /^mixin[ \t]+([A-Za-z_]\w*)/gm,
    /^extension[ \t]+([A-Za-z_]\w*)/gm,
    /^typedef[ \t]+([A-Za-z_]\w*)/gm,
    /^(?:abstract[ \t]+)?class[ \t]+([A-Za-z_]\w*)/gm,
    /^const[ \t]+(?:[A-Za-z_][\w<>,?\[\].]*[ \t]+)?([A-Za-z_]\w*)[ \t]*=/gm,
    /^final[ \t]+(?:[A-Za-z_][\w<>,?\[\].]*[ \t]+)?([A-Za-z_]\w*)[ \t]*=/gm,
    /^[A-Za-z_][\w<>,?\[\].]*[ \t]+([A-Za-z_]\w*)[ \t]*\(/gm,
  ];

  // 去掉注释与字符串，避免字符串里的同名文字造成误报
  function stripNoise(src) {
    let out = '';
    let i = 0;
    let st = 'code';
    while (i < src.length) {
      const c = src[i], n = src[i + 1];
      if (st === 'code') {
        if (c === '/' && n === '/') { st = 'line'; i += 2; continue; }
        if (c === '/' && n === '*') { st = 'block'; i += 2; continue; }
        if (c === "'" || c === '"') { st = c === "'" ? 'sq' : 'dq'; i++; out += ' '; continue; }
        out += c; i++; continue;
      }
      if (st === 'line') { if (c === '\n') { st = 'code'; out += '\n'; } i++; continue; }
      if (st === 'block') { if (c === '*' && n === '/') { st = 'code'; i += 2; } else i++; continue; }
      if (st === 'sq' || st === 'dq') {
        const q = st === 'sq' ? "'" : '"';
        if (c === '\\') { i += 2; continue; }
        if (c === q) { st = 'code'; i++; }
        i++; continue;
      }
      i++;
    }
    return out;
  }

  const selfPkg = selfName;
  const symbolOf = new Map();
  const fileInfo = new Map();

  for (const f of [...dartFiles, ...testFiles]) {
    const rawSrc = fs.readFileSync(f, 'utf8');
    const src = stripNoise(rawSrc);
    const defs = new Set();
    for (const re of declPatterns) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(src))) {
        if (!m[1].startsWith('_')) defs.add(m[1]);
      }
    }
    // import 路径必须从「未去噪」的原文里取（字符串里才是路径）
    const imports = new Set();
    const impRe = /^import[ \t]+['"]([^'"]+)['"]/gm;
    let im;
    while ((im = impRe.exec(rawSrc))) {
      const spec = im[1];
      if (spec.startsWith('dart:')) continue;
      if (spec.startsWith('package:')) {
        if (selfPkg && spec.startsWith('package:' + selfPkg + '/')) {
          imports.add(path.join(ROOT, 'lib', spec.slice(selfPkg.length + 9)));
        }
        continue;
      }
      // Dart 的相对路径可以不带 ./ 前缀（如 'core/constants.dart'）
      imports.add(path.resolve(path.dirname(f), spec));
    }
    fileInfo.set(f, { src, imports, defs });
    for (const d of defs) {
      if (!symbolOf.has(d)) symbolOf.set(d, f);
    }
  }

  let crossIssues = 0;
  for (const [f, info] of fileInfo) {
    const body = info.src.replace(/^import[ \t]+.*$/gm, '');
    for (const [sym, owner] of symbolOf) {
      if (owner === f) continue;
      if (info.defs.has(sym)) continue;
      if (!new RegExp('\\b' + sym + '\\b').test(body)) continue;
      if (info.imports.has(owner)) continue;
      fail(`${path.relative(ROOT, f)} 用了 ${sym}，但未 import ${path.relative(ROOT, owner)}`);
      crossIssues++;
    }
  }
  if (crossIssues === 0) {
    ok(`${symbolOf.size} 个顶层符号，跳文件引用全部有对应 import`);
  }
}

// ---------- 3. assets 存在性 ----------
console.log('\n[3] assets 路径');
const assets = (pubspec && pubspec.flutter && pubspec.flutter.assets) || [];
for (const a of assets) {
  const p = path.join(ROOT, a);
  if (fs.existsSync(p)) ok(a + ' 存在');
  else fail(a + ' 不存在');
}

// ---------- 4. JSON 可解析 ----------
console.log('\n[4] JSON 资源');
const jsonFiles = walk(ROOT).filter((f) => f.endsWith('.json') && !f.includes('node_modules'));
for (const f of jsonFiles) {
  try { JSON.parse(fs.readFileSync(f, 'utf8')); ok(path.relative(ROOT, f)); }
  catch (e) { fail(path.relative(ROOT, f) + ' 解析失败: ' + e.message); }
}

// ---------- 4b. YAML 文件（含 GitHub Actions） ----------
console.log('\n[4b] YAML 文件');
if (yaml) {
  const ymlFiles = walk(ROOT).filter((f) => /\.(ya?ml)$/.test(f) && !f.includes('node_modules'));
  for (const f of ymlFiles) {
    try { yaml.load(fs.readFileSync(f, 'utf8')); ok(path.relative(ROOT, f)); }
    catch (e) { fail(path.relative(ROOT, f) + ' 解析失败: ' + e.message); }
  }
  // workflow 额外检查：是否声明了 permissions
  const wf = path.join(ROOT, '.github/workflows/ios.yml');
  if (fs.existsSync(wf)) {
    const src = fs.readFileSync(wf, 'utf8');
    if (src.includes('contents: write')) ok('workflow 已声明 contents: write');
    else fail('workflow 缺少 permissions: contents: write');
    if (src.includes('CODE_SIGNING_ALLOWED=NO')) ok('workflow 已关闭签名');
    else fail('workflow 缺少 CODE_SIGNING_ALLOWED=NO');
  }
} else {
  ok('（无 js-yaml，跳过）');
}

// ---------- 5. Dart 配对 ----------
console.log('\n[5] Dart 括号 / 引号配对');
const PAIRS = { ')': '(', ']': '[', '}': '{' };
for (const f of [...dartFiles, ...testFiles]) {
  const src = fs.readFileSync(f, 'utf8');
  const stack = [];
  let i = 0, line = 1, bad = null;
  let st = 'code';
  while (i < src.length) {
    const c = src[i], n = src[i + 1];
    if (c === '\n') line++;
    if (st === 'code') {
      if (c === '/' && n === '/') { st = 'line'; i += 2; continue; }
      if (c === '/' && n === '*') { st = 'block'; i += 2; continue; }
      if (c === "'") { st = 'sq'; i++; continue; }
      if (c === '"') { st = 'dq'; i++; continue; }
      if (c === 'r' && (n === "'" || n === '"')) { st = n === "'" ? 'rawsq' : 'rawdq'; i += 2; continue; }
      if ('([{'.includes(c)) stack.push([c, line]);
      else if (')]}'.includes(c)) {
        const top = stack.pop();
        if (!top || top[0] !== PAIRS[c]) { bad = `第 ${line} 行 多余的 '${c}'`; break; }
      }
      i++; continue;
    }
    if (st === 'line') { if (c === '\n') st = 'code'; i++; continue; }
    if (st === 'block') { if (c === '*' && n === '/') { st = 'code'; i += 2; continue; } i++; continue; }
    if (st === 'sq' || st === 'dq') {
      const q = st === 'sq' ? "'" : '"';
      if (c === '\\') { i += 2; continue; }
      if (c === q) { st = 'code'; i++; continue; }
      i++; continue;
    }
    if (st === 'rawsq' || st === 'rawdq') {
      const q = st === 'rawsq' ? "'" : '"';
      if (c === q) { st = 'code'; i++; continue; }
      i++; continue;
    }
  }
  const rel = path.relative(ROOT, f);
  if (bad) fail(`${rel}: ${bad}`);
  else if (stack.length) fail(`${rel}: 未闭合的 '${stack[stack.length - 1][0]}'（第 ${stack[stack.length - 1][1]} 行）`);
  else if (st !== 'code' && st !== 'line') fail(`${rel}: 字符串/注释未闭合（状态 ${st}）`);
  else ok(rel);
}

// ---------- 6. 图标（不入库，由 workflow 现场生成） ----------
console.log('\n[6] 图标生成（workflow 内置脚本）');
{
  const localIcon = path.join(ROOT, 'assets/icon/app_icon.png');
  if (fs.existsSync(localIcon)) {
    fail('assets/icon/app_icon.png 不应存在（已改为 CI 生成，且已在 .gitignore 中）');
  } else {
    ok('本地无图标文件（符合预期）');
  }

  const wfPath = path.join(ROOT, '.github/workflows/ios.yml');
  let script = null;
  if (yaml && fs.existsSync(wfPath)) {
    const wf = yaml.load(fs.readFileSync(wfPath, 'utf8'));
    const steps = (wf && wf.jobs && wf.jobs['build-ios'] && wf.jobs['build-ios'].steps) || [];
    for (const s of steps) {
      if (typeof s.run === 'string' && s.run.includes("<<'NODE_SCRIPT'")) {
        const m = s.run.match(/<<'NODE_SCRIPT'\n([\s\S]*?)\n\s*NODE_SCRIPT/);
        if (m) script = m[1];
      }
    }
  }

  if (!script) {
    fail('未在 workflow 中找到内联的图标生成脚本');
  } else {
    ok(`已从 workflow 提取生成脚本（${script.split('\n').length} 行）`);
    try {
      new Function(script);
      ok('脚本语法合法');
    } catch (e) {
      fail('脚本语法错误: ' + e.message);
      script = null;
    }
  }

  // 真的跑一遍，验证能产出合法 PNG
  if (script) {
    const tmpScript = path.join(ROOT, 'tool', '.icon_gen_tmp.js');
    const tmpOut = path.join(ROOT, 'tool', '.icon_out_tmp.png');
    try {
      fs.writeFileSync(tmpScript, script);
      const { execFileSync } = require('child_process');
      execFileSync(process.execPath, [tmpScript, tmpOut], { stdio: 'pipe' });

      const b = fs.readFileSync(tmpOut);
      const sigOk = b.slice(0, 8).toString('hex') === '89504e470d0a1a0a';
      const w = b.readUInt32BE(16), h = b.readUInt32BE(20);
      if (sigOk && w === 1024 && h === 1024 && b[24] === 8 && b[25] === 6) {
        ok(`试跑成功：${w}x${h} 8bit RGBA，${b.length} bytes`);
      } else {
        fail('生成的 PNG 不合法或尺寸不对');
      }
    } catch (e) {
      fail('试跑图标脚本失败: ' + (e.stderr ? e.stderr.toString() : e.message));
    } finally {
      for (const f of [tmpScript, tmpOut]) {
        try { if (fs.existsSync(f)) fs.unlinkSync(f); } catch (_) { /* ignore */ }
      }
    }
  }

  // pubspec 里的图标路径必须与 workflow 生成路径一致
  if (pubspec && pubspec.flutter_launcher_icons) {
    const declared = pubspec.flutter_launcher_icons.image_path;
    if (declared === 'assets/icon/app_icon.png') {
      ok('flutter_launcher_icons.image_path 与 workflow 生成路径一致');
    } else {
      fail(`image_path=${declared} 与 workflow 生成的 assets/icon/app_icon.png 不一致`);
    }
  } else {
    fail('pubspec.yaml 缺少 flutter_launcher_icons 配置');
  }
}

console.log('\n' + (failed === 0 ? '🎉 全部通过' : `⚠️  ${failed} 项未通过`) + '\n');
process.exit(failed === 0 ? 0 : 1);
