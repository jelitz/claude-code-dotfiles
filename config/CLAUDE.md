# CLAUDE.md — User Global

모든 프로젝트에 공통 적용되는 개인 글로벌 지침. 프로젝트 고유 규칙은 해당 repo의 `./CLAUDE.md`에 둠

## 사용자 인터뷰

**IMPORTANT:**

- 큰 기능의 경우 Claude가 내장된 도구를 사용하여 사용자 인터뷰를 적극 수행하도록 시도
  - 명백한 질문을 하지 말 것
  - 사용자가 고려하지 않았을 수 있는 어려운 부분을 파고들 것
  - 모든 것을 다룰 때 까지 인터뷰할 것을 권장
- 비용
  - 올바른 모델 선택
    - sonnet : 일일 코딩 작업을 위해 최신 Sonnet 모델을 사용합니다
    - opus : 복잡한 추론 작업을 위해 최신 Opus 모델을 사용합니다
    - haiku : 간단한 작업을 위해 빠르고 효율적인 Haiku 모델을 사용합니다
  - 시간이 많이 소요되는 스레드 시작 시 다음 두 가지를 설정:
    - 전달 체크포인트: 진행 전 결과물을 한 문장으로 명시(PR 제목·변경 파일·예상 명령 출력 등). (a) 10분 이상 수정 없거나 (b) 동일 접근 2회 실패 시 비정상으로 판단해 중단·재판단. 단일 수정에 2회 이상 재시도 금지
    - 새 컨텍스트 제약: 처음부터 다시 시작 — 현재 목표·관련 파일·실패한 명령/출력과 아래 제약만 사용, 작업 컨텍스트를 10개 항목 이내로 재작성
  - agent 관련 모델·비용 기준은 `agent-orchestration` skill 참조

## Environment

- **IMPORTANT:** Python + Windows 한글 파일 처리 시 기본 인코딩이 cp949 → 파일·sqlite I/O·표준출력(print) 모두 encoding="utf-8" 명시 (또는 `PYTHONIOENCODING=utf-8`)

## 작업 흐름

### 탐색과 실행 분리

- 권장 워크플로우: 탐색 → 계획 → 구현 → 커밋
- 범위가 명확하고 수정이 작은 작업(예: 오타 수정, 로그 줄 추가, 변수 이름 바꾸기)은 직접 수행 여부를 제안하거나 claude가 직접 판단 가능
- diff를 한 문장으로 설명할 수 있다면 계획을 건너뛰기

### 검증과 복구

- 완료 선언 전 관련 검증 명령(빌드·테스트·lint)을 실행하고 실제 출력 확인 — 출력 없이 성공 주장 금지
- 대규모·위험 변경 전 git 체크포인트(커밋 또는 worktree) 확보 — /rewind 체크포인트는 Bash로 일어난 변경을 추적하지 못함

### 지식 관리

- 동일 유형 작업을 반복하거나 시행착오 끝에 패턴을 확립하면 skill 자산화(또는 memory 저장)를 제안
- 검증된 근거(코드·문서·공식 출처) 기반 내용과 추측성 제안은 구분 표기 — 추측은 `[제안]` prefix, 근거는 출처 명시

### Compaction

- 압축(Compaction)할 때는 수정된 파일 목록 전체와 테스트 명령어를 항상 보존

## 기획 문서 (SDD)

프로젝트 `./CLAUDE.md`가 자체 문서 컨벤션을 명시하면 그것을 따르고, 명시하지 않으면 기본값으로 Kiro IDE 스타일 SDD(steering/specs 분리)를 따름. 적용 시점은 위 "사용자 인터뷰" 절의 큰 기능 기준과 동일 — 인터뷰 결과가 곧 requirements.md의 출발점.

- 전역 컨텍스트 `docs/steering/`: `product.md`(비전·타깃·핵심가치) · `tech.md`(스택·아키텍처 제약·의존성) · `structure.md`(디렉터리·네이밍·모듈 경계) — 거의 안 바뀜, 기능 작업마다 재작성 금지
- 기능 명세 `docs/specs/{feature-name}/`: `requirements.md`(요구사항·승인기준·검증 계획(빌드·테스트·스모크 방법), 가능하면 EARS 표기: "WHEN ~ THEN 시스템은 ~해야 한다") · `design.md`(아키텍처·시퀀스·인터페이스) · `tasks.md`(체크리스트, ✅/⬜·의존관계)
- `implemented.md`: 설계 결정(명세가 모호해 내린 선택) · 편차(의도적으로 스펙과 다르게 간 부분과 이유) · 트레이드오프(고려한 대안과 선택 이유) · 미결 질문(확인·수정 필요 사항)
- 기능 2개 이상 동시 진행 시 문서 충돌 방지를 위해 반드시 `{feature-name}` 폴더로 분리

