# 릴리스 노트

버전은 스냅샷 날짜(`vYYYY.MM.DD`)입니다. 같은 날 두 번째 릴리스부터는 `.2`, `.3`을 붙입니다.

## v2026.10.27 (2026-10-27)

dadeumi 플러그인이 글의 유형과 구조를 정하는 1·2단계를 건너뛰고 윤문만 하던 문제를 고쳤습니다. 세션 27개를 조사하니 skill 호출은 대부분 초안 전에 있었지만, 전체 흐름 글 20건 중 목차를 먼저 만든 것은 4건이었습니다. 원인은 3단계에만 파일·스크립트·변경률이라는 산출이 있고 1·2단계에는 산출과 확인 지점이 없었던 것입니다. 상류 dadeumi 1.2.0이 1·2단계 산출을 "구조 확인 메시지"(유형·독자·목표와 목차)로 정했고, 이 저장소의 CLAUDE.md 조항도 호출이 아니라 그 메시지를 요구하도록 바꿨습니다. hook 사본(`dadeumi-gate.js`)은 바뀌지 않았습니다. 복원할 때 따로 할 일은 없습니다. 플러그인은 autoUpdate로 1.2.0을 받습니다.

### CLAUDE.md

- **「남이 읽을 글」 조항을 "초안 직전에 호출하고 유형·독자·목표와 목차를 먼저 보인 뒤 초안을 쓴다"로 바꿨습니다.** 호출만 하고 이 메시지가 없으면 흐름을 거치지 않은 것으로 봅니다.
## v2026.10.23 (2026-10-23)

독립 작업이 여럿일 때 Workflow 도구가 쓰이지 않던 문제를 고쳤습니다. 세션 110개를 조사해 보니 Workflow는 5개 세션에서만 돌았고 그중 2개는 사용자가 직접 지시한 경우였습니다. 계획에 독립 task가 많은 세션일수록 `subagent-driven-development`가 발동해 Agent를 한 번에 하나씩 수십 번 돌렸습니다. 한 응답에 Agent를 둘 이상 띄운 세션은 없었습니다. 원인은 셋입니다. Workflow 도구는 사용자 옵트인(`ultracode`) 없이는 호출할 수 없습니다. superpowers의 `dispatching-parallel-agents`·`subagent-driven-development`가 "독립 task 여럿"이라는 조건을 먼저 받아 Agent로 보냅니다. `writing-plans`의 실행 방식 질문(Subagent-driven / Native)에는 Workflow가 없습니다. CLAUDE.md의 Workflow 조항은 "제안한다"는 약한 규칙이었습니다. 수정안은 Workflow로 검증 에이전트 4개를 돌려 적대적으로 검토했고 must-fix 6건을 반영했습니다. `ultracode` 키는 Claude Code 2.1.309에서 확인했고 새 세션부터 적용되므로 복원할 때 따로 할 일은 없습니다.

### 설정

- **`settings.json`에 `ultracode: true`를 추가했습니다.** 새 세션이 Ultracode(동적 워크플로)가 켜진 상태로 시작해 Workflow 도구의 옵트인 조건을 상시 충족합니다. 2.1.284부터는 effort를 xhigh로 강제하지 않습니다. 한 세션만 끄려면 `/effort ultracode off`를 씁니다.

### CLAUDE.md

