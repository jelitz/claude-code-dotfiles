---
name: sdd
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
| `requirements.md` | 요구사항 · 승인기준 · 범위 외(out of scope) · E2E 검증 절차. 통과/실패를 판정하는 명령까지 적는다. 가능하면 EARS 표기: "WHEN ~ THEN 시스템은 ~해야 한다" |
| `design.md` | 아키텍처 · 시퀀스 · 인터페이스 |
| `tasks.md` | 체크리스트 ✅/⬜ · 의존관계 |
| `implemented.md` | 설계 결정(명세가 모호해 내린 선택) · 의도적 편차와 이유 · 트레이드오프 · 미결 질문 |

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
| brainstorming builder check | `requirements.md` 교차 검토를 대신한다 — adversarial-reviewer를 또 돌리지 않는다 |
| `docs/superpowers/specs/`, `docs/superpowers/plans/` 기본 경로 | 쓰지 않는다. 위 `docs/specs/{feature-name}/`가 사용자 선호 경로다 |

## 예시 (requirements.md 승인기준 한 줄)

> WHEN 관리자가 쿠폰 코드를 중복 등록하면 THEN 시스템은 409를 반환하고 기존 쿠폰을 변경하지 않아야 한다. 검증: `pytest tests/e2e/test_coupon.py::test_duplicate_code -q` 통과.
