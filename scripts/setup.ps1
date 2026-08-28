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
Write-Host "  ✓ skills\ → $ClaudeDir\skills (직접 관리 10종 + pup 제공 dd-* 11종)" -ForegroundColor Green

if (Test-Path "$ConfigDir\agents") {
    Copy-Item "$ConfigDir\agents\*" "$ClaudeDir\agents\" -Recurse -Force
    Write-Host "  ✓ agents\ → $ClaudeDir\agents (pup 제공 Datadog 도메인 서브에이전트 48종)" -ForegroundColor Green
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

# 실사용 마켓플레이스 (claude-plugins-official 은 기본 등록)
$marketplaces = @(
    @{ id = "anthropic-agent-skills"; arg = "github:anthropics/skills" },
    @{ id = "openai-codex";           arg = "github:openai/codex-plugin-cc" },
    @{ id = "gptaku-plugins";         arg = "https://github.com/fivetaku/gptaku_plugins.git" },
    @{ id = "ui-ux-pro-max-skill";    arg = "github:nextlevelbuilder/ui-ux-pro-max-skill" }
)
# 등록만 해둔 옵션 마켓플레이스 (필요 시 주석 해제)
# $marketplaces += @(
#     @{ id = "exa-skills";                    arg = "github:benjaminjackson/exa-skills" },
#     @{ id = "Claudest";                      arg = "github:gupsammy/claudest" },
#     @{ id = "ecc";                           arg = "github:affaan-m/everything-claude-code" },
#     @{ id = "agent-browser";                 arg = "github:vercel-labs/agent-browser" },
#     @{ id = "claude-for-financial-services"; arg = "github:anthropics/financial-services" }
# )
foreach ($mp in $marketplaces) {
    try {
        claude plugin marketplace add $mp.id $mp.arg 2>$null
        Write-Host "  ✓ $($mp.id)" -ForegroundColor Green
    } catch {
        Write-Host "  - $($mp.id) (이미 등록됨)"
    }
}

Write-Host "[5/5] 플러그인 설치..." -ForegroundColor Yellow

$plugins = @(
    "codex@openai-codex",
    "context7@claude-plugins-official",
    "playwright@claude-plugins-official",
    "document-skills@anthropic-agent-skills",
    "example-skills@anthropic-agent-skills",
    "cloudflare@claude-plugins-official",
    "security-guidance@claude-plugins-official",
    "code-simplifier@claude-plugins-official",
    "pr-review-toolkit@claude-plugins-official",
    "claude-md-management@claude-plugins-official",
    "insane-search@gptaku-plugins"
)
foreach ($plugin in $plugins) {
    try {
        claude plugin install $plugin 2>$null
        Write-Host "  ✓ $plugin" -ForegroundColor Green
    } catch {
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
