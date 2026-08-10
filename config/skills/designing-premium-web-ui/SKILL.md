---
name: designing-premium-web-ui
description: Use when the user asks to design a new website/landing page or redesign an existing site/UI with high visual quality — 신규 사이트 제작, 랜딩페이지, 기존 사이트 리디자인, "디자인 완성도 높게", "고급스럽게", "AI 티 안 나게", "촌스러워", redesign, premium design, high-fidelity UI
---

# Designing Premium Web UI

## Overview

핵심 원칙: **코드를 만지기 전에 시각 시안(Stitch mockup)으로 방향을 합의한다.** 신규/기존은 시작점만 다르고 이후 흐름은 동일하다.

## 첫 분기: 완성도 vs 속도

작업 시작 전 반드시 확인. 사용자가 빠른 프로토타입·일회성 데모를 원하면 Stitch 단계를 생략하고 `frontend-design` 스킬로 직행한다. "완성도 높게"가 목표일 때만 아래 전체 흐름을 탄다.

## Flow

| 단계 | 도구/스킬 | 사용자 게이트 |
|---|---|---|
| 1a. 기존 사이트 | `redesign-existing-projects`로 현재 디자인 감사 + playwright로 before 캡처 | 감사 결과 보고 |
| 1b. 신규 사이트 | `superpowers:brainstorming`으로 요구사항·무드 인터뷰 | requirements 승인 |
| 2. 방향 시안 | 스타일 스킬 후보 2~3개 선정(1안 = 1스킬, 혼합 금지) → `stitch-design-taste`로 DESIGN.md → `mcp__stitch__create_project` → `create_design_system_from_design_md` → `generate_screen_from_text` → `get_screen` 스크린샷 제시 | **시안 중 방향 선택** |
| 3. 시안 반복 | `mcp__stitch__edit_screens` / `generate_variants` | 최종 목업 확정 |
| 4. 코드화 | `frontend-design` + 선택된 스타일 스킬 + `tailwindcss` (토큰은 DESIGN.md 수치를 theme에 등록) | — |
| 5. 검증 | `playwright` 스크린샷 ↔ 목업 대조, 반응형 3뷰포트, 콘솔 에러, 대비비·reduced-motion | before/after 보고 |

## Stitch 프롬프트 규칙

공식 프롬프트 가이드(discuss.ai.google.dev/t/stitch-prompt-guide/83844) 기반.

**생성(generate_screen_from_text)**
- **평문으로 작성** — XML 태그·JSON 구조 금지, 5,000자 이하. 과밀한 단일 프롬프트는 컴포넌트 누락을 유발한다(초기 정확도 ~60% 전제, 반복으로 수렴).
- 복잡한 화면은 프롬프트를 분할한다: ① 핵심 구조 → ② 필터·부가 컴포넌트 → ③ 미세 조정. 여러 기능 요청을 한 프롬프트에 섞으면 레이아웃이 무너진다.
- 무드는 형용사로("minimalist and focused", "vibrant and encouraging"), 색은 구체적 색명 또는 무드 기반으로 지정. 이미지가 필요한 화면은 원하는 이미지의 내용·스타일까지 서술한다.
- mockup에는 **실제 콘텐츠**(실제 헤드라인·섹션 구성)를 넣는다. lorem ipsum이면 비교 판단이 불가능하다.
- 프롬프트 본문은 영어로 작성한다(UI 용어 인식률이 안정적). 화면에 표시될 콘텐츠 문안은 실제 언어 그대로 둔다.
- 이후 추가할 컴포넌트(필터 행 등)의 자리는 생성 시점에 빈 영역으로 예약해두면, 나중에 추가할 때 레이아웃 재생성을 막을 수 있다.

**수정(edit_screens)**
- **한 프롬프트에 하나의 화면, 1~2개의 변경만.** Stitch는 이전 디자인 결정을 잘 유지하지 못해, 동시 다발 요청은 레이아웃 전체 재생성을 유발한다.
- 대상 요소를 UI/UX 용어로 정확히 지정한다: "hero section의 이미지", "sign-up form의 primary button", "header의 navigation bar".
- 테마 색을 바꿀 때는 이미지·아이콘도 새 팔레트에 맞추라는 지시를 함께 넣는다.
- 성공한 반복마다 `get_screen`으로 스크린샷 URL을 확보해둔다(회귀 시 복원 기준).

**공통**
- 프롬프트 작성은 `design-first-ui-prompting` 규칙을 따른다.
- 목업은 방향 합의용이다. 코드와 픽셀 단위로 같지 않을 수 있고, 어긋날 때 기준은 DESIGN.md의 수치다.

## Fallbacks — 의존 스킬·도구가 없을 때

이 스킬이 참조하는 스킬·MCP가 설치되어 있지 않아도 흐름 자체는 유지한다. 없는 것은 아래로 대체하고, 대체했다는 사실을 사용자에게 명시한다.

| 없을 때 | 대체 방법 |
|---|---|
| `superpowers:brainstorming` | 내장 질문 도구(AskUserQuestion)로 직접 인터뷰: 목적·타깃, 실제 콘텐츠 확보 여부, 레퍼런스 2~3개(싫어하는 것 포함), 다크/라이트·모션 강도, 스택·배포 대상 |
| `redesign-existing-projects` | 직접 감사: before 스크린샷 확보 후 제네릭 패턴 점검 — 기본 폰트 스택(system-ui/Inter 단독), 보라~파랑 그라디언트, 균등 3열 카드, 이모지 아이콘, 섹션 여백 부족, 균일한 radius, 카드 속 카드 |
| `stitch-design-taste` | DESIGN.md 직접 작성: 컬러 토큰(hex), 타이포 스케일(폰트·크기·굵기·행간, 단계비 1.25 이상), 스페이싱(4px 기반), radius, 모션 규칙을 전부 수치로 명시 |
| Stitch MCP 미설정 | 시안을 정적 HTML 목업으로 대체: 방향별 단일 HTML 파일 제작 → 스크린샷 제시 → 선택 후 목업은 폐기하고 DESIGN.md 기준으로 본 구현 |
| `frontend-design` / 스타일 스킬 | 위 감사 체크리스트를 금지 목록으로 삼고, 시작 전 단일 스타일 방향(무드·팔레트·타이포 성격)을 한 단락으로 선언한 뒤 전 섹션에 일관 적용 |
| `design-first-ui-prompting` | 시안 프롬프트에 레이아웃 구조·타이포 규칙·색·금지 사항을 명시적 제약 목록으로 나열 |
| `playwright` | claude-in-chrome MCP로 대체, 둘 다 없으면 사용자에게 수동 확인 요청 |

## Common Mistakes

- **시안 합의 없이 바로 코드 직행** — 말로 합의한 "고급스럽게"는 반드시 어긋난다
- 기존 사이트에서 감사·before 캡처 생략 — 개선 근거와 회귀 비교 기준이 사라진다
- 스타일 스킬 여러 개 혼합 — 관점 없는 제네릭 결과의 주원인
- Stitch 목업을 최종 픽셀 스펙으로 취급 — 기준은 DESIGN.md
- 속도가 목표인 사용자에게 전체 흐름 강제 — 첫 분기를 건너뛰지 말 것
