'use strict';

// Living Map structural runner. Loads a bundled web-tree-sitter grammar, parses a
// file, and returns the raw parse tree. Extraction of anchors builds on parseFile;
// this entry only proves and exposes the parse seam plus file enumeration and
// extension-based language detection.

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const Parser = require('web-tree-sitter');

const RUNNER_DIR = __dirname;
const GRAMMAR_DIR = path.join(RUNNER_DIR, 'grammars');
const LANG_DETECT_PATH = path.join(RUNNER_DIR, 'lang-detect.json');

// languageIds that have a bundled tree-sitter grammar. Anything else resolves to
// the floor (file-level) or to a non-grammar tier handled elsewhere.
const GRAMMAR_WASM = {
  c_sharp: 'tree-sitter-c_sharp.wasm',
  typescript: 'tree-sitter-typescript.wasm',
  tsx: 'tree-sitter-tsx.wasm',
  java: 'tree-sitter-java.wasm',
  python: 'tree-sitter-python.wasm',
  javascript: 'tree-sitter-javascript.wasm',
};

let _initPromise = null;
function initParser() {
  if (!_initPromise) {
    _initPromise = Parser.init({
      locateFile: () => path.join(GRAMMAR_DIR, 'tree-sitter.wasm'),
    });
  }
  return _initPromise;
}

const _langCache = {};
async function loadLanguage(languageId) {
  if (_langCache[languageId]) return _langCache[languageId];
  const wasm = GRAMMAR_WASM[languageId];
  if (!wasm) throw new Error(`no bundled grammar for languageId: ${languageId}`);
  const lang = await Parser.Language.load(path.join(GRAMMAR_DIR, wasm));
  _langCache[languageId] = lang;
  return lang;
}

function loadLangDetect() {
  return JSON.parse(fs.readFileSync(LANG_DETECT_PATH, 'utf8'));
}

// Resolve a file to a languageId by extension only. A miss returns 'floor' - no
// content sniffing; an ambiguous extension simply degrades to the file-level floor.
function detectLanguage(file) {
  const map = loadLangDetect();
  const ext = path.extname(file).toLowerCase();
  return map[ext] || 'floor';
}

// Parse a file and return the raw tree. This is the seam extraction builds on:
// tree in, anchors out.
async function parseFile(absFilePath, languageId) {
  await initParser();
  const lang = await loadLanguage(languageId);
  const parser = new Parser();
  parser.setLanguage(lang);
  const source = fs.readFileSync(absFilePath, 'utf8');
  const tree = parser.parse(source);
  return { tree, language: languageId, source };
}

function countNodes(node) {
  let n = 1;
  let errors = 0;
  if (node.type === 'ERROR' || node.isMissing) errors++;
  for (let i = 0; i < node.namedChildCount; i++) {
    const r = countNodes(node.namedChild(i));
    n += r.n;
    errors += r.errors;
  }
  return { n, errors };
}

// True if the first slice of the file contains a NUL byte (the standard binary
// heuristic). The ripgrep walker honors ignore files and skips hidden entries;
// it does not skip binary by content, so the walk filters those out here.
function isBinary(absPath) {
  let fd;
  try {
    fd = fs.openSync(absPath, 'r');
    const buf = Buffer.alloc(8000);
    const bytes = fs.readSync(fd, buf, 0, 8000, 0);
    for (let i = 0; i < bytes; i++) {
      if (buf[i] === 0) return true;
    }
    return false;
  } catch {
    return false;
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

// Enumerate files under dir using ripgrep as the single walk: honors the project's
// own .gitignore/.ignore with or without a .git directory, skips hidden entries,
// applies no craft-authored ignore list. Binary files are filtered out here.
function enumerate(dir) {
  const out = execFileSync('rg', ['--files', '--no-require-git'], {
    cwd: dir,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
  return out
    .split('\n')
    .filter(Boolean)
    .filter((rel) => !isBinary(path.join(dir, rel)));
}

async function cmdParse(argv) {
  const file = argv[0];
  const languageId = argv[1] || detectLanguage(file);
  if (!GRAMMAR_WASM[languageId]) {
    return {
      tier: 'floor',
      reason: languageId === 'floor' ? 'no-grammar-for-extension' : `no-grammar:${languageId}`,
      language: languageId,
      file,
    };
  }
  const { tree } = await parseFile(path.resolve(file), languageId);
  const counts = countNodes(tree.rootNode);
  return {
    ok: true,
    tier: 'grammar',
    language: languageId,
    file,
    rootType: tree.rootNode.type,
    hasError: tree.rootNode.hasError,
    nodeCount: counts.n,
    errorCount: counts.errors,
    span: { startIndex: tree.rootNode.startIndex, endIndex: tree.rootNode.endIndex },
  };
}

function cmdDetect(argv) {
  const file = argv[0];
  return { file, language: detectLanguage(file) };
}

function cmdEnumerate(argv) {
  const dir = path.resolve(argv[0] || '.');
  return { dir, files: enumerate(dir) };
}

// Capability probe: node runs, the runtime wasm loads, a grammar loads.
async function cmdProbe() {
  try {
    await initParser();
    await loadLanguage('c_sharp');
    return { node: true, runtime: 'loaded', testGrammar: 'loaded' };
  } catch (e) {
    return { node: true, runtime: 'failed', error: String((e && e.message) || e) };
  }
}

async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  let result;
  switch (cmd) {
    case 'parse':
      result = await cmdParse(rest);
      break;
    case 'detect':
      result = cmdDetect(rest);
      break;
    case 'enumerate':
      result = cmdEnumerate(rest);
      break;
    case 'probe':
      result = await cmdProbe();
      break;
    default:
      process.stderr.write(`unknown command: ${cmd}\n`);
      process.exit(2);
  }
  process.stdout.write(JSON.stringify(result) + '\n');
}

// Run as a CLI only when invoked directly (not when imported by tests).
if (require.main === module) {
  main().catch((e) => {
    process.stderr.write(`runner error: ${String((e && e.message) || e)}\n`);
    process.exit(1);
  });
}

module.exports = { parseFile, detectLanguage, enumerate, GRAMMAR_WASM };
