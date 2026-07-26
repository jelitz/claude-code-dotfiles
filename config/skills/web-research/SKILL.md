---
name: web-research
description: Use when performing web search or URL fetch with Exa, Jina, or insane-search — choosing search parameters (numResults, type, maxAgeHours, maxCharacters), fetching full text, needing fresh/realtime results, or hitting 403/paywall/blocked pages
---

# Web Research

웹 검색·fetch 도구별 세부 파라미터와 폴백 동작. 도구 우선순위 체인(Exa → Jina → insane-search → claude-in-chrome)은 글로벌 CLAUDE.md 참조.

## Exa MCP

- 검색 `web_search_exa`, URL 본문 확인 `web_fetch_exa`. 코드 컨텍스트·회사·사람 검색 등 전용 도구가 있으면 그것을 우선
- 기본 파라미터: 자연어 쿼리 · `type: auto` · `numResults: 5-10` · `contents.highlights: true`
- full text가 필요할 때만 `maxCharacters` 명시 — 기본 highlights로 충분한 경우가 대부분
- 실시간성이 꼭 필요할 때만 `contents.maxAgeHours: 0` — 캐시 우회는 느리고 비쌈

## Jina (Exa로 부족할 때)

- URL 접근: `https://r.jina.ai/<URL>`
- 검색: `https://s.jina.ai/<query>`

## insane-search (403/차단 폴백)

- 공개 페이지 전용. 로그인·페이월은 뚫지 않고 "authentication required"로 종료
- X/Twitter, Reddit, YouTube, Naver 등 WAF 보호 플랫폼 접근 시 사용

## Quick Reference

| 상황 | 설정 |
|---|---|
| 일반 검색 | `type: auto`, `numResults: 5-10`, `contents.highlights: true` |
| 전체 본문 필요 | `maxCharacters` 명시 |
| 실시간·최신 데이터 필수 | `contents.maxAgeHours: 0` |
| Exa 실패/부족 | `r.jina.ai/<URL>` 또는 `s.jina.ai/<query>` |
| 403·차단·WAF | insane-search 스킬 (공개 페이지만) |
