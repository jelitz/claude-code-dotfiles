#!/usr/bin/env node
/**
 * Python Encoding Check
 *
 * Cross-platform (Windows, macOS, Linux)
 *
 * PostToolUse hook for Edit / Write. After a `.py` file is written, scans it
 * for text-mode I/O calls that omit `encoding=` and hands Claude a reminder
 * as additionalContext (non-blocking, the edit has already happened).
 *
 * Why a hook: the CLAUDE.md rule "commit code must state encoding='utf-8'"
 * kept leaking (this machine got PYTHONUTF8=1 as a safety net, teammates and
 * CI did not). Best practices: rules that keep getting missed become hooks.
 *
 * Checked calls: builtin open(), io.open(), Path.read_text(), Path.write_text().
 * Skipped: calls whose mode string contains 'b' (binary), calls that already
 * pass encoding=. Everything is heuristic; false negatives are fine, false
 * positives only cost one line of context.
 *
 * Fail-open: any error exits 0 without output.
 */

const fs = require('fs');
const { readStdinJson, output } = require('../lib/utils');

const CALL_RE = /(?<![\w.])open\s*\(|\bio\.open\s*\(|\.read_text\s*\(|\.write_text\s*\(/g;
const MAX_ARG_SPAN = 600;

// Return the text between the opening paren at `start` and its matching close.
function argSpan(src, start) {
  let depth = 0;
  let inStr = null;
  for (let i = start; i < src.length && i - start < MAX_ARG_SPAN; i++) {
    const ch = src[i];
    if (inStr) {
      if (ch === '\\') { i++; continue; }
      if (ch === inStr) inStr = null;
      continue;
    }
    if (ch === '"' || ch === "'") { inStr = ch; continue; }
    if (ch === '#') { // comment to end of line
      while (i < src.length && src[i] !== '\n') i++;
      continue;
    }
    if (ch === '(') depth++;
    else if (ch === ')') {
      depth--;
      if (depth === 0) return src.slice(start + 1, i);
    }
  }
  return src.slice(start + 1, start + MAX_ARG_SPAN);
}

function isBinaryMode(args) {
  // second positional or mode= keyword holding a string with 'b'
  const modeKw = args.match(/\bmode\s*=\s*(['"])([^'"]*)\1/);
  if (modeKw) return modeKw[2].includes('b');
  const parts = args.split(',');
  if (parts.length >= 2) {
    const second = parts[1].trim().match(/^(['"])([^'"]*)\1$/);
    if (second) return second[2].includes('b');
  }
  return false;
}

function lineOf(src, idx) {
  let n = 1;
  for (let i = 0; i < idx; i++) if (src[i] === '\n') n++;
  return n;
}

function findMissing(src) {
  const hits = [];
  let m;
  CALL_RE.lastIndex = 0;
  while ((m = CALL_RE.exec(src)) !== null) {
    const parenIdx = src.indexOf('(', m.index);
    if (parenIdx === -1) break;
    const args = argSpan(src, parenIdx);
    if (/\bencoding\s*=/.test(args)) continue;
    if (isBinaryMode(args)) continue;
    hits.push({ line: lineOf(src, m.index), call: m[0].replace(/\s*\($/, '') });
    if (hits.length >= 10) break;
  }
  return hits;
}

async function main() {
  let input;
  try {
    input = await readStdinJson({ timeoutMs: 3000 });
  } catch {
    process.exit(0);
  }
  if (!input || typeof input !== 'object') process.exit(0);

  const toolInput = (input.tool_input && typeof input.tool_input === 'object') ? input.tool_input : {};
  const filePath = typeof toolInput.file_path === 'string' ? toolInput.file_path : '';
  if (!/\.py$/i.test(filePath)) process.exit(0);

  let src;
  try {
    src = fs.readFileSync(filePath, 'utf8');
  } catch {
    process.exit(0);
  }

  const hits = findMissing(src);
  if (hits.length === 0) process.exit(0);

  const list = hits.map(h => `${h.line}행 ${h.call}(`).join(', ');
  output({
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext:
        `[py-encoding-check] ${filePath}: encoding= 없는 텍스트 I/O 호출 — ${list}. ` +
        '커밋되는 코드는 encoding="utf-8"을 명시할 것(CLAUDE.md Environment: 팀원 PC·CI는 cp949 기본). ' +
        '바이너리 모드거나 의도적 생략이면 무시.'
    }
  });
  process.exit(0);
}

main().catch(() => process.exit(0));
