# claude-code-dotfiles

jsmoon의 Claude Code 설정 백업 레포.  
새 환경에서 Claude Code를 설치하거나 기존 설정을 복원할 때 사용합니다.

---

## 파일 구조

```
claude-code-dotfiles/
├── settings.json                    # 메인 설정 → ~/.claude/settings.json
├── settings.local.json.template     # 로컬 권한 설정 템플릿
├── CLAUDE.md                        # 전역 AI 지시사항 → ~/.claude/CLAUDE.md
├── statusline-bash.sh               # 커스텀 statusline 스크립트 → ~/.claude/statusline-bash.sh
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
git clone https://github.com/jelly35/claude-code-dotfiles.git
cd claude-code-dotfiles
bash setup.sh
```

### PowerShell (Windows)

```powershell
git clone https://github.com/jelly35/claude-code-dotfiles.git
cd claude-code-dotfiles
.\setup.ps1
```

스크립트가 자동으로:
1. `settings.json` → `~/.claude/settings.json` 복사
2. `CLAUDE.md` → `~/.claude/CLAUDE.md` 복사
3. `mcp/claude_desktop_config.json` → `%APPDATA%\Claude\` 복사
4. 커스텀 마켓플레이스 등록
5. 플러그인 설치

---

## BMAD Method

[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) — AI 기반 애자일 개발 프레임워크. PM·아키텍트·개발자·UX 등 12개 이상의 전문 AI 에이전트와 브레인스토밍→설계→구현→회고까지 전체 개발 사이클을 지원합니다.

설치 스크립트에서 자동으로 아래 명령을 실행합니다:

```bash
npx bmad-method install --directory ~/.claude --modules bmm --tools claude-code --yes
```

`--directory ~/.claude` 로 설치하면 모든 프로젝트에서 공통으로 BMAD 스킬을 사용할 수 있습니다.

**포함되는 주요 스킬 (51개):**
- `bmad-help` — 현재 상황에 맞는 다음 단계 안내
- `bmad-create-prd`, `bmad-create-architecture`, `bmad-create-ux-design` — 설계 문서 작성
- `bmad-dev-story`, `bmad-quick-dev` — 스토리 기반 구현
- `bmad-code-review`, `bmad-qa-generate-e2e-tests` — 코드 리뷰 및 테스트
- `bmad-sprint-planning`, `bmad-sprint-status`, `bmad-retrospective` — 스프린트 관리
- `bmad-party-mode` — 복수 AI 에이전트 협업 세션

> 수동 설치: `npx bmad-method install` (대화형 설치 마법사 실행)

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

## Statusline

터미널 하단에 세션 정보를 두 줄로 표시합니다.

**출력 형태:**
```
⎇ main │ ◈ Sonnet 4.6 │ effort: high │ ⚖ advisor: opus
ctx ████░░░░ 45% │ $0.23 │ 5h ████░░░░ 23% ↻ 1h30m │ 7d ░░░░░░░░ 13%  v2.1.90
```

**Row 1 — identity (현재 작동 환경)**

| 항목 | 설명 |
|---|---|
| `⎇ branch` | 현재 git 브랜치 (cyan) |
| `◈ model` | 모델명 (blue, "Claude " 접두어 생략) |
| `effort: <lvl>` | 작업 노력 수준 (magenta) |
| `⚖ advisor: <model>` | `/advisor`로 설정된 보조 리뷰어 모델 (yellow); 미설정 시 `(unset)` (dim) |

**Row 2 — usage (자원 소비)**

| 항목 | 설명 |
|---|---|
| `ctx bar %` | 컨텍스트 윈도우 사용률 progress bar |
| `$cost` | 세션 누적 비용 (dim / $1↑노랑 / $5↑빨강) |
| `5h bar % ↻ left` | 5시간 rate limit + 리셋까지 남은 시간 |
| `7d bar %` | 7일 rate limit (10% 미만이면 생략) |
| `v버전` | Claude Code 버전 (dim) |

**구현 메모**

- advisor 값은 stdin JSON에 포함되지 않아 스크립트가 `~/.claude/settings.json`의 `advisorModel` 키를 직접 읽음
- 줄 분리는 `printf '%s\n'`을 두 번 호출 → 각 호출이 별도 행으로 렌더링됨 (Claude Code 다중 줄 statusline 사양)

설정 파일 위치:
- 스크립트: `~/.claude/statusline-bash.sh`
- 활성화: `settings.json` → `statusLine.command`

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
| `advisorModel` | (선택) | `/advisor` 명령으로 설정 — 보조 리뷰어 모델. statusline에 표시됨 |
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

# 5. BMAD Method 설치
npx bmad-method install --directory ~/.claude --modules bmm --tools claude-code --yes
```

---

## 설치 후 확인사항

- `settings.json` 의 `CLAUDE_CODE_GIT_BASH_PATH` — Git Bash 실제 경로 확인 (Windows)
- `mcp/claude_desktop_config.json` 의 `localAgentModeTrustedFolders` — 실제 작업 폴더로 변경
- Claude Code 재시작
