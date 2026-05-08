#!/usr/bin/env bash
# Claude Code 설정 복원 스크립트 (Git Bash / WSL / macOS)
# 사용법: bash setup.sh

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Claude Code Setup ==="
echo "설정 디렉토리: $CLAUDE_DIR"
echo ""

# ──────────────────────────────────────────────
# 1. 필수 디렉토리 생성
# ──────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/plugins"

# ──────────────────────────────────────────────
# 2. 설정 파일 복사
# ──────────────────────────────────────────────
echo "[1/5] 설정 파일 복사..."

# settings.json
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "  ⚠ settings.json 이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    sed "s/YOUR_USERNAME/$(whoami)/g" "$SCRIPT_DIR/settings.json" > "$CLAUDE_DIR/settings.json"
    echo "  ✓ settings.json 덮어씀"
  fi
else
  sed "s/YOUR_USERNAME/$(whoami)/g" "$SCRIPT_DIR/settings.json" > "$CLAUDE_DIR/settings.json"
  echo "  ✓ settings.json 복사 완료"
fi

# settings.local.json (템플릿에서 생성)
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
  cp "$SCRIPT_DIR/settings.local.json.template" "$CLAUDE_DIR/settings.local.json"
  echo "  ✓ settings.local.json 생성 완료 (템플릿에서)"
else
  echo "  - settings.local.json 은 이미 존재하므로 건너뜀"
fi

# statusline-bash.sh
cp "$SCRIPT_DIR/statusline-bash.sh" "$CLAUDE_DIR/statusline-bash.sh"
chmod +x "$CLAUDE_DIR/statusline-bash.sh"
echo "  ✓ statusline-bash.sh 복사 완료"

# CLAUDE.md
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "  ✓ CLAUDE.md 복사 완료"
else
  echo "  - CLAUDE.md 는 이미 존재하므로 건너뜀"
fi

# ──────────────────────────────────────────────
# 3. Claude Desktop MCP 설정 복사 (Windows only)
# ──────────────────────────────────────────────
echo "[2/5] MCP 설정 복사..."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WINDIR" ]]; then
  APPDATA_CLAUDE="$APPDATA/Claude"
  mkdir -p "$APPDATA_CLAUDE"
  # YOUR_USERNAME 를 실제 사용자명으로 치환
  USERNAME=$(whoami)
  sed "s/YOUR_USERNAME/$USERNAME/g" "$SCRIPT_DIR/mcp/claude_desktop_config.json" > "$APPDATA_CLAUDE/claude_desktop_config.json"
  echo "  ✓ claude_desktop_config.json → $APPDATA_CLAUDE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  MAC_CONFIG="$HOME/Library/Application Support/Claude"
  mkdir -p "$MAC_CONFIG"
  USERNAME=$(whoami)
  sed "s/YOUR_USERNAME/$USERNAME/g" "$SCRIPT_DIR/mcp/claude_desktop_config.json" > "$MAC_CONFIG/claude_desktop_config.json"
  echo "  ✓ claude_desktop_config.json → $MAC_CONFIG"
else
  echo "  - Linux: claude_desktop_config.json 경로를 직접 지정해주세요"
fi

# ──────────────────────────────────────────────
# 4. 커스텀 마켓플레이스 등록
# ──────────────────────────────────────────────
echo "[3/5] 커스텀 마켓플레이스 등록..."

if ! command -v claude &>/dev/null; then
  echo "  ⚠ claude CLI 가 PATH에 없습니다. 마켓플레이스/플러그인 설치를 건너뜁니다."
  echo "    Claude Code 설치 후 다시 실행하거나, 수동으로 아래 명령어를 실행하세요."
  SKIP_PLUGINS=1
fi

if [ -z "$SKIP_PLUGINS" ]; then
  # 마켓플레이스 (claude-plugins-official 은 기본 등록)
  MARKETPLACES=(
    "anthropic-agent-skills github:anthropics/skills"
    "exa-skills github:benjaminjackson/exa-skills"
    "openai-codex github:openai/codex-plugin-cc"
    "thedotmack github:thedotmack/claude-mem"
    "korean-law-marketplace github:chrisryugj/korean-law-mcp"
    "lazyweb https://github.com/aboul3ata/lazyweb-skill.git"
  )
  for entry in "${MARKETPLACES[@]}"; do
    id="${entry%% *}"
    src="${entry#* }"
    claude plugin marketplace add "$id" "$src" 2>/dev/null && echo "  ✓ $id" || echo "  - $id (이미 등록됨)"
  done

  # ──────────────────────────────────────────────
  # 4. 플러그인 설치
  # ──────────────────────────────────────────────
  echo "[4/5] 플러그인 설치..."

  PLUGINS=(
    "superpowers@claude-plugins-official"
    "context7@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
    "ralph-loop@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
    "playground@claude-plugins-official"
    "codex@openai-codex"
    "exa-core@exa-skills"
    "document-skills@anthropic-agent-skills"
    "claude-mem@thedotmack"
  )

  for plugin in "${PLUGINS[@]}"; do
    claude plugin install "$plugin" 2>/dev/null && echo "  ✓ $plugin" || echo "  - $plugin (이미 설치됨 또는 오류)"
  done
fi

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
echo ""
echo "[5/5] 완료!"
echo ""
echo "다음 단계:"
echo "  1. settings.json 의 CLAUDE_CODE_GIT_BASH_PATH 경로 확인"
echo "  2. mcp/claude_desktop_config.json 의 localAgentModeTrustedFolders 경로 확인"
echo "  3. Claude Code 재시작"
