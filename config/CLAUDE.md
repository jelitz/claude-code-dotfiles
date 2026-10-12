# CLAUDE.md — User Global

모든 프로젝트에 공통 적용되는 개인 원칙. 프로젝트 고유 규칙은 해당 repo의 `./CLAUDE.md`에 둠.

## 자율성과 안전

- 외부에 보이는 작업(PR/이슈 코멘트, 메시지·이메일 발송)은 실행 전 확인
- 파괴적 명령(rm -rf, git push --force, git reset --hard, git clean -f)은 `destructive-command-gate` 훅이 확인 프롬프트를 강제하고 `--no-verify`는 차단한다 — 훅에 막히면 우회하지 말고 원인을 고칠 것

## 작업 흐름

- diff를 한 문장으로 설명할 수 있으면 계획 생략. 그 이상이면 계획을 먼저 보인다
- 요청된 범위에서 요청된 것을 전달. 해석 차이가 결과물을 실질적으로 바꿀 때만 확인 질문. 작업 전체를 완료한 뒤에만 완료 보고
- 과잉 엔지니어링 방지: 요청 없는 기능 추가·리팩토링·추상화 금지, 일회성 작업에 헬퍼 불필요, 발생할 수 없는 시나리오용 에러 처리·검증 금지 — 검증은 시스템 경계(사용자 입력, 외부 API)에서만
- 동일 접근 2회 실패 시 중단하고 재판단 — 현재 목표·관련 파일·실패한 명령과 출력만 갖고 새 컨텍스트에서 재시작
- 큰 기능은 구현 전 인터뷰(내장 질문 도구)로 스펙 확정 — 명백한 질문은 피하고, 사용자가 고려하지 않았을 어려운 부분을 파고들 것
- 대규모·위험 변경 전 git 체크포인트 확보 — /rewind 체크포인트는 Bash로 일어난 변경을 추적하지 못함

## 기획 문서 (SDD)

- 큰 기능(위 인터뷰 기준)은 `writing-sdd-blueprints` 스킬을 호출해 `docs/specs/{feature-name}/`에 requirements → design → tasks를 쓰고 각 단계 전환 전 사용자 승인을 받는다. 프로젝트 `./CLAUDE.md`가 자체 문서 컨벤션을 명시하면 그것이 우선
- `tasks.md` 승인 뒤 구현은 새 컨텍스트에서 시작한다 — `/clear` 후 스펙 경로로 재개를 제안. 코드 변경마다 `tasks.md`·`implemented.md` 동기화

## 하네스 우선순위 (superpowers 7.x)

- 이 파일이 superpowers 스킬보다 우선한다(플러그인 자체 원칙). 어긋나면 이 파일을 따르고, 스킬은 실행 품질(TDD · systematic-debugging · verification-before-completion · worktrees · code-review)을 맡는다
- brainstorming의 "quick, clear task" 판정은 위 "diff를 한 문장으로 설명할 수 있으면 계획 생략"과 같은 기준이다. 그 경우 질문 없이 바로 수행한다. "small change"는 채팅 설명 1회 승인으로 끝낸다 — 문서를 만들지 않는다
- 큰 기능의 인터뷰는 brainstorming으로 하되 두 가지는 이 파일을 따른다. 질문은 내장 질문 도구(선택지 제시)로 묶어서 하고, 코드베이스 탐색은 허락을 구하지 않고 먼저 한다 — 탐색 결과가 질문의 질을 결정하기 때문
- 설계 문서는 docs/superpowers/specs가 아니라 `writing-sdd-blueprints` 스킬의 `docs/specs/{feature-name}/requirements.md` → `design.md` 순서로 나눠 쓰고 각각 승인을 받는다. writing-plans 산출물은 같은 폴더의 `tasks.md`로 저장한다
- brainstorming의 builder check가 돌았으면 requirements 교차 검토(adversarial-reviewer)는 생략하고, subagent-driven-development의 최종 코드 리뷰가 돌았으면 PR 전 adversarial-reviewer도 생략한다 — 같은 검토를 두 번 하지 않기 위함
- 서브에이전트에는 SessionStart 주입이 전달되지 않으므로 TDD · 검증 규율을 위임 프롬프트에 직접 쓴다

## 보고와 커뮤니케이션

- 진행·완료 보고 전 각 주장을 이번 세션의 실제 도구 결과와 대조 — 증거를 가리킬 수 있는 것만 보고하고, 미검증·실패·건너뛴 단계는 사실대로 명시
- 오래 지켜보지 않은 세션의 최종 보고는 재정립 방식으로: 작업 중 쓰던 속기·화살표 체인·임의 라벨을 버리고 완전한 문장으로, 식별자는 평이한 설명과 함께
- 검증된 근거 기반 내용과 추측을 구분 표기 — 추측은 `[제안]` prefix, 근거는 출처 명시

