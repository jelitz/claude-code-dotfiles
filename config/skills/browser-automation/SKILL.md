---
name: browser-automation
description: Use when a task needs a browser — opening a site, filling forms, reading a logged-in account page (Gmail, Slack, Notion, SaaS consoles), verifying UI on localhost, handling alert/confirm/prompt dialogs, or inspecting console/network — and you must choose between aside exec, claude-in-chrome MCP, and Playwright MCP, or one of them is misbehaving (clicks not registering, dialog hang, missing login session, page.on listeners never firing)
---

# Browser Automation — 도구 선택과 주의점

## Overview

세 도구는 같은 일을 다른 방식으로 한다. Aside는 별도 브라우저 안의 자체 에이전트에 자연어로 위임하고 결과만 받는다. claude-in-chrome은 사용자의 실제 Chrome 탭을 내가 한 스텝씩 조작한다. Playwright MCP는 내 Chrome과 별개인 자체 프로필 브라우저를 결정적으로 제어한다. 서비스 전용 CLI(`gws`·`gh` 등)가 있으면 브라우저보다 먼저다.

## 선택 기준

| 상황 | 도구 |
|---|---|
| 내 계정이 로그인된 사이트에서 여러 단계를 맡기고 결과만 받기 | `aside exec` |
| 내 Chrome 탭에서 화면을 보며 한 스텝씩 판단하며 진행 | claude-in-chrome |
| 로그인이 필요 없는 결정적·재현 작업, localhost UI 검증, dialog가 잦은 페이지, 내 세션과 분리해야 하는 작업 | Playwright MCP |
| 사용자가 도구를 지정 | 그 도구 |

로그인 상태는 Aside와 claude-in-chrome 둘 다 있으므로 선택 근거가 아니다. 갈리는 지점은 "위임하고 안 볼 것인가(Aside)" vs "보면서 조작할 것인가(claude-in-chrome)".

## aside exec

- 시작 전 `aside guide` 출력을 읽는다(`aside-browser` 스킬이 강제). 사이트별 내장 스킬은 `aside skills list` — Slack·Gmail·Notion·Google Docs/Sheets/Search·YouTube·LinkedIn·iMessage 제공(`aside guide repl` 기준).
- Bash `run_in_background`로 실행하고 output 파일에서 최종 결과를 읽는다.
- 지시문에는 대상 URL·계정, 할 일, 반환 형식, 그리고 중단 조건을 쓴다: "발송·결제·삭제·설정 변경 전에는 멈추고 보고". Aside 내부 에이전트는 이 세션의 확인 규칙을 모른다.
- 값은 명시한다. "두 번째 옵션" 같은 표현은 Aside가 안내문 포함 여부를 스스로 정한다.
- `aside repl`은 Playwright 문법이지만 자체 구현이다. `page.once`·`addListener`는 없고, `page.on('dialog'|'response'|'requestfailed'|'console')` 리스너는 발화하지 않았다(1.26.906, 2026-09-14 실측). dialog 값은 `page.evaluate`로 `window.alert/confirm/prompt`를 오버라이드해 넣고, HTTP 상태는 `(await fetch(url)).status`로 직접 확인한다(확인할 URL 목록은 `page.evaluate`로 `document.images`나 `performance.getEntriesByType('resource')`에서 뽑는다). `locator.screenshot()`은 Invalid parameters — `page.screenshot({ clip })`을 쓴다.

## claude-in-chrome

- 요소 조작은 ref 기반: `find` 또는 `read_page`로 ref를 얻고 `form_input`/ref 클릭. ref 클릭이 이벤트를 일으키지 않으면 `form_input`, 그다음 좌표 클릭(스크린샷 직후, 같은 `browser_batch` 안에서).
- alert/confirm/prompt가 뜰 수 있는 클릭 전에 `javascript_tool`로 오버라이드한다:

```js
window.__log = [];
window.alert = m => { window.__log.push('alert:' + m); };
window.confirm = m => { window.__log.push('confirm:' + m); return true; };
window.prompt = m => { window.__log.push('prompt:' + m); return '입력값'; };
```

  실제 네이티브 dialog가 뜨면 확장이 명령을 받지 못한다. 사용자가 손으로 닫아야 복구된다.
- `read_network_requests`는 호출 시점 이후의 요청만 캡처한다. 먼저 호출해 두거나 navigate를 다시 한다.
- 사용자의 실제 탭과 포커스를 점유한다. 사용자가 열려 있는 탭을 지목하면 `tabs_context_mcp`로 그 탭을 잡아 그대로 쓰고, 아니면 새 탭에서 작업하고 끝나면 닫는다. 값 읽기는 `get_page_text`(본문 전체) 또는 `javascript_tool`(DOM에서 직접 계산).

## Playwright MCP

- 프로필은 내 Chrome과 별개다. 기본은 persistent(한 번 로그인하면 유지), `--isolated`면 휘발. 로그인 상태가 필요하면 한 번 로그인하거나 `browser_set_storage_state`/`--storage-state`로 넣는다.
- dialog는 클릭 응답에 "Modal state"로 나타난다. `browser_handle_dialog { accept, promptText }`로 처리한 뒤 진행한다.
- `browser_find`는 인포박스 같은 표 구조에서 부정확하다. `browser_evaluate`로 직접 파싱한다. `browser_network_requests`는 `filter` 정규식을 받는다.
- 끝나면 `browser_close`.

## Common Mistakes

| 실수 | 결과 |
|---|---|
| Aside REPL에서 `page.on('dialog')`에 의존 | prompt가 빈 값으로 조용히 수락됨 |
| claude-in-chrome에서 dialog 버튼을 먼저 클릭 | 확장 정지, 사용자 수동 복구 |
| Playwright를 "로그인 불가"로 단정 | 별개 프로필일 뿐 — 한 번 로그인하면 유지 |
| 로그인 여부로 Aside를 고름 | claude-in-chrome도 같은 로그인 상태 |
| `aside exec`에 중단 조건 없이 위임 | 내부 에이전트가 발송·결제까지 진행할 수 있음 |

## 만료·재검증

- Aside: `aside --update` 후 REPL에서 `typeof page.once`와 `page.on('dialog')` 발화를 재확인. 동작하면 REPL 함정 항목 삭제.
- claude-in-chrome: 공식 문서 트러블슈팅에서 dialog 문구가 사라지거나 anthropics/claude-code #25518·#90192가 닫히면 재검토.
- Playwright MCP: 플러그인 기본 설정(persistent/isolated)이 바뀌면 프로필 항목 수정.
- 이 기준대로 골랐는데 "동일 접근 2회 실패" 규칙이 발동한 사례가 2건 쌓이면 개정.

근거·실측표·출처: 같은 폴더의 `evidence.md`.