- **「서브에이전트 위임」 절의 Workflow 조항을 개수 기준으로 바꿨습니다.** 독립 작업(서로 의존하지 않고 수정 파일이 겹치지 않는 작업)이 3개 이상이거나, 같은 변경을 3개 이상 대상에 반복하되 대상마다 독자적인 판단·검증이 필요하면 Workflow를 띄웁니다. 이때 `dispatching-parallel-agents`·`subagent-driven-development`·`executing-plans`는 호출하지 않고 Agent 다중 호출로 대신하지 않습니다. ultracode가 켜진 세션에서는 제안 없이 바로 띄웁니다. 세션에서 껐다는 reminder가 있으면 비용을 적어 제안만 합니다. 동일한 한 줄 수정의 반복은 직접 하거나 Agent 1회에 묶습니다.
- **구현 경로 규칙을 「하네스 우선순위」 절에 넣었습니다.** `tasks.md`의 task가 위 기준에 해당하면 superpowers 구현 스킬 대신 Workflow로 구현합니다. 이 기준은 Workflow를 반드시 쓰는 하한이지 상한이 아닙니다. 기준 미만이라도 ultracode가 켜진 세션이면 `workflow-authoring`의 기본값을 따릅니다. superpowers 경로는 ultracode가 꺼진 세션의 기준 미만 작업에만 씁니다. Workflow 스크립트에는 SDD의 task 리뷰와 최종 리뷰(브랜치 전체 diff 대상 적대적 verify)에 해당하는 단계를 넣습니다.
- **`writing-plans`의 실행 방식 질문을 하지 않고 plan 머리의 `REQUIRED SUB-SKILL` 줄을 바꿉니다.** 질문의 선택지가 Subagent-driven / Native 둘뿐이라 Workflow가 빠집니다. plan 첫 줄의 `REQUIRED SUB-SKILL: subagent-driven-development` 지시가 `tasks.md`에 그대로 남아 재개 세션을 SDD로 이끌었습니다. `tasks.md` 승인만 받고 `/clear`를 제안합니다. 그 줄은 "구현 경로: 글로벌 CLAUDE.md 「하네스 우선순위」 구현 경로 규칙"으로 바꿉니다.
- **SDD 절에서 `tasks.md`로 재개한 세션이 위 구현 경로 규칙을 따르도록 참조를 달았습니다.**
- **리뷰 중복 제거 규칙에 Workflow의 최종 리뷰 단계를 추가했습니다.** SDD 최종 리뷰와 같이 Workflow 안에서 브랜치 전체 diff를 적대적으로 검증했으면 PR 전 adversarial-reviewer를 생략합니다. 「서브에이전트 위임」의 PR 전 리뷰 규칙에는 생략 조건의 위치를 적었습니다.
- **모델 배정 규칙에 Workflow 구현 단계 기준을 더했습니다.** 1~2파일에 완전한 스펙이면 sonnet, 설계 판단이 필요하면 세션 모델입니다.
- **Environment 절에 `python -I` 함정을 적었습니다.** `-I`는 PYTHON* 환경변수를 모두 무시해 전역 UTF-8 설정이 꺼지고 cp949로 돌아갑니다. encoding을 지정하지 않은 `open()`은 UTF-8 파일에서 UnicodeDecodeError가 납니다. stdout의 한글은 깨져 돌아오며 이모지나 — 같은 문자는 UnicodeEncodeError가 납니다. `-I`가 필요하면 `python -I -X utf8`로 호출합니다. 이 머신(Python 3.9.13)에서 재현했습니다.

### 스킬

- **`writing-sdd-blueprints`의 superpowers 대응표를 새 구현 경로에 맞췄습니다.** `writing-plans` 계획 행에 `REQUIRED SUB-SKILL` 줄 치환을, 최종 리뷰 행에 Workflow의 최종 리뷰 단계를 넣었습니다. Execution Handoff 질문을 하지 않는다는 행을 추가했습니다. 절차 3번에 재개 세션의 구현 경로 참조를 달았습니다.

### README

- **버전 배지를 v2026.10.23으로, Claude Code 배지를 2.1.309로 올리고 설정 표에 `ultracode` 행을 추가했습니다.**

## v2026.10.14.4 (2026-10-14)

새 PC에서 `dadeumi` 플러그인이 언제 쓸 수 있게 되는지 README에 적었습니다. 설정과 파일은 바뀌지 않았으므로 복원할 때 따로 할 일은 없습니다.

### README

- **새 PC에서는 셋째 세션부터 `dadeumi:dadeumi`를 쓸 수 있다고 적었습니다.** 설치 기록을 지우고 `settings.json`의 두 키만 남긴 채 headless 세션을 세 번 띄워 확인했습니다. 첫 세션은 마켓플레이스를 등록했고(`autoUpdate: true`는 유지됨), 둘째 세션은 플러그인 1.1.1을 설치했고, 셋째 세션에서 skill 목록에 `dadeumi:dadeumi`가 나왔습니다.

## v2026.10.14.3 (2026-10-14)

README의 스킬·플러그인 개수를 v2026.10.14 변경에 맞췄습니다. 설정과 파일은 바뀌지 않았으므로 복원할 때 따로 할 일은 없습니다.

### README

- **설치 단계 설명의 스킬 개수를 19종(직접 관리 7종)으로 고쳤습니다.** v2026.10.14에서 `dadeumi`를 뺄 때 트리 주석만 고치고 이 줄은 그대로 두었습니다.
- **플러그인 표에 `dadeumi`를 추가하고 제목을 "활성 13종"으로 고쳤습니다.** `dadeumi`는 setup의 설치 명령이 아니라 `settings.json`의 마켓플레이스 등록으로 새 세션에서 설치됩니다.

## v2026.10.14.2 (2026-10-14)

v2026.10.14의 `dadeumi-gate.js` 사본이 실행되지 않던 문제를 고쳤습니다. 상류 태그를 적은 주석을 첫 줄에 넣는 바람에 `#!/usr/bin/env node`가 둘째 줄로 밀려 Node가 구문 오류로 멈췄습니다. 훅은 오류만 내고 게시를 막지는 않았으므로 그동안 확인 기능이 꺼져 있었습니다. 복원할 때는 setup 스크립트를 다시 실행하면 됩니다.

### 훅

- **상류 태그 주석을 shebang 바로 아래 둘째 줄로 옮겼습니다.** 이 줄을 빼면 상류 v1.1.0 파일과 같습니다.

### CI

