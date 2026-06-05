# claude-code-dotfiles

개인 Claude Code 사용 환경 백업 저장소.
새 머신에서 Claude Code를 설치하거나 기존 설정을 복원할 때 사용하고, 같은 구성을 참고하려는 다른 사용자도 그대로 활용할 수 있습니다.

> **스냅샷 기준**: 2026-06-05 · Claude Code 2.1.165 · Windows 11 (PowerShell 7 / Git Bash)
> 개인 식별 정보(사용자명·계정 ID·개인 경로·API 식별자)는 모두 `YOUR_USERNAME`, `YOUR_OC_ID` 등의 플레이스홀더로 치환되어 있습니다. 자세한 내용은 [비식별화 정책](#비식별화-정책) 참고.

---

## 파일 구조

```
claude-code-dotfiles/
├── settings.json                    # 메인 설정 → ~/.claude/settings.json
├── settings.local.json.template     # 로컬(머신별) 권한 설정 템플릿
├── CLAUDE.md                        # 전역 AI 지시사항 → ~/.claude/CLAUDE.md
├── RTK.md                           # RTK 사용 지침 (CLAUDE.md 가 @RTK.md 로 import)
├── statusline-bash.sh               # 커스텀 2줄 statusline 스크립트
├── skills/                          # 사용자 스킬 → ~/.claude/skills/
│   ├── code-search-exa/             #   Exa 코드 검색 (Task agent 격리 실행)
│   ├── company-research/            #   Exa 기업 리서치
│   └── web-search-advanced-research-paper/  # Exa 논문 검색
├── plugins/
│   ├── installed_plugins.json       # 플러그인 목록 (활성/비활성/스코프 + 설명)
│   └── known_marketplaces.json      # 마켓플레이스 목록 (실사용/등록만 구분)
├── mcp/
│   └── claude_desktop_config.json   # Claude Desktop MCP·환경 설정
├── examples/
│   └── project-permissions.example.json  # 프로젝트 종속 권한 예시 (Railway 등)
├── setup.sh                         # 복원 스크립트 (Git Bash / macOS)
└── setup.ps1                        # 복원 스크립트 (PowerShell)
```

---

## 빠른 설치

### 전제 조건

**1. Claude Code CLI** — Native Install 권장 (npm 방식은 더 이상 권장하지 않음)

| 플랫폼 | 명령 |
|---|---|
| Windows PowerShell | `irm https://claude.ai/install.ps1 \| iex` |
| Windows CMD | `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd` |
| macOS / Linux / WSL | `curl -fsSL https://claude.ai/install.sh \| bash` |
| WinGet (Windows 대안) | `winget install Anthropic.ClaudeCode` |
| Homebrew (macOS 대안) | `brew install --cask claude-code` |

설치 확인: `claude --version` / `claude doctor`

**2. Git for Windows** (Windows 권장) — Claude Code의 Bash 도구와 statusline 스크립트가 사용. 미설치 시 PowerShell로 폴백.

**3. rtk** (사실상 필수 — 아래 [RTK](#rtk--토큰-절약-레이어) 참고)
`settings.json` 의 PreToolUse 훅이 `rtk` 를 호출하므로, **rtk 미설치 상태로 settings.json 을 적용하면 모든 Bash 도구 호출에서 훅 오류가 발생**합니다. setup 스크립트가 설치 여부를 검사하고 경고합니다.

**4. Node.js v20+** (옵션) — `@playwright/mcp`, `korean-law-mcp` 등 npx 기반 MCP 서버 사용 시에만 필요.

### 설치

```bash
# Git Bash (Windows) / macOS / Linux
git clone https://github.com/jelitz/claude-code-dotfiles.git
cd claude-code-dotfiles
bash setup.sh
```

```powershell
# PowerShell (Windows)
git clone https://github.com/jelitz/claude-code-dotfiles.git
cd claude-code-dotfiles
.\setup.ps1
```

스크립트가 자동으로:
1. `settings.json` · `settings.local.json` · `CLAUDE.md` · `RTK.md` · `statusline-bash.sh` 복사 (플레이스홀더 치환 포함)
2. 사용자 스킬 3종 → `~/.claude/skills/` 복사
3. `mcp/claude_desktop_config.json` → `%APPDATA%\Claude\` 복사
4. 커스텀 마켓플레이스 등록 (8곳)
5. 활성 플러그인 11종 설치
6. rtk 설치 여부 확인 및 경고

---

## RTK — 토큰 절약 레이어

[rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer)는 git/ls/grep 등 자주 쓰는 CLI 출력물을 LLM 컨텍스트에 들어가기 전에 압축·필터링해 **토큰을 60-90% 절약**하는 단일 Rust 바이너리 프록시입니다.

이 환경에서의 연동 방식:

| 구성 요소 | 역할 |
|---|---|
| `settings.json` → `hooks.PreToolUse` | `rtk hook claude` — Bash 도구 호출을 가로채 `git status` → `rtk git status` 식으로 자동 재작성 |
| `RTK.md` | rtk 메타 명령(`rtk gain`, `rtk discover`, `rtk proxy`) 사용 지침. `CLAUDE.md` 가 `@RTK.md` 로 import |
| 바이너리 위치 | `~/.local/bin/rtk` (PATH 등록 필요, 스냅샷 시점 버전 0.39.0) |

> ⚠ rtk 를 쓰지 않으려면 `~/.claude/settings.json` 에서 `hooks.PreToolUse` 블록을 제거하고, `CLAUDE.md` 의 `@RTK.md` import 줄과 `RTK.md` 를 삭제하면 됩니다.

---

## 플러그인

### 활성 (`enabled: true`)

| 플러그인 | 마켓플레이스 | 설명 |
|---|---|---|
| `superpowers` | claude-plugins-official | 브레인스토밍·플래닝·TDD·디버깅·코드리뷰 스킬 모음 |
| `context7` | claude-plugins-official | 라이브러리/프레임워크 최신 문서 실시간 조회 (MCP) |
| `pyright-lsp` | claude-plugins-official | Python LSP 지원 (타입 체크·자동완성) |
| `ralph-loop` | claude-plugins-official | Ralph Loop 반복 실행 워크플로 |
| `claude-code-setup` | claude-plugins-official | Claude Code 자동화 추천·설정 헬퍼 |
| `playground` | claude-plugins-official | 단일 HTML playground/explorer 생성 스킬 |
| `codex` | openai-codex | OpenAI Codex 서브에이전트 (rescue, setup). **job은 항상 `--background` 로 실행** (CLAUDE.md 참고) |
| `exa-core` | exa-skills | Exa AI 웹 검색 (search, context, answer, find-similar 등) |
| `document-skills` | anthropic-agent-skills | Anthropic 공식 문서 작업 (PDF·DOCX·XLSX·PPTX·frontend-design 등) |
| `claude-mem` | thedotmack | 세션 간 영속 메모리 (mem-search, timeline-report, smart-explore) |
| `andrej-karpathy-skills` | karpathy-skills | Karpathy 코딩 가이드라인 — 과도한 복잡화 방지·외과적 수정 |

### 설치되어 있지만 비활성 (`enabled: false`)

| 플러그인 | 마켓플레이스 | 비활성 사유 |
|---|---|---|
| `frontend-design` | claude-plugins-official | document-skills의 frontend-design과 중복 |
| `playwright` | claude-plugins-official | claude-in-chrome MCP를 우선 사용 |
| `korean-law` | korean-law-marketplace | 개인 OC ID 필요 (필요시 활성화) |
| `lazyweb` | lazyweb | 옵션 |
| `cloudflare` | claude-plugins-official | Cloudflare 리소스 다룰 때만 활성화 |
| `example-skills` | anthropic-agent-skills | 참고용으로 설치만 해둠 |
| `ui-ux-pro-max` | ui-ux-pro-max-skill | 프로젝트 스코프 설치, 현재 미활성 |
| `sentry` | claude-plugins-official | 특정 프로젝트 스코프로만 설치 (전역 미사용) |

마켓플레이스는 `plugins/known_marketplaces.json` 에 **실사용(active) / 등록만(registered-only)** 으로 구분 기록되어 있습니다. 등록만 해둔 곳(Claudest, ecc, agent-browser, claude-for-financial-services)은 setup 스크립트에서 주석 처리되어 있으며 필요 시 해제하면 됩니다.

---

## 사용자 스킬 (`~/.claude/skills/`)

플러그인과 별개로 직접 관리하는 개인 스킬. 셋 다 Exa MCP(`https://mcp.exa.ai/mcp`)를 사용하며, **메인 컨텍스트 오염 방지를 위해 항상 Task agent 로 격리 실행**하도록 작성되어 있습니다.

| 스킬 | 용도 |
|---|---|
| `code-search-exa` | 코드 예제·API 문법·라이브러리 문서 검색 (GitHub/StackOverflow) |
| `company-research` | 기업 정보·경쟁사·시장 리서치 |
| `web-search-advanced-research-paper` | 학술 논문·arXiv 검색 (날짜·텍스트 필터 지원) |

---

## MCP 서버

| 서버 | 등록 방식 | 설명 |
|---|---|---|
| `claude-in-chrome` | Chrome 확장에서 자동 | 브라우저 자동화 기본 수단 (CLAUDE.md 에서 Playwright 보다 우선하도록 지정) |
| `context7` | 플러그인이 자동 등록 | `context7@claude-plugins-official` 활성 시 자동 |
| `claude-mem` (mcp-search) | 플러그인이 자동 등록 | `claude-mem@thedotmack` 활성 시 자동 |
| Slack | claude.ai 커넥터 | claude.ai 계정 연결로 제공 (이 저장소 설정과 무관, 계정에서 별도 연결) |
| `playwright` | Claude Desktop (`mcp/claude_desktop_config.json`) | `npx @playwright/mcp@latest` — Desktop 전용 |
| `korean-law` (옵션) | Claude Desktop | `npx korean-law-mcp@latest --oc YOUR_OC_ID` — 사용 시 `_korean-law-example` 키의 `_` 제거 + 본인 [국가법령정보센터](https://open.law.go.kr) OC ID 입력 |

---

## Statusline

터미널 하단에 세션 정보를 두 줄로 표시합니다 (`statusline-bash.sh`).

```
⎇ main │ ◈ Opus 4.8 │ effort: xhigh │ ⚖ advisor: (unset) │ v2.1.165
ctx ████░░░░ 45% │ $0.23 │ 5h ██░░░░░░ 23% ↻ 1h30m │ 7d █░░░░░░░ 13%
```

**Row 1 — identity**

| 항목 | 설명 |
|---|---|
| `⎇ branch` | 현재 git 브랜치 (cyan) |
| `◈ model` | 모델명 (blue, "Claude " 접두어 생략) |
| `effort: <lvl>` | 작업 노력 수준 (magenta) |
| `⚖ advisor: <model>` | `settings.json` 의 `advisorModel` 값 (yellow); 미설정 시 `(unset)` (dim) |
| `v버전` | Claude Code 버전 (dim) |

**Row 2 — usage**

| 항목 | 설명 |
|---|---|
| `ctx bar %` | 컨텍스트 윈도우 사용률 (50%↑ 노랑, 80%↑ 빨강) |
| `$cost` | 세션 누적 비용 ($1↑ 노랑, $5↑ 빨강) |
| `5h bar % ↻ left` | 5시간 rate limit + 리셋까지 남은 시간 |
| `7d bar %` | 7일 rate limit |

**구현 메모**
- advisor 값은 stdin JSON에 없어 스크립트가 `~/.claude/settings.json` 을 직접 읽음 (현재 `advisorModel` 미설정 → `(unset)` 표시)
- 줄 분리는 `printf '%s\n'` 두 번 호출 (Claude Code 다중 줄 statusline 사양)
- 활성화: `settings.json` → `statusLine.command` (Git Bash 식 경로 — setup.sh 가 OS에 맞게 치환)

---

## 주요 설정값 (settings.json)

| 키 | 값 | 설명 |
|---|---|---|
| `language` | `Korean` | 응답 언어 |
| `effortLevel` | `xhigh` | 기본 작업 노력 수준 (low/medium/high/xhigh/max) |
| `permissions.defaultMode` | `auto` | 안전한 작업은 자동 승인 |
| `hooks.PreToolUse` | `rtk hook claude` | Bash 명령을 rtk 프록시로 재작성 (토큰 절약) |
| `worktree.baseRef` | `fresh` | 워크트리 생성 시 기준 ref |
| `autoDreamEnabled` | `true` | 세션 종료 시 자동 메모리 추출 |
| `teammateMode` | `auto` | Agent Teams 팀원 실행 방식 자동 선택 |
| `skillListingBudgetFraction` | `0.05` | 스킬 목록이 차지하는 컨텍스트 비율 상한 |
| `autoUpdatesChannel` | `latest` | 최신 채널로 자동 업데이트 |
| `remoteControlAtStartup` | `true` | 시작 시 원격 제어 활성화 |
| `inputNeededNotifEnabled` / `agentPushNotifEnabled` | `true` | 입력 필요·에이전트 완료 푸시 알림 |
| `env.ENABLE_TOOL_SEARCH` | `true` | 지연 로드 도구 검색 활성화 |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | 멀티 에이전트 팀 기능 활성화 |
| `env.CLAUDE_CODE_USE_POWERSHELL_TOOL` | `1` | PowerShell 도구 활성화 (Windows) |
| `env.CLAUDE_CODE_GIT_BASH_PATH` | Git Bash 경로 | Bash 도구용 (Windows) |

> `model` 키는 의도적으로 두지 않음 — 세션마다 `/model` 로 선택. `advisorModel` 도 현재 미설정 (`/advisor` 로 필요 시 지정).

### 전역 권한 정책

전역 `settings.json` 의 `permissions.allow` 에는 **범용 권한 2개만** 유지합니다 (브라우저 탭 컨텍스트 조회, Get-FileHash). Railway 배포 운영 등 **프로젝트 종속 권한은 해당 프로젝트의 `.claude/settings.json` 에 두는 것이 원칙**이며, 실제 사용하던 목록은 [`examples/project-permissions.example.json`](examples/project-permissions.example.json) 에 참고용으로 보존되어 있습니다.

---

## 수동 설치

스크립트 없이 직접 설치하려면:

```bash
# 1. 설정 파일 복사 (YOUR_USERNAME 치환 필요)
cp settings.json ~/.claude/settings.json
cp settings.local.json.template ~/.claude/settings.local.json
cp CLAUDE.md RTK.md ~/.claude/
cp statusline-bash.sh ~/.claude/ && chmod +x ~/.claude/statusline-bash.sh
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/

# Windows: Claude Desktop MCP 설정
cp mcp/claude_desktop_config.json "$APPDATA/Claude/claude_desktop_config.json"

# 2. 커스텀 마켓플레이스 등록 (claude-plugins-official 은 기본 등록)
claude plugin marketplace add anthropic-agent-skills github:anthropics/skills
claude plugin marketplace add exa-skills github:benjaminjackson/exa-skills
claude plugin marketplace add openai-codex github:openai/codex-plugin-cc
claude plugin marketplace add thedotmack github:thedotmack/claude-mem
claude plugin marketplace add karpathy-skills github:forrestchang/andrej-karpathy-skills
claude plugin marketplace add korean-law-marketplace github:chrisryugj/korean-law-mcp
claude plugin marketplace add lazyweb https://github.com/aboul3ata/lazyweb-skill.git
claude plugin marketplace add ui-ux-pro-max-skill github:nextlevelbuilder/ui-ux-pro-max-skill

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
claude plugin install andrej-karpathy-skills@karpathy-skills
```

---

## 설치 후 확인사항

- `settings.json` 의 `CLAUDE_CODE_GIT_BASH_PATH` — Git Bash 실제 경로 확인 (Windows)
- `rtk` 가 PATH에 있는지 확인 (`rtk gain` 실행) — 없으면 [RTK](#rtk--토큰-절약-레이어) 항목 참고
- Claude Desktop 의 `localAgentModeTrustedFolders` — 실제 작업 폴더로 변경
- korean-law MCP 사용 시 본인 OC ID 입력
- Claude Code 재시작

---

## 비식별화 정책

이 저장소는 공개 백업이므로 다음 원칙을 따릅니다.

| 항목 | 처리 |
|---|---|
| 사용자명이 포함된 경로 | `YOUR_USERNAME` 플레이스홀더 (setup 스크립트가 치환) |
| API·서비스 개인 식별자 (OC ID 등) | `YOUR_OC_ID` 플레이스홀더 + 비활성(`_` 접두) 예시로만 보존 |
| 계정 UUID·디바이스명·기기 상태 캐시 | 백업에서 제거 (앱이 자동 재생성) |
| 사내·개인 NAS 등 비공개 경로 | 백업에서 제거 |
| 자격 증명 (`.credentials.json` 등) | `.gitignore` 로 커밋 차단 |
| 프로젝트 종속 권한 목록 | `examples/` 로 분리, 전역 설정에서 제외 |

갱신 시에도 커밋 전 위 항목이 포함되지 않았는지 확인하세요.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
