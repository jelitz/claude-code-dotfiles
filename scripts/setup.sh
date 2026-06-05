#!/usr/bin/env bash
# Claude Code 설정 복원 스크립트 (Git Bash / WSL / macOS / Linux)
# 사용법: bash scripts/setup.sh   (repo 어디서 실행해도 무방)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_DIR/config"
CLAUDE_DIR="$HOME/.claude"

# ──────────────────────────────────────────────
# 0. OS 감지
# ──────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "$WINDIR" ]]; then
    echo "windows"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}
OS="$(detect_os)"

echo "=== Claude Code Setup ==="
echo "감지된 OS   : $OS"
echo "설정 디렉토리: $CLAUDE_DIR"
echo ""

# ──────────────────────────────────────────────
# 1. 필수 디렉토리 생성
# ──────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/plugins" "$CLAUDE_DIR/skills"

# ──────────────────────────────────────────────
# 2. 설정 파일 복사 (config/ → ~/.claude/)
# ──────────────────────────────────────────────
echo "[1/6] 설정 파일 복사..."

# settings.json 렌더링 — OS별 보정
#  - windows : YOUR_USERNAME → 실제 사용자명
#  - 그 외   : statusline 경로를 $HOME 기준으로 치환하고,
#              Windows 전용 env 인 CLAUDE_CODE_GIT_BASH_PATH 줄을 제거
#              (config/settings.json 에서 해당 키는 env 블록의 첫 항목이므로
#               줄 삭제만으로 JSON 이 유효하게 유지됨)
render_settings() {
  local out="$1"
  if [[ "$OS" == "windows" ]]; then
    sed "s/YOUR_USERNAME/$(whoami)/g" "$CONFIG_DIR/settings.json" > "$out"
  else
    sed -e "s|/c/Users/YOUR_USERNAME|$HOME|g" \
        -e "/CLAUDE_CODE_GIT_BASH_PATH/d" \
        "$CONFIG_DIR/settings.json" > "$out"
  fi
}

if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "  ⚠ settings.json 이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    render_settings "$CLAUDE_DIR/settings.json"
    echo "  ✓ settings.json 덮어씀"
  fi
else
  render_settings "$CLAUDE_DIR/settings.json"
  echo "  ✓ settings.json 복사 완료"
fi

# settings.local.json (템플릿에서 생성)
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
  cp "$CONFIG_DIR/settings.local.json.template" "$CLAUDE_DIR/settings.local.json"
  echo "  ✓ settings.local.json 생성 완료 (템플릿에서)"
else
  echo "  - settings.local.json 은 이미 존재하므로 건너뜀"
fi

# statusline-bash.sh
cp "$CONFIG_DIR/statusline-bash.sh" "$CLAUDE_DIR/statusline-bash.sh"
chmod +x "$CLAUDE_DIR/statusline-bash.sh"
echo "  ✓ statusline-bash.sh 복사 완료"

# CLAUDE.md + RTK.md (CLAUDE.md 가 @RTK.md 를 import 하므로 쌍으로 유지)
for doc in CLAUDE.md RTK.md; do
  if [ ! -f "$CLAUDE_DIR/$doc" ]; then
    cp "$CONFIG_DIR/$doc" "$CLAUDE_DIR/$doc"
    echo "  ✓ $doc 복사 완료"
  else
    echo "  - $doc 는 이미 존재하므로 건너뜀"
  fi
done

# ──────────────────────────────────────────────
# 3. 사용자 스킬 복사 (config/skills → ~/.claude/skills)
# ──────────────────────────────────────────────
echo "[2/6] 사용자 스킬 복사..."
cp -r "$CONFIG_DIR/skills/"* "$CLAUDE_DIR/skills/"
echo "  ✓ skills/ → $CLAUDE_DIR/skills (code-search-exa, company-research, web-search-advanced-research-paper)"

# ──────────────────────────────────────────────
# 4. Claude Desktop 설정 복사 (desktop/ → OS별 경로)
# ──────────────────────────────────────────────
echo "[3/6] Claude Desktop 설정 복사..."

copy_desktop_config() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  sed "s/YOUR_USERNAME/$(whoami)/g" "$REPO_DIR/desktop/claude_desktop_config.json" \
    > "$dest_dir/claude_desktop_config.json"
  echo "  ✓ claude_desktop_config.json → $dest_dir"
}

