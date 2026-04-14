# Claude Code 설정 복원 스크립트 (PowerShell)
# 사용법: .\setup.ps1
# Windows PowerShell 7+ (pwsh) 권장

$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$ScriptDir = $PSScriptRoot
$AppDataClaude = "$env:APPDATA\Claude"

Write-Host "=== Claude Code Setup ===" -ForegroundColor Cyan
Write-Host "설정 디렉토리: $ClaudeDir"
Write-Host ""

# ──────────────────────────────────────────────
# 1. 필수 디렉토리 생성
# ──────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\plugins" | Out-Null

# ──────────────────────────────────────────────
# 2. 설정 파일 복사
# ──────────────────────────────────────────────
Write-Host "[1/5] 설정 파일 복사..." -ForegroundColor Yellow

# settings.json
if (Test-Path "$ClaudeDir\settings.json") {
    $answer = Read-Host "  settings.json 이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
    if ($answer -match '^[Yy]$') {
        Copy-Item "$ScriptDir\settings.json" "$ClaudeDir\settings.json" -Force
        Write-Host "  ✓ settings.json 덮어씀" -ForegroundColor Green
    }
} else {
    Copy-Item "$ScriptDir\settings.json" "$ClaudeDir\settings.json"
    Write-Host "  ✓ settings.json 복사 완료" -ForegroundColor Green
}

# settings.local.json (템플릿에서 생성)
if (-not (Test-Path "$ClaudeDir\settings.local.json")) {
    Copy-Item "$ScriptDir\settings.local.json.template" "$ClaudeDir\settings.local.json"
    Write-Host "  ✓ settings.local.json 생성 완료 (템플릿에서)" -ForegroundColor Green
} else {
    Write-Host "  - settings.local.json 은 이미 존재하므로 건너뜀"
}

# CLAUDE.md
if (-not (Test-Path "$ClaudeDir\CLAUDE.md")) {
    Copy-Item "$ScriptDir\CLAUDE.md" "$ClaudeDir\CLAUDE.md"
    Write-Host "  ✓ CLAUDE.md 복사 완료" -ForegroundColor Green
} else {
    Write-Host "  - CLAUDE.md 는 이미 존재하므로 건너뜀"
}

# ──────────────────────────────────────────────
# 3. Claude Desktop MCP 설정 복사
# ──────────────────────────────────────────────
Write-Host "[2/5] MCP 설정 복사..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path $AppDataClaude | Out-Null
$mcpContent = Get-Content "$ScriptDir\mcp\claude_desktop_config.json" -Raw
$mcpContent = $mcpContent -replace 'YOUR_USERNAME', $env:USERNAME
Set-Content "$AppDataClaude\claude_desktop_config.json" $mcpContent -Encoding UTF8
Write-Host "  ✓ claude_desktop_config.json → $AppDataClaude" -ForegroundColor Green

# ──────────────────────────────────────────────
# 4. 커스텀 마켓플레이스 등록
# ──────────────────────────────────────────────
Write-Host "[3/5] 커스텀 마켓플레이스 등록..." -ForegroundColor Yellow

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Host "  ⚠ claude CLI 가 PATH에 없습니다. Claude Code 설치 후 다시 실행하세요." -ForegroundColor Red
    Write-Host "    npm install -g @anthropic-ai/claude-code"
    exit 1
}

$marketplaces = @(
    @{ id = "exa-skills";    arg = "github:benjaminjackson/exa-skills" },
    @{ id = "Claudest";      arg = "github:gupsammy/claudest" },
    @{ id = "openai-codex";  arg = "github:openai/codex-plugin-cc" }
)
foreach ($mp in $marketplaces) {
    try {
        claude plugin marketplace add $mp.id $mp.arg 2>$null
        Write-Host "  ✓ $($mp.id)" -ForegroundColor Green
    } catch {
        Write-Host "  - $($mp.id) (이미 등록됨)"
    }
}

# ──────────────────────────────────────────────
# 5. 플러그인 설치
# ──────────────────────────────────────────────
Write-Host "[4/5] 플러그인 설치..." -ForegroundColor Yellow

$plugins = @(
    "superpowers@claude-plugins-official",
    "context7@claude-plugins-official",
    "frontend-design@claude-plugins-official",
    "pyright-lsp@claude-plugins-official",
    "playwright@claude-plugins-official",
    "exa-core@exa-skills",
    "claude-memory@Claudest"
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
# 5. BMAD Method 설치 (글로벌 Claude Code 스킬)
# ──────────────────────────────────────────────
Write-Host "[5/6] BMAD Method 설치..." -ForegroundColor Yellow

$npxCmd = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npxCmd) {
    Write-Host "  ⚠ npx 가 없습니다. Node.js v20+ 설치 후 다시 실행하세요." -ForegroundColor Red
} else {
    try {
        npx bmad-method install --directory $ClaudeDir --modules bmm --tools claude-code --yes
        Write-Host "  ✓ BMAD Method 설치 완료" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ BMAD Method 설치 실패 — 수동으로 실행: npx bmad-method install" -ForegroundColor Red
    }
}

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] 완료!" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:"
Write-Host "  1. settings.json 의 CLAUDE_CODE_GIT_BASH_PATH 경로 확인"
Write-Host "  2. mcp\claude_desktop_config.json 의 localAgentModeTrustedFolders 경로 확인"
Write-Host "  3. Claude Code 재시작"
