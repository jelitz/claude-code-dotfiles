---
name: web-research
description: Use when choosing between Exa, Firecrawl, WebSearch/WebFetch, or insane-search for a web search or URL fetch — including fresh/realtime needs, JS-rendered pages, or 403/CAPTCHA/blocked pages
---

# Web Research

도구 선택만 다룬다. 명령·파라미터 상세는 각 도구 스키마와 `firecrawl:*` 스킬을 따른다.

## 고르는 법

| 상황 | 도구 |
|---|---|
| 일반·한국어·최신 뉴스 검색 | Exa `web_search_exa` |
| 날짜·도메인·카테고리 필터 | `mcp__exa__web_search_advanced_exa` |
| 영어 사실 교차검증 | WebSearch |
| 정적 URL 본문 | Exa `web_fetch_exa` |
| JS 렌더링·CAPTCHA·403·최신본 필요 | Firecrawl scrape |
| 여러 페이지·사이트 구조·클릭·변경 감시 | Firecrawl (map·crawl·interact·monitor 스킬) |
| 위 도구가 모두 실패 | insane-search → 브라우저 |

## 함정 (틀리기 쉬운 기본값)

- Exa `web_fetch_exa`는 기본 3,000자에서 자른다 → 긴 문서는 `maxCharacters` 지정
- WebFetch는 원문이 아니라 작은 모델의 요약을 준다 → 수치·표·인용에는 쓰지 않는다
- WebSearch는 제목·URL만 주고 한국어 질의에 약하다(US-only)
- Firecrawl은 기본 2일 캐시 → 최신본은 `--max-age 0`, 메뉴·광고 제거는 `--only-main-content`
- Firecrawl 무료 플랜은 동시 2개·분당 10회 → 병렬은 2개씩