case "$OS" in
  windows) copy_desktop_config "$APPDATA/Claude" ;;
  macos)   copy_desktop_config "$HOME/Library/Application Support/Claude" ;;
  linux)   copy_desktop_config "$HOME/.config/Claude" ;;
  wsl)
    echo "  - WSL: Claude Desktop 은 Windows 호스트에서 실행됩니다."
    echo "    호스트 PowerShell 에서 scripts/setup.ps1 을 실행하거나,"
    echo "    desktop/claude_desktop_config.json 을 %APPDATA%\\Claude\\ 에 직접 복사하세요."
    ;;
esac

# ──────────────────────────────────────────────
# 5. 커스텀 마켓플레이스 등록 + 플러그인 설치
# ──────────────────────────────────────────────
echo "[4/6] 커스텀 마켓플레이스 등록..."

if ! command -v claude &>/dev/null; then
  echo "  ⚠ claude CLI 가 PATH에 없습니다. 마켓플레이스/플러그인 설치를 건너뜁니다."
  echo "    Claude Code 설치 후 다시 실행하거나, README 의 수동 설치 명령을 실행하세요."
  SKIP_PLUGINS=1
fi

if [ -z "$SKIP_PLUGINS" ]; then
  # 실사용 마켓플레이스 (claude-plugins-official 은 기본 등록)
  MARKETPLACES=(
    "anthropic-agent-skills github:anthropics/skills"
    "exa-skills github:benjaminjackson/exa-skills"
    "openai-codex github:openai/codex-plugin-cc"
    "thedotmack github:thedotmack/claude-mem"
    "karpathy-skills github:forrestchang/andrej-karpathy-skills"
    "korean-law-marketplace github:chrisryugj/korean-law-mcp"
    "lazyweb https://github.com/aboul3ata/lazyweb-skill.git"
    "ui-ux-pro-max-skill github:nextlevelbuilder/ui-ux-pro-max-skill"
  )
  # 등록만 해둔 옵션 마켓플레이스 (필요 시 주석 해제)
  # MARKETPLACES+=(
  #   "Claudest github:gupsammy/claudest"
  #   "ecc github:affaan-m/everything-claude-code"
  #   "agent-browser github:vercel-labs/agent-browser"
  #   "claude-for-financial-services github:anthropics/financial-services"
  # )
  for entry in "${MARKETPLACES[@]}"; do
    id="${entry%% *}"
    src="${entry#* }"
    claude plugin marketplace add "$id" "$src" 2>/dev/null && echo "  ✓ $id" || echo "  - $id (이미 등록됨)"
  done

  echo "[5/6] 플러그인 설치..."

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
    "andrej-karpathy-skills@karpathy-skills"
  )

  for plugin in "${PLUGINS[@]}"; do
    claude plugin install "$plugin" 2>/dev/null && echo "  ✓ $plugin" || echo "  - $plugin (이미 설치됨 또는 오류)"
  done
fi

# ──────────────────────────────────────────────
# 6. rtk 확인 (settings.json 의 PreToolUse 훅이 의존)
# ──────────────────────────────────────────────
echo "[6/6] rtk 확인..."

if command -v rtk &>/dev/null; then
  echo "  ✓ rtk $(rtk --version 2>/dev/null | head -1)"
else
  echo "  ⚠ rtk 가 PATH에 없습니다!"
  echo "    settings.json 의 PreToolUse 훅('rtk hook claude')이 rtk 를 호출하므로,"
  echo "    rtk 미설치 상태에서는 모든 Bash·PowerShell 도구 호출 시 훅 오류가 발생합니다."
  echo "    해결 방법 중 하나를 선택하세요:"
  echo "      a) rtk 설치: https://github.com/rtk-ai/rtk (단일 Rust 바이너리, ~/.local/bin 등 PATH 에 배치)"
  echo "      b) ~/.claude/settings.json 에서 hooks.PreToolUse 블록 제거"
fi

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
echo ""
echo "완료!"
echo ""
echo "다음 단계:"
if [[ "$OS" == "windows" ]]; then
  echo "  1. settings.json 의 CLAUDE_CODE_GIT_BASH_PATH 경로 확인 (Git Bash 실제 설치 경로)"
else
  echo "  1. statusline 경로가 \$HOME 기준으로 적용되었는지 확인 (~/.claude/settings.json)"
fi
echo "  2. Claude Desktop 의 localAgentModeTrustedFolders 를 실제 작업 폴더로 변경"
echo "  3. korean-law MCP 사용 시 본인 OC ID 입력 (desktop/claude_desktop_config.json 참고)"
echo "  4. Claude Code 재시작"
