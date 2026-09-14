# browser-automation 근거

SKILL.md의 규칙이 어디서 왔는지. 규칙을 고칠 때 이 파일을 먼저 갱신한다.

## 실측 (2026-09-14, Windows 11, Aside 1.26.906, 각 시나리오 1회)

| 시나리오 | Aside (`aside exec`) | claude-in-chrome | Playwright MCP |
|---|---|---|---|
| 1. Wikipedia 인포박스 3항목 추출 | 성공. `locator.screenshot()` Invalid parameters 오류(추출 무관) | 성공, `get_page_text` 2스텝 | 성공. `browser_find`만으론 행 매칭 부정확 → `browser_evaluate`로 표 파싱 |
| 2. Selenium 데모 폼 입력·제출 | 성공. 지시문 "두 번째 옵션"을 안내문 제외로 해석해 'One' 선택(다른 둘은 'Two' 지정 — 동일 지시문 재실행 안 함) | 성공. ref 클릭·`type`이 이벤트 미발생 → `form_input` + 좌표 클릭, 8스텝 | 성공, 4스텝 |
| 3. alert/confirm/prompt | 성공. `p.once`/`addListener` undefined, `page.on('dialog')` 미발화 → `window.prompt` 오버라이드로 해결 | 성공. 사전 오버라이드 후 클릭, 확장 정지 없음. ref 클릭 실패 → 좌표 클릭 | 성공. 클릭 응답에 Modal state → `browser_handle_dialog` |
| 4. google.com 로그인 상태 | 로그인 계정 인식(별도 검색 테스트 스냅샷 재사용) | 로그인 아바타 노출 | 미로그인 — 별개 프로필에 로그인한 적 없음 |
| 5. broken_images 404 탐지 | 성공. `page.on('response'/'requestfailed'/'console')` 미발화 → `fetch()` 상태코드로 확인 | 성공. `read_network_requests`가 호출 이후만 캡처 → 재navigate | 성공. `browser_network_requests` filter로 즉시 |

하네스: Gmail 읽지 않은 메일 수 요청은 Claude Code auto-mode 분류기가 PII로 차단(도구 무관).

한계: 각 1회. Aside 2·4는 동일 지시문 재실행 없음. claude-in-chrome ref 클릭 실패 원인(스테일 ref? viewport 타이밍?) 미규명 — 문서는 ref를 권장하므로 "ref 우선, 실패 시 폴백"으로 기재.

## 문서·이슈

- Aside 블로그 "How we built the SOTA browser agent that outperforms Fable" (aside.com/blog, 2026-06-25): Playwright가 아닌 자체 구현 Asidewright, "interface is 100% identical to Playwright", 에이전트 시그널 예시는 popup/download/tab closed. dialog·response 이벤트는 언급 없음 — 미지원 확인은 아님. `aside guide repl` 출력도 `waitForEvent('download')`만 예시.
- code.claude.com/docs/en/chrome 트러블슈팅: "JavaScript dialogs block browser events and prevent Claude from receiving commands. Dismiss the dialog manually."
- anthropics/claude-code #25518 (2026-02-13): 좌표 기반 `computer`(CDP 디버거)는 복잡한 페이지에서 detach; `read_page`/`find`/`form_input`/ref 클릭은 stable.
- anthropics/claude-code #90192: Outlook Web에서 `type` 앞 글자 누락, `form_input` 성공 보고 후 no-op(React controlled input). ref 경로도 완벽하지 않음.
- dev.to (2026-07-11), q2bstudio.com (2026-07-29): viewport innerWidth가 로드 후 2–3초 더 변해 좌표가 오른쪽으로 밀림. 권장: 좌표 → ref, 스크린샷 직후 즉시 클릭, ref는 리렌더 시 stale.
- playwright.dev/mcp/tools/dialogs: dialog 발생 시 다른 도구 응답에 "⚠ Dialog appeared", `browser_handle_dialog { accept, promptText }`.
- playwright.dev/mcp/configuration/user-profile, github.com/microsoft/playwright-mcp README: 기본 persistent profile(로그인 유지, 위치 `%LOCALAPPDATA%\ms-playwright\mcp-{channel}-profile`), `--isolated`, `--storage-state`, `--user-data-dir`, `--cdp-endpoint`, `browser_storage_state`/`browser_set_storage_state`.
- code.claude.com/docs/en/memory: auto memory는 프로젝트별·machine-local, CLAUDE.md는 규칙 전용, 작업별 세부는 skill로 — 이 내용이 CLAUDE.md가 아니라 skill에 있는 이유.

## 추론(실측 없음)

- localhost UI 검증에 Playwright: 별개 프로필이라 실제 세션 오염이 없다는 데서 나온 추론.
- "다단계 위임"이 Aside의 우위: 실측 시나리오는 모두 단일 페이지·단발. 근거는 `aside guide`의 "think of it like spawning subagent"뿐.
- claude-in-chrome이 사용자 브라우징을 방해: 실제 탭 점유는 관찰, 방해 정도는 미측정.

## 미결

- 봇 차단 사이트·파일 다운로드·비용(토큰/과금) 3도구 비교 없음.
- Playwright MCP 플러그인이 현재 persistent인지 isolated인지 미확인(미로그인 관찰은 둘 다와 일치).
- claude-in-chrome ref 클릭 실패 재현 조건.