- **`ci.yml`이 둘째 줄을 뺀 나머지를 상류 파일과 `diff`하고, 그 전에 `node --check`로 사본의 구문을 검사합니다.** 이번 같은 오류가 다시 생기면 CI가 실패합니다.

## v2026.10.14 (2026-10-14)

`dadeumi` 스킬을 이 저장소에서 빼고 공개 저장소 [jelitz/dadeumi-korean-writing](https://github.com/jelitz/dadeumi-korean-writing)의 플러그인 `dadeumi@dadeumi`로 설치하도록 바꿨습니다. 지금까지는 같은 스킬을 두 저장소에서 따로 고쳐 왔습니다. 이제 원본은 공개 저장소 하나이고, 이 저장소에는 마켓플레이스 등록과 훅 사본만 남습니다. 공개판은 v1.1.0에서 비영리 조건(CC BY-NC-SA 4.0)이 붙은 배경 설명 파일을 지워 저장소 전체가 MIT가 됐습니다. 복원할 때는 setup 스크립트를 다시 실행하면 됩니다. 남아 있는 `~/.claude/skills/dadeumi/`를 지우고, 플러그인은 새 세션에서 자동으로 받습니다.

### 스킬

- **`config/skills/dadeumi/`를 지웠습니다.** 스킬 이름은 `dadeumi:dadeumi`가 됩니다. 직접 관리하는 스킬은 7종입니다.

### 설정

- **`settings.json`에 마켓플레이스와 플러그인을 등록했습니다.** `extraKnownMarketplaces.dadeumi`(GitHub `jelitz/dadeumi-korean-writing`, `autoUpdate: true`)와 `enabledPlugins`의 `"dadeumi@dadeumi": true`입니다. 새 세션에서 플러그인을 받고, 공개 저장소에 새 릴리스가 나오면 자동으로 갱신합니다.

### 훅

- **`config/scripts/hooks/dadeumi-gate.js`를 공개 저장소 v1.1.0의 `hooks/dadeumi-gate.js` 사본으로 바꿨습니다.** 첫 줄 주석에 상류 태그 URL을 적었고, 그 아래는 상류 파일과 같습니다. 동작은 같고 `../lib/utils` 대신 Node 기본 모듈만 씁니다. 이 파일은 여기서 고치지 않습니다. 상류를 고친 뒤 사본과 첫 줄의 태그를 함께 갱신합니다.

### CI

- **`.github/workflows/ci.yml`을 추가했습니다.** push·PR마다 훅 사본의 첫 줄을 뺀 나머지를 첫 줄에 적힌 태그의 상류 파일과 `diff`합니다.

### setup 스크립트

- **예전 사본 `~/.claude/skills/dadeumi/`를 한 번 지우는 단계를 넣었습니다.** 남아 있으면 스킬이 `dadeumi`와 `dadeumi:dadeumi` 두 벌로 잡히기 때문입니다. 지운 경로를 출력합니다. setup 스크립트가 파일을 지우는 단계는 이것 하나뿐입니다.

## v2026.10.13 (2026-10-13)

서브에이전트의 기본 모델을 `sonnet`으로 정했습니다. 지금까지는 `model`을 지정하지 않은 서브에이전트(pup Datadog 에이전트 48종, `general-purpose`, Workflow `agent()`)가 모두 세션 모델을 상속했습니다. 세션이 Fable 5.1이면 grep·목록 추출 같은 기계적 작업도 Haiku 5.5의 100배 단가로 돌았습니다. `CLAUDE_CODE_SUBAGENT_MODEL` 환경변수는 기본값일 뿐 강제가 아니라서 frontmatter `model`과 호출 시 `model` 파라미터가 이깁니다. 내장 `Explore`·`Plan`과 `model: inherit`인 `adversarial-reviewer`는 바뀌지 않습니다. 복원할 때 따로 할 일은 없습니다. 환경변수라 새 세션부터 적용됩니다.

### 설정

- **`settings.json` `env`에 `CLAUDE_CODE_SUBAGENT_MODEL: "sonnet"`을 추가했습니다.** 모델 결정 순서는 호출 시 `model` 파라미터 → 정의 frontmatter `model` → 이 환경변수 → 메인 모델입니다(공식 sub-agents 문서, 2026-10-13 확인). `_FORCE`는 켜지 않았습니다. 켜면 frontmatter를 무시해서 `adversarial-reviewer`까지 sonnet으로 내려갑니다. pup 에이전트는 `pup skills install claude`로 재생성해도 frontmatter에 `model`이 없으므로 이 기본값이 계속 적용됩니다.

### CLAUDE.md

- **서브에이전트 위임 절의 모델 선택 규칙에 한 구절을 더했습니다.** `model`을 생략하면 세션 모델이 아니라 sonnet이 적용되므로 최종 판정·적대적 검증·설계 종합처럼 세션 모델이 필요한 단계는 `model`을 명시합니다. frontmatter가 `inherit`인 `adversarial-reviewer`는 예외입니다.

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
