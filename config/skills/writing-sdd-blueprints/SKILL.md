---
name: writing-sdd-blueprints
description: Use when a feature is big enough to need a spec before code — writing or updating requirements.md, design.md, tasks.md, implemented.md under docs/specs/{feature}/, or docs/steering/ context files (Kiro-style spec-driven development). Also use when superpowers brainstorming or writing-plans produces a design document or plan and it has to be saved in this layout.
---

# SDD (Kiro 스타일 기획 문서)

프로젝트 `./CLAUDE.md`가 자체 문서 컨벤션을 명시하면 그것을 따른다. 없으면 이 레이아웃이 기본값이다. 적용 시점은 글로벌 CLAUDE.md의 "큰 기능" 기준과 같다 — brainstorming의 project 판정과 동일하고, quick·small 변경에는 문서를 만들지 않는다.

## 파일 레이아웃

전역 컨텍스트 `docs/steering/` — 프로젝트 전역 성격이 실제로 바뀔 때만 갱신하고 기능 작업마다 재작성하지 않는다.

| 파일 | 내용 |
|---|---|
| `product.md` | 비전 · 타깃 · 핵심가치 |
| `tech.md` | 스택 · 아키텍처 제약 · 의존성 |
| `structure.md` | 디렉터리 · 네이밍 · 모듈 경계 |

기능 명세 `docs/specs/{feature-name}/` — 기능 2개 이상 동시 진행 시 폴더로 분리해 문서 충돌을 막는다.

| 파일 | 내용 |
|---|---|
| `requirements.md` | 요구사항 · 승인기준 · 범위 외(out of scope) · E2E 검증 절차. 통과/실패를 판정하는 명령까지 적는다. 가능하면 EARS 표기: "WHEN ~ THEN 시스템은 ~해야 한다". 끝에 **Assumptions** 절: 사용자가 정하지 않아 합리적 기본값으로 채운 항목과 그 근거, 아직 못 정한 항목은 `[미확정: 질문]`으로 표시 |
| `design.md` | 아키텍처 · 시퀀스 · 인터페이스. 단순한 길(프레임워크 직접 사용, 모델 표현 하나, 추상화 없음)을 벗어나는 결정이 있으면 **Complexity Tracking** 표(결정 · 왜 필요한가 · 더 단순한 대안을 버린 이유) |
| `tasks.md` | 체크리스트 ✅/⬜ · 의존관계. 추가 전용: 완료된 과제는 고치거나 지우지 않고, 구현 뒤 드러난 남은 일은 끝에 새 절로 덧붙인다 |
| `implemented.md` | 설계 결정(명세가 모호해 내린 선택) · 의도적 편차와 이유 · 트레이드오프 · 미결 질문 |

유지 모델은 flow-back이다. 통찰이 생긴 산출물(코드·tasks·design·requirements 어디든)에서 먼저 고치고, 같은 변경으로 나머지 문서를 맞춘다. 더 이상 신뢰하지 않는 문장을 남겨 두지 않는다.

## 에픽 분할 (roadmap)

한 번의 requirements → design → tasks 사이클에 담기지 않는 기능은 먼저 `docs/specs/{epic-name}/roadmap.md`에 독립적으로 테스트 가능한 조각으로 나눈다. 로드맵은 조각의 이름과 순서만 정하고 설계는 하지 않는다. 각 조각은 자기 폴더 `docs/specs/{epic-name}-{slice}/`에서 보통 사이클을 돌고, `requirements.md` 첫 줄에 `상위 로드맵: ../{epic-name}/roadmap.md → R2`처럼 역참조한다. 조각 하나가 또 너무 크면 같은 방식으로 한 단계 더 나눈다. 과제 수 제한이나 서브에이전트 위임으로 해결되면 로드맵을 만들지 않는다.

| ID | 조각 | 의도 | 범위 경계(포함 / 다른 조각으로) | 의존 | 상태 | 스펙 |
|---|---|---|---|---|---|---|
| R1 | 청구서 조회 | 지난 청구서 열람·다운로드 | 읽기 전용 / 결제 행동은 R2 | — | done | `../billing-invoices/` |
| R2 | 결제수단 | 카드 추가·삭제·기본 지정 | 플랜 변경은 R3 | R1 | in-progress | `../billing-payment-methods/` |

ID는 스펙이 참조한 뒤로 바꾸지 않는다. 범위가 바뀌면 로드맵을 먼저 고치고 영향받는 조각 스펙을 맞춘다.

## 절차와 게이트

1. 인터뷰 결과가 `requirements.md`의 출발점이다. 인터뷰는 내장 질문 도구로 묶어서 하고, 코드베이스 탐색은 허락을 구하지 않고 먼저 한다.
2. `requirements.md` → `design.md` → `tasks.md` 순서로 쓰고 각 단계 전환 전 사용자 승인을 받는다.
3. `tasks.md` 승인 뒤 구현은 새 컨텍스트에서 시작한다 — 사용자에게 `/clear` 후 스펙 경로로 재개를 제안한다. 탐색·인터뷰 잔재로 오염된 컨텍스트를 피하기 위함이지 토큰 절약이 아니다.
4. 코드 변경마다 `tasks.md`·`implemented.md`를 동기화한다. PR 전 코드·테스트·문서 일치를 확인하고, 불일치는 동일 PR 또는 별도 `docs:` 커밋으로 맞춘다.

## superpowers와의 대응

| superpowers 산출물 | 이 레이아웃에서의 위치 |
|---|---|
| brainstorming 설계 문서(intent · goals/non-goals · constraints · 결정한 how) | `requirements.md`(intent · goals/non-goals · 승인기준)와 `design.md`(constraints · how)로 나눠 쓰고 각각 승인 |
| writing-plans 계획 | 같은 폴더의 `tasks.md` |
| brainstorming builder check | `requirements.md` 교차 검토를 대신한다 — adversarial-reviewer를 또 돌리지 않는다. builder check에서 "내 판단(Minor)"으로 정한 항목은 `requirements.md`의 Assumptions 절에, "사용자 몫(Theirs)"으로 남은 항목은 `[미확정: 질문]`으로 적는다 |
| writing-plans Self-Review(스펙 커버리지 · 단계 스캔 · 타입 일관성 · Review Focus · 비율) | `tasks.md` 승인 전 정합성 점검을 대신한다 — 별도 analyze 단계를 두지 않는다 |
| subagent-driven-development 최종 코드 리뷰 | PR 전 적대적 리뷰를 대신한다 — adversarial-reviewer를 또 돌리지 않는다. 인라인 실행(executing-plans)으로 구현했을 때만 adversarial-reviewer를 1회 돌린다 |
| `docs/superpowers/specs/`, `docs/superpowers/plans/` 기본 경로 | 쓰지 않는다. 위 `docs/specs/{feature-name}/`가 사용자 선호 경로다 |

## 예시 (requirements.md 승인기준 한 줄)

> WHEN 관리자가 쿠폰 코드를 중복 등록하면 THEN 시스템은 409를 반환하고 기존 쿠폰을 변경하지 않아야 한다. 검증: `pytest tests/e2e/test_coupon.py::test_duplicate_code -q` 통과.
