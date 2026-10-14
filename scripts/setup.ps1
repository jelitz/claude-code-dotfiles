# Claude Code 설정 복원 스크립트 (Windows PowerShell)
# 사용법: .\scripts\setup.ps1   (repo 어디서 실행해도 무방)
# Windows PowerShell 7+ (pwsh) 권장

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path $PSScriptRoot -Parent
$ConfigDir = Join-Path $RepoDir "config"
$ClaudeDir = "$env:USERPROFILE\.claude"
$AppDataClaude = "$env:APPDATA\Claude"

Write-Host "=== Claude Code Setup ===" -ForegroundColor Cyan
Write-Host "감지된 OS   : Windows (PowerShell)"
Write-Host "설정 디렉토리: $ClaudeDir"
Write-Host ""

# ──────────────────────────────────────────────
# 1. 필수 디렉토리 생성
# ──────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\plugins" | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\skills" | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\agents" | Out-Null

# ──────────────────────────────────────────────
# 2. 설정 파일 복사 (config\ → ~\.claude\)
# ──────────────────────────────────────────────
Write-Host "[1/5] 설정 파일 복사..." -ForegroundColor Yellow

# settings.json (YOUR_USERNAME → 실제 사용자명 치환)
$settingsContent = Get-Content "$ConfigDir\settings.json" -Raw
$settingsContent = $settingsContent -replace 'YOUR_USERNAME', $env:USERNAME
if (Test-Path "$ClaudeDir\settings.json") {
    $answer = Read-Host "  settings.json 이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
    if ($answer -match '^[Yy]$') {
        Set-Content "$ClaudeDir\settings.json" $settingsContent -Encoding UTF8
        Write-Host "  ✓ settings.json 덮어씀" -ForegroundColor Green
    }
} else {
    Set-Content "$ClaudeDir\settings.json" $settingsContent -Encoding UTF8
    Write-Host "  ✓ settings.json 복사 완료" -ForegroundColor Green
}

# settings.local.json (템플릿에서 생성)
if (-not (Test-Path "$ClaudeDir\settings.local.json")) {
    Copy-Item "$ConfigDir\settings.local.json.template" "$ClaudeDir\settings.local.json"
    Write-Host "  ✓ settings.local.json 생성 완료 (템플릿에서)" -ForegroundColor Green
} else {
    Write-Host "  - settings.local.json 은 이미 존재하므로 건너뜀"
}

# statusline-bash.sh
Copy-Item "$ConfigDir\statusline-bash.sh" "$ClaudeDir\statusline-bash.sh" -Force
Write-Host "  ✓ statusline-bash.sh 복사 완료" -ForegroundColor Green

# CLAUDE.md
if (-not (Test-Path "$ClaudeDir\CLAUDE.md")) {
    Copy-Item "$ConfigDir\CLAUDE.md" "$ClaudeDir\CLAUDE.md"
    Write-Host "  ✓ CLAUDE.md 복사 완료" -ForegroundColor Green
} else {
    Write-Host "  - CLAUDE.md 는 이미 존재하므로 건너뜀"
}

# ──────────────────────────────────────────────
# 3. 사용자 스킬 복사 (config\skills → ~\.claude\skills)
# ──────────────────────────────────────────────
Write-Host "[2/5] 사용자 스킬 복사..." -ForegroundColor Yellow
Copy-Item "$ConfigDir\skills\*" "$ClaudeDir\skills\" -Recurse -Force
Write-Host "  ✓ skills\ → $ClaudeDir\skills (직접 관리 7종 + Aside 1종 + pup 제공 dd-* 11종)" -ForegroundColor Green

# 구 사본 정리 (1회성): dadeumi 는 v2026.10.14 부터 플러그인(dadeumi@dadeumi)으로 설치한다.
# 예전 setup 이 복사해 둔 사본이 남아 있으면 스킬이 두 벌(dadeumi, dadeumi:dadeumi)로 잡히므로 그 경로 하나만 지운다.
if (Test-Path "$ClaudeDir\skills\dadeumi") {
    Remove-Item "$ClaudeDir\skills\dadeumi" -Recurse -Force
    Write-Host "  ✓ 구 사본 삭제: $ClaudeDir\skills\dadeumi (이제 플러그인 dadeumi@dadeumi 로 설치)" -ForegroundColor Green
}

if (Test-Path "$ConfigDir\agents") {
    Copy-Item "$ConfigDir\agents\*" "$ClaudeDir\agents\" -Recurse -Force
    Write-Host "  ✓ agents\ → $ClaudeDir\agents (직접 관리 adversarial-reviewer 1종 + pup 제공 Datadog 도메인 48종)" -ForegroundColor Green
}

