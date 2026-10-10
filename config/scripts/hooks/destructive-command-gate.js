#!/usr/bin/env node
/**
 * Destructive Command Gate
 *
 * Cross-platform (Windows, macOS, Linux)
 *
 * PreToolUse hook for Bash / PowerShell. Turns two advisory CLAUDE.md rules
 * into a deterministic gate (Claude Code best practices: "if Claude already
 * does it without the rule, delete the rule or convert it into a hook"):
 *
 *   deny  - `--no-verify` on any git command. Safety bypass is never allowed;
 *           the reason is shown to Claude so it fixes the failing hook instead.
 *   ask   - rm -rf (and PowerShell Remove-Item -Recurse, cmd rd /s),
 *           git push --force / --force-with-lease / +refspec,
 *           git reset --hard, git clean -f.
 *           "ask" forces a confirmation prompt even in auto mode (hooks docs,
 *           Claude Code >= 2.1.211): the classifier can still deny, but it can
 *           no longer approve silently. The reason is shown to the user.
 *
 * Text the shell does not run as a command is masked before matching: quoted
 * strings, heredoc bodies and PowerShell here-strings. A commit message that
 * mentions --no-verify or rm -rf is therefore not a match. The payload of
 * `bash -c "..."` / `pwsh -Command "..."` is a command, so it is checked again.
 *
 * Fail-open by design: any unexpected error exits 0 with no output, so a
 * broken hook never blocks ordinary commands. Exit 0 with no output means
 * "no decision" and the normal permission flow continues.
 */

const { readStdinJson, output } = require('../lib/utils');

// Split on shell separators so flags from one command don't leak into another.
const SEGMENT_SPLIT_RE = /\s*(?:&&|\|\||[;|]|\n)\s*/;

function segments(command) {
  return command.split(SEGMENT_SPLIT_RE).map(s => s.trim()).filter(Boolean);
}

