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

**1. Claude Code CLI 설치** — Native Install 권장 (npm 방식은 더 이상 권장하지 않음)

| 플랫폼 | 명령 |
|---|---|
| Windows PowerShell | `irm https://claude.ai/install.ps1 \| iex` |
| Windows CMD | `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd` |
| macOS / Linux / WSL | `curl -fsSL https://claude.ai/install.sh \| bash` |
| WinGet (Windows 대안) | `winget install Anthropic.ClaudeCode` |
| Homebrew (macOS 대안) | `brew install --cask claude-code` |

> 네이티브 설치는 백그라운드 자동 업데이트를 지원합니다. 자세한 내용은 [Claude Code 공식 설정 문서](https://code.claude.com/docs/ko/setup) 참고.

**2. Git for Windows** (Windows 권장, 선택)

Claude Code의 Bash 도구를 사용하려면 [Git for Windows](https://git-scm.com/downloads/win) 설치를 권장합니다. 미설치 시 PowerShell로 폴백됩니다.

**3. Node.js v20+** (옵션 — 일부 MCP 서버 한정)

`@playwright/mcp`, `korean-law-mcp` 등 npx 기반 MCP 서버를 사용하려는 경우에만 필요합니다. Claude Code 본체는 더 이상 Node.js에 의존하지 않습니다.

**설치 확인**

```bash
claude --version
claude doctor   # 설치 상태 진단
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

## 설치되는 플러그인

### 활성화 (`enabled: true`)

| 플러그인 | 마켓플레이스 | 설명 |
|---|---|---|
| `superpowers` | claude-plugins-official | 브레인스토밍·플래닝·TDD·디버깅·코드리뷰 스킬 모음 |
| `context7` | claude-plugins-official | 라이브러리/프레임워크 최신 문서 실시간 조회 (MCP) |
| `pyright-lsp` | claude-plugins-official | Python LSP 지원 (타입 체크·자동완성) |
| `ralph-loop` | claude-plugins-official | Ralph Loop 반복 실행 워크플로 |
| `claude-code-setup` | claude-plugins-official | Claude Code 자동화 추천·설정 헬퍼 |
| `playground` | claude-plugins-official | 단일 HTML playground/explorer 생성 스킬 |
| `codex` | openai-codex | OpenAI Codex 서브에이전트 (rescue, setup) |
| `exa-core` | exa-skills | Exa AI 웹 검색 (search, context, answer, find-similar 등) |
| `document-skills` | anthropic-agent-skills | Anthropic 공식 문서 작업 (PDF·DOCX·XLSX·PPTX·frontend-design 등) |
| `claude-mem` | thedotmack | 세션 간 영속 메모리 (mem-search, timeline-report, smart-explore) |

### 설치되지만 비활성 (`enabled: false`)

| 플러그인 | 마켓플레이스 | 비활성 사유 |
|---|---|---|
| `frontend-design` | claude-plugins-official | document-skills의 frontend-design과 중복 |
| `playwright` | claude-plugins-official | claude-in-chrome MCP를 우선 사용 |
| `korean-law` | korean-law-marketplace | 개인 OC ID 필요 (필요시 활성화) |
| `lazyweb` | lazyweb | 옵션 |
| `cloudflare` | claude-plugins-official | Cloudflare 리소스 다룰 때만 활성화 |

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
| `permissions.defaultMode` | `auto` | 자동 모드 (안전한 작업은 자동 승인) |
| `autoDreamEnabled` | `true` | 세션 종료 시 자동 메모리 추출 |
| `effortLevel` | `medium` | 기본 작업 노력 수준 (low/medium/high/xhigh/max) |
| `advisorModel` | `opus` | `/advisor` 보조 리뷰어 모델 — statusline `⚖ advisor:`에 표시 |
| `language` | `Korean` | 응답 언어 |
| `ENABLE_TOOL_SEARCH` | `true` | 지연 로드 도구 검색 활성화 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 멀티 에이전트 팀 기능 활성화 |
| `CLAUDE_CODE_USE_POWERSHELL_TOOL` | `1` | PowerShell 도구 활성화 (Windows) |

### MCP 서버

| 서버 | 실행 방법 | 설명 |
|---|---|---|
| `playwright` | `npx @playwright/mcp@latest` | 브라우저 자동화 (Claude Desktop에서 사용) |
| `korean-law` (옵션) | `npx korean-law-mcp@latest --oc YOUR_OC_ID` | 한국 법령 검색. 사용 시 `mcp/claude_desktop_config.json`에서 `_korean-law-example` 키의 `_` 제거 + 본인 OC ID 입력 |
| `claude-in-chrome` | Chrome 확장에서 자동 | Claude in Chrome 확장 설치 시 자동 등록되며 별도 MCP 설정 불필요 |
| `context7` | 플러그인이 자동 등록 | `context7@claude-plugins-official` 활성 시 자동 |
| `claude-mem` | 플러그인이 자동 등록 | `claude-mem@thedotmack` 활성 시 자동 |

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

# 2. 커스텀 마켓플레이스 등록 (claude-plugins-official 은 기본 등록)
claude plugin marketplace add anthropic-agent-skills github:anthropics/skills
claude plugin marketplace add exa-skills github:benjaminjackson/exa-skills
claude plugin marketplace add openai-codex github:openai/codex-plugin-cc
claude plugin marketplace add thedotmack github:thedotmack/claude-mem
# 옵션 마켓플레이스 (필요 시)
claude plugin marketplace add korean-law-marketplace github:chrisryugj/korean-law-mcp
claude plugin marketplace add lazyweb https://github.com/aboul3ata/lazyweb-skill.git

# 3. 플러그인 설치 (활성화 대상)
claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install ralph-loop@claude-plugins-official
claude plugin install claude-code-setup@claude-plugins-official
claude plugin install playground@claude-plugins-official
claude plugin install codex@openai-codex
claude plugin install exa-core@exa-skills
claude plugin install document-skills@anthropic-agent-skills
claude plugin install claude-mem@thedotmack
```

---

## 설치 후 확인사항

- `settings.json` 의 `CLAUDE_CODE_GIT_BASH_PATH` — Git Bash 실제 경로 확인 (Windows)
- `mcp/claude_desktop_config.json` 의 `localAgentModeTrustedFolders` — 실제 작업 폴더로 변경
- Claude Code 재시작
