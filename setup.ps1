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
New-Item -ItemType Directory -Force -Path "$ClaudeDir\skills" | Out-Null

# ──────────────────────────────────────────────
# 2. 설정 파일 복사
# ──────────────────────────────────────────────
Write-Host "[1/6] 설정 파일 복사..." -ForegroundColor Yellow

# settings.json (YOUR_USERNAME → 실제 사용자명 치환)
$settingsContent = Get-Content "$ScriptDir\settings.json" -Raw
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
    Copy-Item "$ScriptDir\settings.local.json.template" "$ClaudeDir\settings.local.json"
    Write-Host "  ✓ settings.local.json 생성 완료 (템플릿에서)" -ForegroundColor Green
} else {
    Write-Host "  - settings.local.json 은 이미 존재하므로 건너뜀"
}

# statusline-bash.sh
Copy-Item "$ScriptDir\statusline-bash.sh" "$ClaudeDir\statusline-bash.sh" -Force
Write-Host "  ✓ statusline-bash.sh 복사 완료" -ForegroundColor Green

# CLAUDE.md + RTK.md (CLAUDE.md 가 @RTK.md 를 import 하므로 쌍으로 유지)
foreach ($doc in @("CLAUDE.md", "RTK.md")) {
    if (-not (Test-Path "$ClaudeDir\$doc")) {
        Copy-Item "$ScriptDir\$doc" "$ClaudeDir\$doc"
        Write-Host "  ✓ $doc 복사 완료" -ForegroundColor Green
    } else {
        Write-Host "  - $doc 는 이미 존재하므로 건너뜀"
    }
}

# ──────────────────────────────────────────────
# 3. 사용자 스킬 복사 (~/.claude/skills)
# ──────────────────────────────────────────────
Write-Host "[2/6] 사용자 스킬 복사..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\skills\*" "$ClaudeDir\skills\" -Recurse -Force
Write-Host "  ✓ skills\ → $ClaudeDir\skills (code-search-exa, company-research, web-search-advanced-research-paper)" -ForegroundColor Green

# ──────────────────────────────────────────────
# 4. Claude Desktop MCP 설정 복사
# ──────────────────────────────────────────────
Write-Host "[3/6] MCP 설정 복사..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path $AppDataClaude | Out-Null
$mcpContent = Get-Content "$ScriptDir\mcp\claude_desktop_config.json" -Raw
$mcpContent = $mcpContent -replace 'YOUR_USERNAME', $env:USERNAME
Set-Content "$AppDataClaude\claude_desktop_config.json" $mcpContent -Encoding UTF8
Write-Host "  ✓ claude_desktop_config.json → $AppDataClaude" -ForegroundColor Green

# ──────────────────────────────────────────────
# 5. 커스텀 마켓플레이스 등록 + 플러그인 설치
# ──────────────────────────────────────────────
Write-Host "[4/6] 커스텀 마켓플레이스 등록..." -ForegroundColor Yellow

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Host "  ⚠ claude CLI 가 PATH에 없습니다. Claude Code 설치 후 다시 실행하세요." -ForegroundColor Red
    Write-Host "    irm https://claude.ai/install.ps1 | iex"
    exit 1
}

# 실사용 마켓플레이스 (claude-plugins-official 은 기본 등록)
$marketplaces = @(
    @{ id = "anthropic-agent-skills"; arg = "github:anthropics/skills" },
    @{ id = "exa-skills";             arg = "github:benjaminjackson/exa-skills" },
    @{ id = "openai-codex";           arg = "github:openai/codex-plugin-cc" },
    @{ id = "thedotmack";             arg = "github:thedotmack/claude-mem" },
    @{ id = "karpathy-skills";        arg = "github:forrestchang/andrej-karpathy-skills" },
    @{ id = "korean-law-marketplace"; arg = "github:chrisryugj/korean-law-mcp" },
    @{ id = "lazyweb";                arg = "https://github.com/aboul3ata/lazyweb-skill.git" },
    @{ id = "ui-ux-pro-max-skill";    arg = "github:nextlevelbuilder/ui-ux-pro-max-skill" }
)
# 등록만 해둔 옵션 마켓플레이스 (필요 시 주석 해제)
# $marketplaces += @(
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

Write-Host "[5/6] 플러그인 설치..." -ForegroundColor Yellow

$plugins = @(
    "superpowers@claude-plugins-official",
    "context7@claude-plugins-official",
    "pyright-lsp@claude-plugins-official",
    "ralph-loop@claude-plugins-official",
    "claude-code-setup@claude-plugins-official",
    "playground@claude-plugins-official",
    "codex@openai-codex",
    "exa-core@exa-skills",
    "document-skills@anthropic-agent-skills",
    "claude-mem@thedotmack",
    "andrej-karpathy-skills@karpathy-skills"
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
# 6. rtk 확인 (settings.json 의 PreToolUse 훅이 의존)
# ──────────────────────────────────────────────
Write-Host "[6/6] rtk 확인..." -ForegroundColor Yellow

$rtkCmd = Get-Command rtk -ErrorAction SilentlyContinue
if ($rtkCmd) {
    Write-Host "  ✓ $(rtk --version 2>$null)" -ForegroundColor Green
} else {
    Write-Host "  ⚠ rtk 가 PATH에 없습니다!" -ForegroundColor Red
    Write-Host "    settings.json 의 PreToolUse 훅('rtk hook claude')이 rtk 를 호출하므로,"
    Write-Host "    rtk 미설치 상태에서는 모든 Bash 도구 호출 시 훅 오류가 발생합니다."
    Write-Host "    해결 방법 중 하나를 선택하세요:"
    Write-Host "      a) rtk 설치: https://github.com/rtk-ai/rtk (단일 Rust 바이너리, PATH에 배치)"
    Write-Host "      b) ~/.claude/settings.json 에서 hooks.PreToolUse 블록 제거"
}

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
Write-Host ""
Write-Host "완료!" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:"
Write-Host "  1. settings.json 의 CLAUDE_CODE_GIT_BASH_PATH 경로 확인"
Write-Host "  2. Claude Desktop 의 localAgentModeTrustedFolders 를 실제 작업 폴더로 변경"
Write-Host "  3. korean-law MCP 사용 시 본인 OC ID 입력 (mcp\claude_desktop_config.json 참고)"
Write-Host "  4. Claude Code 재시작"