// Same length as the input; masked characters (newlines included) become spaces.
function maskQuoted(command) {
  const out = command.split('');
  const blank = (from, to) => { for (let k = from; k < to; k++) out[k] = ' '; };
  const heredocs = []; // { bodyStart, resume } in source order
  let i = 0;
  while (i < command.length) {
    if (heredocs.length && i === heredocs[0].bodyStart) {
      const h = heredocs.shift();
      blank(h.bodyStart, h.bodyEnd);
      i = h.resume;
      continue;
    }
    const rest = command.slice(i);
    // PowerShell here-string: @'<newline> ... <newline>'@
    let m = rest.match(/^@(['"])\r?\n/);
    if (m) {
      const close = command.indexOf('\n' + m[1] + '@', i + 2);
      const end = close === -1 ? command.length : close + 1;
      blank(i + 2, end);
      i = end;
      continue;
    }
    // heredoc: <<EOF, <<-EOF, <<'EOF', <<"EOF" — the body starts on the next line
    m = rest.match(/^<<(-?)\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\2/);
    if (m) {
      const lineEnd = command.indexOf('\n', i);
      if (lineEnd !== -1) {
        const delim = new RegExp('\\n' + (m[1] ? '\\t*' : '') + m[3] + '[ \\t]*\\r?(?=\\n|$)');
        const d = command.slice(lineEnd).match(delim);
        const bodyEnd = d ? lineEnd + d.index : command.length;
        heredocs.push({ bodyStart: lineEnd, bodyEnd, resume: bodyEnd });
      }
      i += m[0].length;
      continue;
    }
    const c = command[i];
    if (c === "'") {
      const close = command.indexOf("'", i + 1);
      const end = close === -1 ? command.length : close;
      blank(i + 1, end);
      i = end + 1;
      continue;
    }
    if (c === '"') {
      // \ (bash) and ` (PowerShell) escape the next character
      let j = i + 1;
      while (j < command.length && command[j] !== '"') j += (command[j] === '\\' || command[j] === '`') ? 2 : 1;
      blank(i + 1, Math.min(j, command.length));
      i = j + 1;
      continue;
    }
    i += 1;
  }
  return out.join('');
}

// `bash -c "..."`, `pwsh -NoProfile -Command '...'`: the quoted payload is a command.
const SHELL_PAYLOAD_RE = /(^|[\s;&|(])(?:bash|sh|zsh|dash|pwsh|powershell)(?:\.exe)?\s+(?:-[A-Za-z]+\s+)*?(?:-c|-Command|-command)\s+("(?:[^"\\`]|[\\`][\s\S])*"|'[^']*')/g;

function shellPayloads(command, masked) {
  const payloads = [];
  for (const m of command.matchAll(SHELL_PAYLOAD_RE)) {
    const start = m.index + m[1].length;
    if (masked[start] !== command[start]) continue; // the shell word itself is quoted text
    const quoted = m[2];
    const body = quoted.slice(1, -1);
    payloads.push(quoted[0] === '"' ? body.replace(/[\\`](["\\`$])/g, '$1') : body);
  }
  return payloads;
}

// Subcommands that accept --no-verify (commit also takes -n for it).
const NO_VERIFY_SUBCOMMANDS = new Set(['commit', 'push', 'merge', 'rebase', 'am', 'cherry-pick', 'revert', 'pull']);
const GIT_OPTIONS_WITH_VALUE = new Set(['-C', '-c', '--git-dir', '--work-tree', '--namespace']);

function gitInvocation(seg) {
  const tokens = seg.split(/\s+/).filter(Boolean);
  const g = tokens.findIndex(t => /(^|[\\/])git(\.exe)?$/i.test(t));
  if (g === -1) return null;
  let k = g + 1;
  while (k < tokens.length && tokens[k].startsWith('-')) {
    if (GIT_OPTIONS_WITH_VALUE.has(tokens[k])) k += 1;
    k += 1;
  }
  return k < tokens.length ? { sub: tokens[k], args: tokens.slice(k + 1) } : null;
}

function hasNoVerify(seg) {
  const git = gitInvocation(seg);
  if (!git || !NO_VERIFY_SUBCOMMANDS.has(git.sub)) return false;
  if (git.args.includes('--no-verify')) return true;
  return git.sub === 'commit' && git.args.some(a => /^-[A-Za-z]*n[A-Za-z]*$/.test(a));
}

function isForcePush(seg) {
  if (!/\bgit\s+push\b/.test(seg)) return false;
  return /(^|\s)(-f|--force|--force-with-lease(=\S*)?|--force-if-includes)\b/.test(seg)
    || /\s\+\S+/.test(seg); // git push origin +main
}

function isResetHard(seg) {
  return /\bgit\s+reset\b/.test(seg) && /(^|\s)--hard\b/.test(seg);
}

function isGitClean(seg) {
  return /\bgit\s+clean\b/.test(seg) && /(^|\s)(-[a-zA-Z]*f[a-zA-Z]*|--force)\b/.test(seg);
}

// rm -rf, rm -fr, rm -r -f, rm -Rf, rm --recursive --force, PowerShell rm -r -fo
function isRecursiveRm(seg) {
  const m = seg.match(/(^|[\s(`])(rm|ri|del)\s+(.*)$/);
  if (!m) return false;
  const flags = m[3].split(/\s+/).filter(t => t.startsWith('-'));
  const joined = flags.join(' ');
  const recursive = /(^|\s)-[a-zA-Z]*[rR][a-zA-Z]*(\s|$)/.test(joined) || /--recursive\b/.test(joined) || /-Recurse\b/i.test(joined);
  const force = /(^|\s)-[a-zA-Z]*f[a-zA-Z]*(\s|$)/.test(joined) || /--force\b/.test(joined) || /-Force\b/i.test(joined);
  return recursive && force;
}

function isPowerShellRecursiveRemove(seg) {
  return /\bRemove-Item\b/i.test(seg) && /(^|\s)-Recurse\b/i.test(seg);
}

function isCmdRecursiveRd(seg) {
  return /(^|\s)(rd|rmdir)\s+.*\/[sS](\s|$)/.test(seg);
}

function classify(command, depth = 0) {
  const masked = maskQuoted(command);
  let ask = null;
  for (const seg of segments(masked)) {
    if (hasNoVerify(seg)) return { decision: 'deny', what: '--no-verify' };
    if (ask) continue;
    if (isForcePush(seg)) ask = 'git push --force';
    else if (isResetHard(seg)) ask = 'git reset --hard';
    else if (isGitClean(seg)) ask = 'git clean -f';
    else if (isRecursiveRm(seg)) ask = 'rm -rf';
    else if (isPowerShellRecursiveRemove(seg)) ask = 'Remove-Item -Recurse';
    else if (isCmdRecursiveRd(seg)) ask = 'rd /s';
  }
  if (depth < 3) {
    for (const payload of shellPayloads(command, masked)) {
      const inner = classify(payload, depth + 1);
      if (inner && inner.decision === 'deny') return inner;
      if (inner && !ask) ask = inner.what;
    }
  }
  return ask ? { decision: 'ask', what: ask } : null;
}

async function main() {
  let input;
  try {
    input = await readStdinJson({ timeoutMs: 3000 });
  } catch {
    process.exit(0);
  }
  if (!input || typeof input !== 'object') process.exit(0);

  const toolName = typeof input.tool_name === 'string' ? input.tool_name : '';
  if (toolName !== 'Bash' && toolName !== 'PowerShell') process.exit(0);

  const toolInput = (input.tool_input && typeof input.tool_input === 'object') ? input.tool_input : {};
  const command = typeof toolInput.command === 'string' ? toolInput.command : '';
  if (!command) process.exit(0);

  const result = classify(command);
  if (!result) process.exit(0);

  if (result.decision === 'deny') {
    output({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason:
          '[destructive-command-gate] --no-verify 차단: 훅·안전장치 우회 금지(CLAUDE.md). ' +
          '실패한 훅의 원인을 고친 뒤 --no-verify 없이 다시 실행할 것.'
      }
    });
    process.exit(0);
  }

  output({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason:
        `[destructive-command-gate] 되돌리기 어려운 명령 감지 (${result.what}). 실행을 승인하시겠습니까?`
    }
  });
  process.exit(0);
}

main().catch(() => process.exit(0));
