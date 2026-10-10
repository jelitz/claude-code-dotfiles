# 릴리스 노트

버전은 스냅샷 날짜(`vYYYY.MM.DD`)입니다. 같은 날 두 번째 릴리스부터는 `.2`, `.3`을 붙입니다.

## v2026.10.11 (2026-10-11)

이 저장소의 첫 버전 릴리스입니다. 9월 17일 스냅샷 이후 바뀐 PC 설정을 다시 맞췄습니다. 웹 검색 도구 체인에서 Jina를 빼고 Firecrawl을 넣었고 위험한 명령과 Python 인코딩 누락을 잡는 훅 두 개를 추가했습니다. 이 버전부터 변경 이력을 이 파일과 GitHub Release에 함께 남깁니다.

### 웹 검색

- **웹 검색·fetch 체인을 Exa → Firecrawl → insane-search → 브라우저로 바꿨습니다.** Jina는 CAPTCHA·403 페이지에서 본문을 가져오지 못했고 검색(`s.jina.ai`)은 API 키 없이는 막혀 있어서 체인에서 뺐습니다. JS 렌더링이나 봇 차단이 있는 페이지는 Firecrawl이 맡습니다.
- **`web-research` 스킬을 도구 선택표와 함정 5줄로 줄였습니다.** 요금·플랫폼 지원 같은 참고 정보와 CLI 옵션 상세는 뺐습니다. 옵션은 각 도구 스키마와 firecrawl 플러그인 스킬이 이미 설명합니다. 함정에는 Exa fetch의 3,000자 제한, WebFetch가 원문 대신 요약을 준다는 점, Firecrawl의 기본 2일 캐시를 적었습니다.
- **CLAUDE.md의 웹 검색 규칙을 한 줄로 줄이고 세부는 `web-research` 스킬로 넘겼습니다.**

### 훅

- **`destructive-command-gate` 훅을 추가했습니다.** git 명령의 `--no-verify`는 거부하고 `rm -rf`·`git push --force`·`git reset --hard`·`git clean -f`는 auto 모드에서도 확인을 받습니다. CLAUDE.md에 권고로만 있던 규칙을 훅으로 옮겼습니다.
- **`py-encoding-check` 훅을 추가했습니다.** `.py` 파일을 저장하면 `encoding=` 없이 텍스트를 읽고 쓰는 호출을 찾아 Claude에게 알립니다. 차단하지는 않습니다.

### 플러그인

- **superpowers를 superpowers-marketplace 판으로 바꿔 켰습니다.** 스킬과 CLAUDE.md가 어긋날 때 무엇을 따를지는 CLAUDE.md의 "하네스 우선순위" 절에 정리했습니다.
- **firecrawl, sentry, typescript-lsp, pyright-lsp를 켰습니다.** setup 스크립트가 설치하는 활성 플러그인은 12종이 됐습니다.
- **example-skills, security-guidance, code-simplifier, pr-review-toolkit는 껐습니다.** setup 설치 목록에서 빠졌고 `plugins/installed_plugins.json`에는 비활성으로 기록했습니다.

### 스킬·에이전트

- **`adversarial-reviewer` 에이전트를 추가했습니다.** PR을 열기 전 diff를 새 컨텍스트에서 적대적으로 검토합니다.
- **디자인 스킬 5종을 뺐습니다.** 현재 PC 설정에 없기 때문입니다. pup이 만드는 Datadog 스킬 11종과 에이전트 48종은 복원용으로 그대로 둡니다.

### 설정

- **`settings.json`에 env(`PYTHONUTF8`·`PYTHONIOENCODING`), 모델별 effort, `skillOverrides`, 새 훅 등록을 반영했습니다.** 기본 모델은 `opus`로 바뀌었습니다.
- **조직 정보가 들어 있는 `autoMode` 설정, 프로젝트 종속 권한, 로컬 폴더 마켓플레이스는 저장소에 넣지 않았습니다.**

### 릴리스

- **버전 태그와 릴리스 노트를 도입했습니다.** `v*` 태그를 push하면 GitHub Actions가 이 파일에서 해당 버전 절을 뽑아 Release를 만듭니다. 태그가 `VERSION` 파일이나 README 배지와 다르면 실패합니다.

### 이 버전으로 복원할 때

- Firecrawl CLI를 설치하고 로그인합니다: `npm install -g firecrawl-cli` 실행 후 `firecrawl login --browser`
- Exa MCP를 user 스코프로 등록합니다: `claude mcp add --transport http -s user exa "https://mcp.exa.ai/mcp?tools=web_search_exa,web_search_advanced_exa"`