## 남이 읽을 글

- 사용자 본인이 아닌 사람이 읽게 될 글은 초안을 쓰기 전에 `dadeumi` skill을 호출한다. 기준은 독자다 — 어떤 도구·경로로 나가는지, Claude가 직접 올리는지 사용자가 가져다 쓰는지, 길이가 얼마인지는 기준이 아니다
- 예외: 커밋 메시지·코드 주석은 대상이 아니다. PR·이슈의 제목과 본문은 skill을 호출하지 않고 AI 말투와 모호한 표현만 훑어 고친다

## 서브에이전트 위임

- 몇 번의 도구 호출로 끝나는 작업은 직접 수행
- 탐색·grep 결과를 재확인하려고 서브에이전트를 띄우지 않기 — 그 검증은 메인 루프에서. 단 PR 전 diff는 `adversarial-reviewer` 에이전트(또는 `/code-review`)로 새 컨텍스트에서 1회 적대적 리뷰: 계획·요구사항 대비 누락과 정확성 결함은 심각도와 무관하게 전부, 스타일·취향 지적은 제외
- 독립적인 하위 작업은 서브에이전트에 맡기고 기다리지 않고 계속 진행한다. 단발 조사는 Agent 1회, 주고받기가 필요하면 name 붙여 spawn 후 SendMessage. 단계가 고정된 fan-out은 Workflow — 하네스가 사용자 옵트인을 요구하므로 먼저 제안한다
- 병렬 리뷰·경쟁 가설은 겹치지 않는 렌즈로 나누고 적대적으로 배치, 팀원별 파일 소유 분리
- Workflow `agent()`·Agent 도구는 세션 모델·effort를 그대로 상속하지 않고 단계 난이도에 맞춰 고른다 — `workflow-authoring`의 "model 생략" 기본값보다 이 규칙 우선. effort로 먼저 조절하고, 토큰 단가 차이가 큰 기계적 단계(grep·목록·추출·분류)만 `haiku`/`sonnet` + `effort: 'low'`로 내리며, 최종 판정·적대적 검증·설계 종합은 세션 모델 유지

## 지식 관리

- 동일 유형 작업을 반복하거나 시행착오 끝에 패턴을 확립하면 skill 자산화(또는 memory 저장) 제안

## Environment

- Python + Windows 한글: 텍스트 I/O(open·read_text·write_text·sqlite)에 encoding="utf-8" 명시 — 팀원 PC·CI는 cp949 기본. 이 머신은 settings.json `env`와 Windows 사용자 환경변수로 UTF-8이 전역 설정돼 있어 로컬 실행에서는 누락이 드러나지 않으므로, 커밋되는 코드에는 그대로 명시한다. `py-encoding-check` 훅이 편집 직후 누락을 알려줌

## 도구

- 설치된 전용 CLI가 있으면 MCP·브라우저 자동화보다 우선 — 새 서비스를 다루기 전 해당 CLI 설치 여부부터 확인
- Google Workspace: `gws` CLI
- GitHub: issue / PR / release / API 조회는 `gh` CLI 우선
- 브라우저 자동화: 서비스 전용 CLI(gws·gh 등)가 없거나 안 될 때만. Aside·claude-in-chrome·Playwright MCP 중 선택 기준과 도구별 주의점은 `browser-automation` skill 참조
- codex plugin: job은 `--background`로 실행하고 status 폴링으로 결과 수거 — foreground는 무한 hang 가능. hang 시 `--fresh` + 좁은 프롬프트로 새 Agent 실행, plugin 경로가 계속 실패하면 `codex exec --sandbox read-only ... | tee <log>`를 Bash `run_in_background`로 직접 호출
- 라이브러리·프레임워크의 API·버전별 문서는 context7 MCP(라이브러리 ID 조회 → 문서 조회) 먼저. 도구 목록에 인증 스텁만 보이면 미연결이니 `/mcp` 인증을 안내하고, 결과가 없으면 아래 웹 검색 체인으로
- 웹 검색·fetch: Exa MCP → Firecrawl(JS·차단·사이트 단위) → insane-search → 브라우저. 도구 선택 세부는 `web-research` skill. 공식 SDK·프레임워크·플랫폼 조작은 해당 공식 CLI 우선
- 최신성이 중요한 정보는 검색으로 확인하고 출처 링크·날짜와 함께 답변
- 툴 호출 파라미터(JSON)의 한글 등 비ASCII 문자열은 항상 리터럴 UTF-8로 작성하고, \uXXXX 유니코드 이스케이프로 표기하지 않는다

## Compaction·긴 세션

- 압축(Compaction) 시 수정된 파일 목록 전체와 테스트 명령어를 항상 보존
- 긴 작업은 진행 상황을 파일·메모리에 저장해 압축·재개 후에도 이어갈 수 있게 함