# hooks (config\scripts\hooks, config\scripts\lib → ~\.claude\scripts\)
if (Test-Path "$ConfigDir\scripts\hooks") {
    New-Item -ItemType Directory -Force -Path "$ClaudeDir\scripts\hooks" | Out-Null
    New-Item -ItemType Directory -Force -Path "$ClaudeDir\scripts\lib" | Out-Null
    Copy-Item "$ConfigDir\scripts\hooks\*" "$ClaudeDir\scripts\hooks\" -Recurse -Force
    Copy-Item "$ConfigDir\scripts\lib\*" "$ClaudeDir\scripts\lib\" -Recurse -Force
    Write-Host "  ✓ scripts\hooks, scripts\lib → $ClaudeDir\scripts (settings.json의 hooks 절이 이 스크립트를 참조)" -ForegroundColor Green
}

# ──────────────────────────────────────────────
# 4. Claude Desktop 설정 복사 (desktop\ → %APPDATA%\Claude)
# ──────────────────────────────────────────────
Write-Host "[3/5] Claude Desktop 설정 복사..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path $AppDataClaude | Out-Null
$mcpContent = Get-Content "$RepoDir\desktop\claude_desktop_config.json" -Raw
$mcpContent = $mcpContent -replace 'YOUR_USERNAME', $env:USERNAME
Set-Content "$AppDataClaude\claude_desktop_config.json" $mcpContent -Encoding UTF8
Write-Host "  ✓ claude_desktop_config.json → $AppDataClaude" -ForegroundColor Green

# ──────────────────────────────────────────────
# 5. 커스텀 마켓플레이스 등록 + 플러그인 설치
# ──────────────────────────────────────────────
Write-Host "[4/5] 커스텀 마켓플레이스 등록..." -ForegroundColor Yellow

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Host "  ⚠ claude CLI 가 PATH에 없습니다. Claude Code 설치 후 다시 실행하세요." -ForegroundColor Red
    Write-Host "    irm https://claude.ai/install.ps1 | iex"
    exit 1
}

# 실사용 마켓플레이스 — `claude plugin marketplace add <source>` (인자 하나)
# anthropic-plugin-directory 는 내장. claude-plugins-official 은 Claude Code를
# 한 번도 실행하지 않은 상태에서는 등록돼 있지 않으므로 명시적으로 추가한다.
$marketplaces = @(
    "anthropics/claude-plugins-official",
    "anthropics/skills",
    "openai/codex-plugin-cc",
    "https://github.com/fivetaku/gptaku_plugins.git",
    "obra/superpowers-marketplace"
)
# 등록만 해둔 옵션 마켓플레이스 (필요 시 주석 해제)
# $marketplaces += @(
#     "nextlevelbuilder/ui-ux-pro-max-skill",
#     "google-labs-code/stitch-skills",
#     "benjaminjackson/exa-skills",
#     "gupsammy/claudest",
#     "affaan-m/everything-claude-code",
#     "vercel-labs/agent-browser",
#     "anthropics/financial-services"
# )
# 외부 명령은 실패해도 예외를 던지지 않으므로 $LASTEXITCODE 로 판정한다
foreach ($src in $marketplaces) {
    claude plugin marketplace add $src *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $src" -ForegroundColor Green
    } else {
        Write-Host "  - $src (이미 등록됐거나 실패 — claude plugin marketplace list 로 확인)"
    }
}

Write-Host "[5/5] 플러그인 설치..." -ForegroundColor Yellow

# 활성 플러그인만 설치 (비활성 기록은 plugins/installed_plugins.json 참고)
$plugins = @(
    "codex@openai-codex",
    "context7@claude-plugins-official",
    "playwright@claude-plugins-official",
    "document-skills@anthropic-agent-skills",
    "cloudflare@claude-plugins-official",
    "claude-md-management@claude-plugins-official",
    "sentry@claude-plugins-official",
    "typescript-lsp@claude-plugins-official",
    "pyright-lsp@claude-plugins-official",
    "insane-search@gptaku-plugins",
    "firecrawl@anthropic-plugin-directory",
    "superpowers@superpowers-marketplace"
)
foreach ($plugin in $plugins) {
    claude plugin install $plugin *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $plugin" -ForegroundColor Green
    } else {
        Write-Host "  - $plugin (이미 설치됨 또는 오류)"
    }
}

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
Write-Host ""
Write-Host "완료!" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:"
Write-Host "  1. settings.json 의 CLAUDE_CODE_GIT_BASH_PATH 경로 확인 (Git Bash 실제 설치 경로)"
Write-Host "  2. Claude Desktop 의 localAgentModeTrustedFolders 를 실제 작업 폴더로 변경"
Write-Host "  3. Claude Code 재시작"
