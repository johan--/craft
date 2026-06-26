'use strict';

// Assemble one area (one directory) into a slice. Enumerates that directory's own
// files, serves each from the content-hash cache or re-extracts it, ranks the
// definitions, trims to the token budget, and renders the locked indented outline.
// Writes the .craft/map/ index, which is the source of truth for anchor keys.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const { enumerate } = require('./index.js');
const { extract } = require('./extract.js');
const { rankDefinitions } = require('./rank.js');
const { trimToBudget, estimateTokens } = require('./budget-trim.js');

const DEFAULT_BUDGET = 4096;

function mapDir(root) {
  return path.join(root, '.craft', 'map');
}

function indexPath(root) {
  return path.join(mapDir(root), 'index.json');
}

function readIndex(root) {
  try {
    return JSON.parse(fs.readFileSync(indexPath(root), 'utf8'));
  } catch {
    return { version: 1, areas: {} };
  }
}

function writeIndex(root, index) {
  fs.mkdirSync(mapDir(root), { recursive: true });
  fs.writeFileSync(indexPath(root), JSON.stringify(index, null, 2) + '\n');
}

function headSha(root) {
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

// Token budget: map.token_budget from .craft/settings.yaml if present, else default.
function getBudget(root) {
  try {
    const text = fs.readFileSync(path.join(root, '.craft', 'settings.yaml'), 'utf8');
    const m = text.match(/token_budget:\s*(\d+)/);
    if (m) return parseInt(m[1], 10);
  } catch {
    /* no settings file */
  }
  return DEFAULT_BUDGET;
}

function sepForTier(tier) {
  return tier === 'markdown' ? '/' : '.';
}

function splitSegments(symbolPath, sep) {
  let overload = '';
  const p = symbolPath.indexOf('(');
  if (p !== -1) {
    overload = symbolPath.slice(p);
    symbolPath = symbolPath.slice(0, p);
  }
  const segs = symbolPath.length ? symbolPath.split(sep) : [];
  if (segs.length) segs[segs.length - 1] += overload;
  return segs;
}

// Render the locked indented outline: file header, then definitions nested by scope
// (indent encodes the anchor), source order within a file, 100-char line truncation.
function renderSlice(defs, fileMeta) {
  const byFile = new Map();
  defs.forEach((d, i) => {
    if (!byFile.has(d.rel)) byFile.set(d.rel, { defs: [], firstRank: i });
    byFile.get(d.rel).defs.push(d);
  });
  const files = [...byFile.entries()].sort((a, b) => a[1].firstRank - b[1].firstRank);

  const lines = [];
  for (const [rel, grp] of files) {
    const meta = fileMeta.get(rel) || { tier: 'grammar' };
    const sep = sepForTier(meta.tier);
    lines.push(rel);
    const tree = new Map();
    const sourceOrder = grp.defs.slice().sort((a, b) => a.line - b.line);
    for (const d of sourceOrder) {
      const symbolPath = d.anchor.slice(d.anchor.indexOf('#') + 1);
      let node = tree;
      for (const seg of splitSegments(symbolPath, sep)) {
        if (!node.has(seg)) node.set(seg, { children: new Map() });
        node = node.get(seg).children;
      }
    }
    (function walk(node, depth) {
      for (const [seg, info] of node) {
        let line = '  '.repeat(depth + 1) + seg;
        if (line.length > 100) line = line.slice(0, 100);
        lines.push(line);
        walk(info.children, depth + 1);
      }
    })(tree, 0);
  }
  return lines.length ? lines.join('\n') + '\n' : '';
}

// area-key = one directory relpath. Returns that directory's own files only - no
// parent/child expansion, never a full-repo index.
async function assembleArea(areaKey, root) {
  root = root || process.cwd();
  const absDir = path.resolve(root, areaKey);
  const index = readIndex(root);
  const prev = (index.areas && index.areas[areaKey]) || { files: {} };

  let files = [];
  try {
    files = enumerate(absDir).filter((f) => !f.includes('/')); // direct children only
  } catch {
    files = [];
  }

  const perFile = [];
  const rederived = [];
  const cached = [];
  const newFiles = {};
  for (const f of files) {
    const abs = path.join(absDir, f);
    const rel = path.relative(root, abs).split(path.sep).join('/');
    const buf = fs.readFileSync(abs);
    const hash = crypto.createHash('sha256').update(buf).digest('hex');
    const stored = prev.files[rel];
    let result;
    if (stored && stored.hash === hash) {
      result = { file: rel, tier: stored.tier, language: stored.language, floored: stored.floored, anchors: stored.anchors };
      cached.push(rel);
    } else {
      result = await extract(abs, root);
      rederived.push(rel);
    }
    perFile.push({ rel, source: buf.toString('utf8'), result, hash });
    newFiles[rel] = { hash, tier: result.tier, language: result.language, floored: result.floored, anchors: result.anchors };
  }

  const ranked = rankDefinitions(perFile);
  const fileMeta = new Map(perFile.map((f) => [f.rel, { tier: f.result.tier, language: f.result.language }]));
  const budget = getBudget(root);
  const included = trimToBudget(ranked, (subset) => renderSlice(subset, fileMeta), budget);
  const slice = renderSlice(included, fileMeta);

  index.version = 1;
  index.areas = index.areas || {};
  index.areas[areaKey] = { headSha: headSha(root), files: newFiles };
  writeIndex(root, index);

  return {
    area: areaKey,
    fileCount: files.length,
    budget,
    tokenEstimate: estimateTokens(slice),
    rederived,
    cached,
    slice,
  };
}

module.exports = { assembleArea, renderSlice, getBudget };
