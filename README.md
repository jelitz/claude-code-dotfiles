# claude-code-setup

jsmoon의 Claude Code 설정 백업 레포.  
새 환경에서 Claude Code를 설치하거나 기존 설정을 복원할 때 사용합니다.

---

## 파일 구조

```
claude-code-setup/
├── settings.json                    # 메인 설정 → ~/.claude/settings.json
├── settings.local.json.template     # 로컬 권한 설정 템플릿
├── CLAUDE.md                        # 전역 AI 지시사항 → ~/.claude/CLAUDE.md
├── plugins/
│   ├── installed_plugins.json       # 설치된 플러그인 목록 (설명 포함)
│   └── known_marketplaces.json      # 등록된 마켓플레이스 목록
├── mcp/
│   └── claude_desktop_config.json   # MCP 서버 설정 (Claude Desktop용)
├── setup.sh                         # 복원 스크립트 (Git Bash / macOS)
└── setup.ps1                        # 복원 스크립트 (PowerShell)
```

---

## 빠른 설치

### 전제 조건

```bash
# Node.js 설치 확인
node --version   # v18 이상 권장

# Claude Code CLI 설치
npm install -g @anthropic-ai/claude-code
```

### Git Bash (Windows) / macOS / Linux

```bash
git clone https://github.com/jelly35/claude-code-setup.git
cd claude-code-setup
bash setup.sh
```

### PowerShell (Windows)

```powershell
git clone https://github.com/jelly35/claude-code-setup.git
cd claude-code-setup
.\setup.ps1
```

스크립트가 자동으로:
1. `settings.json` → `~/.claude/settings.json` 복사
2. `CLAUDE.md` → `~/.claude/CLAUDE.md` 복사
3. `mcp/claude_desktop_config.json` → `%APPDATA%\Claude\` 복사
4. 커스텀 마켓플레이스 등록
5. 플러그인 설치

---

## 설치되는 플러그인

| 플러그인 | 마켓플레이스 | 설명 |
|---|---|---|
| `superpowers` | claude-plugins-official | 브레인스토밍·플래닝·TDD·디버깅 스킬 모음 (BMAD 포함) |
| `context7` | claude-plugins-official | 라이브러리 최신 문서 실시간 조회 |
| `frontend-design` | claude-plugins-official | 고품질 프론트엔드 UI 생성 |
| `pyright-lsp` | claude-plugins-official | Python 타입 체크 / LSP 지원 |
| `playwright` | claude-plugins-official | 브라우저 자동화 (MCP 기반) |
| `exa-core` | exa-skills | Exa AI 웹 검색 (search, answer 등) |
| `claude-memory` | Claudest | 대화 간 기억 지속 (extract-learnings 등) |

> `codex@openai-codex` 는 설치되어 있으나 비활성화 상태입니다.

---

## 주요 설정값

### settings.json 핵심 항목

| 키 | 값 | 설명 |
|---|---|---|
| `model` | `sonnet[1m]` | Claude Sonnet 4.6 (1M 컨텍스트) |
| `permissions.defaultMode` | `acceptEdits` | 파일 편집 자동 승인 |
| `skipDangerousModePermissionPrompt` | `true` | bypass 모드 프롬프트 생략 |
| `autoDreamEnabled` | `true` | 세션 종료 시 자동 메모리 추출 |
| `effortLevel` | `medium` | 기본 작업 노력 수준 |
| `ENABLE_TOOL_SEARCH` | `true` | 지연 로드 도구 검색 활성화 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 멀티 에이전트 팀 기능 활성화 |
| `CLAUDE_CODE_USE_POWERSHELL_TOOL` | `1` | PowerShell 도구 활성화 |

### MCP 서버

| 서버 | 실행 방법 | 설명 |
|---|---|---|
| `playwright` | `npx @playwright/mcp@latest` | 브라우저 자동화 (Claude Desktop에서 사용) |

---

## 수동 설치

스크립트 없이 직접 설치하려면:

```bash
# 1. 설정 파일 복사
cp settings.json ~/.claude/settings.json
cp settings.local.json.template ~/.claude/settings.local.json
cp CLAUDE.md ~/.claude/CLAUDE.md

# Windows: MCP 설정 (YOUR_USERNAME 치환 필요)
cp mcp/claude_desktop_config.json "$APPDATA/Claude/claude_desktop_config.json"

# 2. 커스텀 마켓플레이스 등록
claude plugin marketplace add exa-skills github:benjaminjackson/exa-skills
claude plugin marketplace add Claudest github:gupsammy/claudest
claude plugin marketplace add openai-codex github:openai/codex-plugin-cc

# 3. 플러그인 설치
claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install exa-core@exa-skills
claude plugin install claude-memory@Claudest
```

---

## 설치 후 확인사항

- `settings.json` 의 `CLAUDE_CODE_GIT_BASH_PATH` — Git Bash 실제 경로 확인 (Windows)
- `mcp/claude_desktop_config.json` 의 `localAgentModeTrustedFolders` — 실제 작업 폴더로 변경
- Claude Code 재시작
