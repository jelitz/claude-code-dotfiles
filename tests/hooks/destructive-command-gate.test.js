// destructive-command-gate 훅을 실제 프로세스로 실행해 결정을 확인한다.
// 실행: node --test "tests/**/*.test.js"
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const HOOK = path.join(__dirname, '..', '..', 'config', 'scripts', 'hooks', 'destructive-command-gate.js');

// 'deny' | 'ask' | null(결정 없음 — 일반 권한 흐름)
function decide(command, toolName = 'Bash') {
  const run = spawnSync(process.execPath, [HOOK], {
    input: JSON.stringify({ tool_name: toolName, tool_input: { command } }),
    encoding: 'utf8',
    timeout: 10000,
  });
  assert.equal(run.status, 0, `hook exited ${run.status}: ${run.stderr}`);
  const out = run.stdout.trim();
  if (!out) return null;
  return JSON.parse(out).hookSpecificOutput.permissionDecision;
}

// --no-verify 거부
test('git commit --no-verify 는 거부', () => {
  assert.equal(decide('git commit --no-verify -m x'), 'deny');
});
test('git push --no-verify 는 거부', () => {
  assert.equal(decide('git push --no-verify origin master'), 'deny');
});
test('git commit -n (--no-verify 축약) 은 거부', () => {
  assert.equal(decide('git commit -n -m x'), 'deny');
});
test('git commit -nm 묶음 옵션도 거부', () => {
  assert.equal(decide('git commit -nm "msg"'), 'deny');
});
test('git -C 경로 commit -n 도 거부', () => {
  assert.equal(decide('git -C ./repo commit -n -m x'), 'deny');
});
test('bash -c 안의 --no-verify 는 거부', () => {
  assert.equal(decide('bash -c "git push --no-verify"'), 'deny');
});
test('pwsh -Command 안의 --no-verify 는 거부', () => {
  assert.equal(decide('pwsh -Command "git commit --no-verify -m x"', 'PowerShell'), 'deny');
});

// 오탐이던 것: 결정 없음
test('커밋 메시지 안의 --no-verify 글자는 통과', () => {
  assert.equal(decide('git commit -m "fix --no-verify detection"'), null);
});
test('heredoc 메시지 안의 --no-verify 글자는 통과', () => {
  const cmd = "git commit -F - <<'EOF'\nskip git hooks with --no-verify is banned\nEOF";
  assert.equal(decide(cmd), null);
});
test('PowerShell here-string 메시지 안의 --no-verify 글자는 통과', () => {
  const cmd = "git commit -m @'\nskip git hooks with --no-verify is banned\n'@";
  assert.equal(decide(cmd, 'PowerShell'), null);
});
test('git 이 아닌 명령의 --no-verify 는 통과', () => {
  assert.equal(decide('npm run build -- --no-verify'), null);
});
test('git push -n (dry-run) 은 통과', () => {
  assert.equal(decide('git push -n origin master'), null);
});
test('echo 문자열 안의 rm -rf 는 통과', () => {
  assert.equal(decide('echo "rm -rf build"'), null);
});
test('따옴표 안의 ; 로 명령을 나누지 않음', () => {
  assert.equal(decide('git commit -m "a; git push --force"'), null);
});

// 확인(ask) 유지
test('git push -f 는 확인', () => {
  assert.equal(decide('git push -f origin master'), 'ask');
});
test('git push --force 는 확인', () => {
  assert.equal(decide('git push --force origin master'), 'ask');
});
test('rm -rf 는 확인', () => {
  assert.equal(decide('rm -rf build'), 'ask');
});
test('git reset --hard 는 확인', () => {
  assert.equal(decide('git reset --hard HEAD~1'), 'ask');
});
test('Remove-Item -Recurse 는 확인', () => {
  assert.equal(decide('Remove-Item -Recurse -Force build', 'PowerShell'), 'ask');
});
test('bash -c 안의 rm -rf 는 확인', () => {
  assert.equal(decide('bash -c "rm -rf build"'), 'ask');
});
test('따옴표 경로를 지우는 rm -rf 도 확인', () => {
  assert.equal(decide('rm -rf "my build"'), 'ask');
});

// 가리기(masking)가 실제 명령까지 가리지 않는지
test('heredoc 이 끝난 뒤의 rm -rf 는 확인', () => {
  assert.equal(decide("cat <<'EOF' > notes.txt\nhello\nEOF\nrm -rf build"), 'ask');
});
test('heredoc 본문의 작은따옴표가 뒤 명령을 가리지 않음', () => {
  assert.equal(decide("cat <<EOF\ndon't stop\nEOF\ngit push --force origin master"), 'ask');
});
test('CRLF 줄바꿈 heredoc 도 본문만 가림', () => {
  assert.equal(decide("git commit -F - <<'EOF'\r\nuse git --no-verify never\r\nEOF\r\ngit push -f"), 'ask');
});
