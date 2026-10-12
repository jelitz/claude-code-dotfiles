# 릴리스 노트

버전은 스냅샷 날짜(`vYYYY.MM.DD`)입니다. 같은 날 두 번째 릴리스부터는 `.2`, `.3`을 붙입니다.

## v2026.10.12 (2026-10-12)

`sdd` 스킬의 이름을 `writing-sdd-blueprints`로 바꿨고, [github/spec-kit](https://github.com/github/spec-kit) v1.1.3을 읽고 superpowers 7.0.0과 겹치지 않는 장치만 이 스킬과 adversarial-reviewer 에이전트에 넣었습니다. spec-kit의 절차 자체(단일 9단계, 긴 명령 스크립트, 프로젝트별 설치, constitution)는 가져오지 않았습니다. 복원할 때는 `~/.claude/skills/sdd/`가 남아 있으면 지우고 `config/skills/writing-sdd-blueprints/`를 복사하면 됩니다.

### 스킬

- **`sdd` → `writing-sdd-blueprints`로 이름을 바꿨습니다.** "blueprints"가 steering과 specs를 함께 가리키고 "sdd"가 방법론을 알려 줍니다. superpowers `writing-plans`와 같은 동사형이라 둘을 나란히 두면 순서가 읽힙니다. "spec-kit"은 GitHub 도구 이름이라 피했습니다. CLAUDE.md의 참조 두 줄도 새 이름으로 바꿨습니다.
- **`writing-sdd-blueprints`에 에픽 분할(roadmap) 절을 추가했습니다.** 한 사이클에 담기지 않는 기능은 `docs/specs/{epic}/roadmap.md`에 독립적으로 테스트 가능한 조각으로 나누고, 조각 스펙은 첫 줄에서 로드맵 ID를 역참조합니다. 과제 수 제한이나 서브에이전트 위임으로 풀리면 만들지 않습니다.
- **`requirements.md`에 Assumptions 절, `design.md`에 Complexity Tracking 표를 정의했습니다.** 사용자가 정하지 않아 기본값으로 채운 항목과 `[미확정: 질문]`은 Assumptions에, 단순한 길을 벗어난 결정은 "결정 · 왜 필요 · 더 단순한 대안을 버린 이유" 표에 적습니다. brainstorming builder check의 "내 판단" 더미가 Assumptions로 들어가는 대응도 적었습니다.
- **`tasks.md`를 추가 전용으로 선언하고 유지 모델을 flow-back으로 명시했습니다.** 완료된 과제는 고치지 않고 남은 일은 끝에 덧붙입니다.
- **superpowers 대응표에 두 줄을 더했습니다.** writing-plans Self-Review가 tasks 승인 전 정합성 점검을 대신하고, subagent-driven-development의 최종 코드 리뷰가 PR 전 적대적 리뷰를 대신합니다.

### 에이전트

- **`adversarial-reviewer`가 요청되지 않은 코드(unrequested)와 기준에 어긋나는 코드(contradicts)도 보고하고, `tasks.md`가 기준에 있으면 남은 일을 추가 전용 과제 줄로 정리해 줍니다.** 파일에 쓰는 것은 위임자가 합니다.

### CLAUDE.md

- **리뷰 중복 방지 한 줄.** subagent-driven-development의 최종 코드 리뷰가 돌았으면 PR 전 adversarial-reviewer를 생략합니다. builder check와 requirements 교차 검토 사이에 있던 같은 규칙을 PR 단계로 확장한 것입니다.

## v2026.10.11.4 (2026-10-11)

글로벌 `CLAUDE.md`의 "기획 문서 (SDD)" 절을 새 스킬 `sdd`로 옮겼습니다. 공식 지침("절차는 스킬에, 규칙은 CLAUDE.md에")에 따라 파일 레이아웃·EARS 표기·superpowers 대응표 같은 절차는 스킬이 맡고, "큰 기능이면 `sdd` 호출, 단계마다 승인, tasks 승인 뒤 `/clear`"라는 규칙만 CLAUDE.md에 남겼습니다. CLAUDE.md는 81줄에서 75줄이 됐습니다. 복원할 때는 `config/skills/sdd/`가 `~/.claude/skills/`에 함께 복사되는지만 확인하면 됩니다.

### 스킬

- **`sdd` 스킬을 추가했습니다.** `docs/steering/`(product·tech·structure)와 `docs/specs/{feature-name}/`(requirements·design·tasks·implemented) 레이아웃, EARS 승인기준과 검증 명령 규칙, requirements → design → tasks 각 승인 게이트, `/clear` 뒤 재시작, superpowers brainstorming 설계 문서를 requirements+design으로 나누고 writing-plans 계획을 tasks.md로 저장하는 대응표, builder check가 돌았으면 adversarial-reviewer를 생략하는 규칙을 담았습니다. description은 큰 기능의 스펙 작성·갱신과 superpowers 산출물 저장 시점에 트리거되도록 썼습니다.

### CLAUDE.md

- **SDD 절 10줄을 2줄로 줄였습니다.** 스킬 호출 조건과 승인 게이트, 프로젝트 CLAUDE.md 컨벤션 우선, `/clear` 재시작, tasks·implemented 동기화만 남았습니다. 하네스 우선순위 절의 "위 SDD 절의" 참조는 "`sdd` 스킬의"로 바꿨습니다.

## v2026.10.11.3 (2026-10-11)

전역 `CLAUDE.md`만 바뀐 버전입니다. superpowers 7.0.0과의 우선순위를 정하는 절을 넣었고, `/claude-api prompt-audit`로 Claude Fable 5.1 기준의 낡은 문구를 걷어냈으며, 상단 유지보수 메모와 인라인 주석을 모두 지웠습니다. 109줄에서 81줄이 됐습니다. 복원할 때 따로 할 일은 없습니다.

### CLAUDE.md

- **"하네스 우선순위 (superpowers 7.x)" 절을 추가했습니다.** CLAUDE.md가 superpowers 스킬보다 우선한다는 원칙, brainstorming의 quick/small 판정과 "diff 한 문장이면 계획 생략" 기준의 대응, 인터뷰 질문은 내장 질문 도구로 묶고 코드베이스 탐색은 허락 없이 먼저 한다는 규칙, 설계 문서는 `docs/superpowers/specs`가 아니라 `docs/specs/{feature-name}/`에 requirements → design → tasks로 나눠 쓴다는 경로(기존 3게이트 유지), builder check가 돌았으면 adversarial-reviewer를 다시 돌리지 않는다는 중복 방지, 서브에이전트에는 SessionStart 주입이 가지 않으니 TDD·검증 규율을 위임 프롬프트에 직접 쓴다는 사실을 담았습니다.
- **SDD 절의 "YOU MUST"를 평서형으로 낮췄습니다.** Anthropic 프롬프트 지침(강조어는 과잉 트리거 원인)과 superpowers 이슈 #2377의 315세션 실측(강조어의 라우팅 효과 0)을 근거로 했습니다. 규칙 내용은 그대로입니다.
- **prompt-audit 결과 6곳을 고쳤습니다.** "탐색 → 계획 → 구현 → 커밋" 절차 문구를 "diff 한 문장이면 계획 생략, 그 이상이면 계획 먼저"로, "병렬화 전 동의" 게이트를 "서브에이전트에 맡기고 계속 진행, Workflow만 옵트인이라 먼저 제안"으로 바꿨습니다. SDD 절의 "(건너뛰고 구현 직행 금지)" 괄호, Environment 절의 날짜·과거형 서술, web-research 스킬의 파라미터 포인터(스킬이 도구 선택만 다룸), Workflow 도구 설명이 이미 강제하는 `workflow-authoring` 참조는 지웠습니다. "model 생략 기본값보다 이 규칙 우선" 줄은 스킬이 지금도 model 생략을 기본으로 두고 Agent 도구가 effort 변경에 CLAUDE.md 명시를 요구하므로 남겼습니다.
- **상단 유지보수 메모(23줄)와 도구 절 인라인 주석 3개를 모두 삭제했습니다.** 200줄 상한, 강조어 예산, 넣지 말 것 목록, 훅 전환 목록, 각 줄의 근거·만료 조건은 더 이상 CLAUDE.md에 없습니다. 그 근거는 이 릴리스 노트에만 남습니다.

## v2026.10.11.2 (2026-10-11)

`dadeumi-gate` 훅의 검사 범위를 스킬 문서에 맞게 되돌렸고 `destructive-command-gate` 훅이 커밋 메시지 같은 따옴표 안의 글자 때문에 명령을 막던 문제를 고쳤습니다. 커밋 작성자 정보를 개인 계정으로 통일하느라 저장소 히스토리를 다시 썼습니다.

### 훅

- **`dadeumi-gate` 훅이 다시 Bash·PowerShell의 `gws`·`gh` 명령을 검사합니다.** v2026.10.11에서는 Bash의 `gws` 명령만 검사했습니다. `dadeumi` 스킬 문서가 설명하는 범위를 기준으로 설정을 고쳤습니다.
- **`destructive-command-gate` 훅이 따옴표·heredoc·PowerShell here-string 안의 글자를 명령으로 보지 않습니다.** 이전에는 커밋 메시지에 `--no-verify`나 `rm -rf`라는 글자만 있어도 명령이 막혔습니다. `bash -c "..."`·`pwsh -Command "..."` 안의 명령은 따로 다시 검사합니다. `--no-verify`와 같은 뜻인 `git commit -n`도 이제 거부합니다.
- **`destructive-command-gate` 훅의 회귀 테스트를 추가했습니다.** `node --test "tests/**/*.test.js"`로 실행합니다.

### 저장소

- **커밋 작성자·커미터 정보를 개인 계정(`jelitz`)의 GitHub noreply 주소로 통일했습니다.** 히스토리를 다시 써서 모든 커밋 해시가 바뀌었고 `v2026.10.11` 태그도 새 커밋을 가리킵니다. 이전에 clone한 사본은 새로 clone하거나 `git fetch --force --tags` 후 `git reset --hard origin/master`로 맞춰야 합니다.

## v2026.10.11 (2026-10-11)

이 저장소의 첫 버전 릴리스입니다. 9월 17일 스냅샷 이후 바뀐 PC 설정을 다시 맞췄습니다. 웹 검색 도구 체인에서 Jina를 빼고 Firecrawl을 넣었고 위험한 명령과 Python 인코딩 누락을 잡는 훅 두 개를 추가했습니다. 이전 setup 스크립트에서 마켓플레이스 등록이 실패하던 문제도 고쳤습니다. 이 버전부터 변경 이력을 이 파일과 GitHub Release에 함께 남깁니다.

### 웹 검색

- **웹 검색·fetch 체인을 Exa → Firecrawl → insane-search → 브라우저로 바꿨습니다.** Jina는 CAPTCHA·403 페이지에서 본문을 가져오지 못했고 검색(`s.jina.ai`)은 API 키 없이는 막혀 있어서 체인에서 뺐습니다. JS 렌더링이나 봇 차단이 있는 페이지는 Firecrawl이 맡습니다.
- **`web-research` 스킬을 도구 선택표와 함정 5줄로 다시 썼습니다.** 이전 판에 있던 Exa 파라미터 설명과 Jina 사용법을 빼고 상황별로 쓸 도구와 틀리기 쉬운 기본값만 남겼습니다. 명령 옵션은 각 도구 스키마와 firecrawl 플러그인 스킬이 이미 설명합니다. 함정에는 Exa fetch의 3,000자 제한, WebFetch가 원문 대신 요약을 준다는 점, Firecrawl의 기본 2일 캐시를 적었습니다.
- **CLAUDE.md의 웹 검색 규칙을 한 줄로 줄이고 세부는 `web-research` 스킬로 넘겼습니다.**

### 훅

- **`destructive-command-gate` 훅을 추가했습니다.** git 명령의 `--no-verify`는 거부하고 `rm -rf`·`git push --force`·`git reset --hard`·`git clean -f`는 auto 모드에서도 확인을 받습니다. CLAUDE.md에 권고로만 있던 규칙을 훅으로 옮겼습니다.
- **`py-encoding-check` 훅을 추가했습니다.** `.py` 파일을 저장하면 `encoding=` 없이 텍스트를 읽고 쓰는 호출을 찾아 Claude에게 알립니다. 차단하지는 않습니다.
- **`dadeumi-gate` 훅은 이제 셸 명령 중에서는 Bash의 `gws` 명령만 검사합니다.** 이전 스냅샷과 달리 `gh` 명령과 PowerShell 명령은 검사하지 않습니다. Confluence·Jira·Slack 게시 도구와 `Skill` 호출 검사는 그대로입니다.

### 플러그인

- **superpowers를 superpowers-marketplace 판으로 바꿔 켰습니다.** 스킬과 CLAUDE.md가 어긋날 때 무엇을 따를지는 CLAUDE.md의 "하네스 우선순위" 절에 정리했습니다.
- **firecrawl, sentry, typescript-lsp, pyright-lsp를 켰습니다.** setup 스크립트가 설치하는 활성 플러그인은 12종이 됐습니다.
- **example-skills, security-guidance, code-simplifier, pr-review-toolkit는 껐습니다.** setup 설치 목록에서 빠졌고 `plugins/installed_plugins.json`에는 비활성으로 기록했습니다.

### setup 스크립트

- **마켓플레이스 등록 명령을 고쳤습니다.** 이전 스크립트는 `claude plugin marketplace add`에 인자 두 개를 넘겨서 등록이 실패했고 그 마켓플레이스의 플러그인도 설치되지 않았습니다. 실패를 "이미 등록됨"으로 출력해서 드러나지도 않았습니다. 이제 소스 하나만 넘기고 exit code로 성공 여부를 판정합니다.
- **`claude-plugins-official` 마켓플레이스를 명시적으로 등록합니다.** Claude Code를 한 번도 실행하지 않은 PC에는 이 마켓플레이스가 없어서 context7 등 여기 속한 플러그인이 설치되지 않았습니다.

### 스킬·에이전트

- **`adversarial-reviewer` 에이전트를 추가했습니다.** PR을 열기 전 diff를 새 컨텍스트에서 적대적으로 검토합니다.
- **디자인 스킬 5종을 뺐습니다.** 현재 PC 설정에 없기 때문입니다. pup이 만드는 Datadog 스킬 11종과 에이전트 48종은 복원용으로 그대로 둡니다.

### 설정

- **`settings.json`에 env(`PYTHONUTF8`·`PYTHONIOENCODING`), 모델별 effort, `skillOverrides`, 새 훅 등록을 반영했습니다.** 기본 모델은 `opus`로 바뀌었습니다.
- **조직 정보가 들어 있는 `autoMode` 설정, 프로젝트 종속 권한, 로컬 폴더 마켓플레이스는 저장소에 넣지 않았습니다.**

### 릴리스

- **버전 태그와 릴리스 노트를 도입했습니다.** `v*` 태그를 push하면 GitHub Actions가 이 파일에서 해당 버전 절을 뽑아 Release를 만듭니다. 태그가 `VERSION` 파일이나 README 배지와 다르면 실패합니다.

### 이 버전으로 복원할 때

- 이전 스냅샷의 setup으로 복원했다면 이 버전의 setup을 다시 실행해 빠진 플러그인을 설치합니다.
- Firecrawl CLI를 설치하고 로그인합니다: `npm install -g firecrawl-cli` 실행 후 `firecrawl login --browser`
- Exa MCP를 user 스코프로 등록합니다: `claude mcp add --transport http -s user exa "https://mcp.exa.ai/mcp?tools=web_search_exa,web_search_advanced_exa"`
- claude.ai 계정에서 Exa 커넥터를 연결합니다. URL 본문을 읽는 `web_fetch_exa`는 이 커넥터가 제공합니다.
