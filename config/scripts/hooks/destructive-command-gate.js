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

function hasNoVerify(seg) {
  return /\bgit\b/.test(seg) && /(^|\s)--no-verify\b/.test(seg);
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

function classify(command) {
  let ask = null;
  for (const seg of segments(command)) {
    if (hasNoVerify(seg)) return { decision: 'deny', what: '--no-verify' };
    if (ask) continue;
    if (isForcePush(seg)) ask = 'git push --force';
    else if (isResetHard(seg)) ask = 'git reset --hard';
    else if (isGitClean(seg)) ask = 'git clean -f';
    else if (isRecursiveRm(seg)) ask = 'rm -rf';
    else if (isPowerShellRecursiveRemove(seg)) ask = 'Remove-Item -Recurse';
    else if (isCmdRecursiveRd(seg)) ask = 'rd /s';
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