**YOU MUST:**

- requirements → design → tasks 순서로 작성, 각 단계 전환 전 사용자 승인 (건너뛰고 구현 직행 금지)
- 코드 변경(신규·수정·폐기)마다 `tasks.md` 체크박스·`implemented.md` 동기화
- PR 전 코드·테스트·배포 상태와 문서 일치 확인, 불일치 시 동일 PR 또는 별도 `docs:` 커밋으로 동기화
- steering 문서는 프로젝트 전역 성격이 실제로 바뀔 때만 갱신 — 기능 작업마다 건드리지 않음

## 효과적인 Claude.md 작성

- 필수적인 형식은 없지만 짧고 간결하게 인간이 읽을 수 있도록 유지
- 각 줄에 대하여 "이것을 제거하면 claude가 실수할까" 라는 질문을 해보고, 그렇지 않다면 불필요하다고 판단
- 광범위하게 적용되는 것만 포함
- 도메인 지식, 일부만 관련된 워크플로우, 다단계 절차, 코드베이스의 한 부분에만 중요한 경우에는 대신 skill 또는 경로 범위 규칙 사용
- 반드시 200줄 이하로 작성
- 필요한 경우 경로 규칙 범위를 사용하여 지침이 로드되도록 구성
- 검증할 수 있을 정도로 구체적인 지침을 작성

## 내장 도구 사용

- 확장 도구는 목표에 맞는 기능을 선택하여 사용

### Agent

- 병렬 작업 검토, subagent vs agent team 선택, 팀 구성·운영 판단 시 반드시 `agent-orchestration` skill 로드 후 진행

### 브라우저 자동화

- 기본: `claude-in-chrome` MCP (`mcp__claude-in-chrome__*` 도구)
- Playwright 등 다른 도구는 사용자가 명시 요청하거나 claude-in-chrome으로 불가한 경우에만 사용

### GitHub

- issue / PR / release / API 조회는 `gh` CLI 우선

### codex plugin

- **IMPORTANT:** codex job은 항상 `--background`로 실행하고 status 폴링으로 결과 수거 (foreground는 무한 hang 가능 — v1.0.4 타임아웃 부재 확인됨)
- hang 발생 시 재시도는 `--fresh` + 좁은 프롬프트로 새 Agent 실행 (새 broker 기동됨)
- plugin 경로가 계속 실패하면 `codex exec --sandbox read-only ... | tee <log>`를 Bash `run_in_background`로 직접 호출

### CLI 도구 사용

- 사용 가능한 경우 CLI 도구 선호
  - CLI 도구가 없는 경우 다른 도구를 활용할 수 있는 지 탐색

## URL fetch / 웹 검색

- 웹 검색·fetch 우선순위: Exa MCP → Jina → insane-search 스킬 → claude-in-chrome → 그 외
  - Exa: 웹 검색 `web_search_exa`, URL 본문 확인 `web_fetch_exa`. 코드 컨텍스트·회사·사람 검색 등 전용 도구 있으면 그것 우선
  - Jina(Exa로 부족할 때): URL 접근 `https://r.jina.ai/<URL>`, 검색 `https://s.jina.ai/<query>`
  - insane-search(앞의 둘이 403/차단으로 막힐 때): 공개 페이지 전용 폴백. 로그인·페이월은 뚫지 않고 "authentication required"로 종료
- 공식 SDK·프레임워크·플랫폼 조작은 해당 공식 CLI 우선
- 기본 검색 파라미터: 자연어 쿼리 · `type: auto` · `numResults: 5-10` · `contents.highlights: true`
- 최신성 중요한 정보는 검색으로 확인, 출처 링크·날짜 함께 답변
- full text 필요시만 `maxCharacters` 명시, 실시간성 꼭 필요시만 `contents.maxAgeHours: 0`

@RTK.md
