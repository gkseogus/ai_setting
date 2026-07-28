Vercel Observability 의 Edge Requests(Bot Name) 데이터를 뽑아 AEO(AI 답변엔진 최적화) 지표 리포트를 만들고 PDF 로 저장한다.

## 인자
$ARGUMENTS — 모두 선택. 자유 텍스트로 받는다.
- **프로젝트 범위**: `팀/프로젝트` 형태. 예) `rebstudios/reb-platform-frontend`. 비어 있으면 기본값 `rebstudios/reb-platform-frontend`.
- **기간(period)**: `24h` / `7d` / `30d` / `90d` 중 하나(Vercel `period=` 파라미터). 비어 있으면 `30d`.
- **환경(env)**: `Production` / `Preview` / `All`. 비어 있으면 `Production`.
- **출력 경로/파일명**: 예) `~/Desktop/reports`, `~/Desktop/aeo.pdf`. 비어 있으면 `~/Desktop/AEO_<프로젝트>_<기간>_<YYYY-MM-DD>.pdf`.
- 예시: `rebstudios/reb-platform-frontend 30d ~/Desktop/reports`

## 어디에 쓰는가
사이트에 **어떤 AI 답변엔진 크롤러(AEO 봇)** 가 얼마나 들어오는지 한 장으로 본다.
GPTBot·OAI-SearchBot·ClaudeBot·PerplexityBot·Google(Read-Aloud/Extended)·Meta AI 등 **답변엔진 봇의 유입량·점유율·캐시율**을 벤더별로 집계하고, 전체 봇(검색/SEO/소셜 포함)과 함께 보여준다.
근거 데이터는 Vercel Observability > Edge Requests > **Bot Name** 탭이다. 대시보드는 **읽기만** 한다.

## 무엇을 뽑는가 (AEO 지표 정의)
- **Total Edge Requests**: 기간 내 전체 엣지 요청 수(상단 Edge Requests 카드의 총계 표시값).
- **AI Crawler Requests**: 아래 분류에서 `ai` 로 분류된 봇들의 Requests 합계(≈, 표시값 단순 합).
- **AI Share**: AI 봇 합계 ÷ 식별된 봇 전체 합계(%). 부제로 전체 엣지 요청 대비 비율도 표기.
- **Top AI Crawler**: AI 봇 중 Requests 1위.
- **AI Answer Engines(벤더별)**: OpenAI / Anthropic / Google / Perplexity / Meta AI / Apple / Amazon / ByteDance / Cohere / Common Crawl … 브랜드 단위 합계·AI 내 점유율·가중 평균 캐시율.
- **Bot Name Breakdown**: 전체 봇을 `AI / Search / SEO / Social / Other` 태그와 함께 Requests 내림차순으로.
- 봇 분류 기준은 `aeo_report_gen.py` 의 `CLASSIFY`(User-Agent 토큰 substring 매칭). 새 봇이 보이면 여기에 추가한다.

## 데이터 수집 순서 (Playwright MCP)
> Playwright 브라우저는 사용자의 일반 Chrome 과 **별개 세션**이라 로그인이 안 돼 있을 수 있다.

1. URL 을 만든다: `https://vercel.com/<팀>/<프로젝트>/observability/edge-requests?tab=botName&period=<기간>`.
2. `browser_navigate` 로 이동. **로그인 페이지(`/login`)로 리다이렉트되면**: 열린 브라우저 창에서 직접 로그인(Google/GitHub/이메일)하도록 사용자에게 요청하고, "됐어" 확인을 받은 뒤 URL 로 **재이동**한다. (로그인 방식/자격증명을 대신 입력하지 않는다.)
3. 환경이 Production 이 아니면 좌상단 환경 콤보박스에서 해당 환경을 고른다(기본 Production 은 그대로 둔다).
4. 표를 **한 페이지에 다 담기 위해** 페이지 크기를 50 으로 올린다. `browser_run_code_unsafe`:
   ```js
   async (page) => {
     for (const s of await page.$$('select')) {
       const txt = await s.evaluate(el => Array.from(el.options).map(o=>o.text).join(','));
       if (txt.includes('Show 50')) { await s.selectOption({ label: 'Show 50' }); return 'ok'; }
     }
     return 'no page-size select';
   }
   ```
   `browser_wait_for` 로 2초 대기(표 재렌더).
5. 표 데이터를 추출한다. `browser_evaluate`:
   ```js
   () => {
     const t = document.querySelector('table');
     const rows = Array.from(t.querySelectorAll('tbody tr')).map(tr => {
       const c = Array.from(tr.querySelectorAll('td')).map(x => x.innerText.trim());
       return { name: c[0], requests: c[1], cached: c[2] };
     }).filter(r => r.name);
     return rows;
   }
   ```
   그리고 `paragraph` 의 `"N of M"` 페이지네이션이 `1 of 1` 인지 확인한다. **2 이상이면 표가 덜 로드된 것** → 다시 대기 후 재추출(모든 봇을 빠짐없이 담아야 한다).
6. 전체 Edge Requests 총계를 추출한다. `browser_evaluate`:
   ```js
   () => {
     for (const c of document.querySelectorAll('.material-small')) {
       if (c.innerText.includes('Edge Requests')) {
         const lines = c.innerText.split('\n').map(s=>s.trim()).filter(Boolean);
         const i = lines.findIndex(l => l === 'Edge Requests');
         if (i >= 0 && lines[i+1]) return lines[i+1];
       }
     }
     return null;
   }
   ```
7. 상단 차트(두 카드)를 캡처한다. `browser_run_code_unsafe`:
   ```js
   async (page) => {
     const ok = await page.evaluate(() => {
       const leaves = [...document.querySelectorAll('*')].filter(el => el.children.length === 0);
       const fire = leaves.find(el => el.textContent.trim() === 'Firewall Actions');
       const card = fire && fire.closest('.material-small');
       if (!card || !card.parentElement) return false;
       card.parentElement.setAttribute('data-aeo-charts', '1');
       return true;
     });
     if (ok) await page.locator('[data-aeo-charts="1"]').screenshot({ path: '.playwright-mcp/aeo_chart.png', scale: 'device', type: 'png' });
     return ok ? 'chart-ok' : 'no-chart';
   }
   ```
   저장 위치는 반드시 허용 루트(`~/.playwright-mcp/` 또는 `~/` 하위). `no-chart` 면 차트 없이 진행한다(리포트는 차트 카드를 자동 생략).
8. 기간 표시(날짜 범위, KST)는 상단 날짜 버튼 텍스트에서 읽어 `period_range` 로 쓴다(없으면 비워 둔다).

## 리포트 디자인 (고정 템플릿 + 생성기)
- 디자인은 **고정 템플릿**을 쓴다: `~/Desktop/ai_setting/template/aeo_report_template.html` (Re:B 브라운/크림 톤, 헤더+타일 4개+차트 카드+AI 벤더 표+전체 봇 표+푸터). `<style>` 은 절대 바꾸지 않는다.
- 채우기/분류/지표 계산은 생성기 스크립트가 한다: `~/Desktop/ai_setting/template/aeo_report_gen.py`.
- 템플릿·생성기가 없으면 실패를 알리고 임의로 대체 디자인을 만들지 않는다(먼저 파일 경로를 사용자에게 확인).

## 생성 순서 (PDF)
1. 수집한 데이터를 JSON 으로 쓴다(임시 경로, 예: 스크래치패드/`.aeo_data.json`):
   ```json
   {
     "scope": "rebstudios / reb-platform-frontend",
     "title": "Edge Requests — AEO Bot Metrics",
     "env": "Production",
     "period_label": "Last 30 days",
     "period_range": "2026-06-28 09:35 ~ 2026-07-28 09:35 (KST)",
     "total_edge": "146K",
     "source_url": "<수집에 쓴 URL>",
     "generated": "<YYYY-MM-DD HH:MM>",
     "bots": [ {"name": "gptbot", "requests": "1.6K", "cached": "38.7%"}, ... ]
   }
   ```
   `period_label` 은 기간 인자에 맞춰(`24h`→`Last 24 hours`, `7d`→`Last 7 days`, `30d`→`Last 30 days`, `90d`→`Last 90 days`).
2. 생성기를 돌려 HTML 을 만든다(차트 있으면 `--chart` 추가):
   ```
   python3 ~/Desktop/ai_setting/template/aeo_report_gen.py \
     --data <.aeo_data.json> \
     --template ~/Desktop/ai_setting/template/aeo_report_template.html \
     --out <출력 pdf 폴더>/.aeo_report.html \
     --chart ~/.playwright-mcp/aeo_chart.png
   ```
   출력의 `[aeo] WARNING: ... unfilled` 이 뜨면 토큰이 남은 것 → 원인 확인 후 재실행(그대로 PDF 로 넘기지 않는다).
3. 출력 경로를 정한다. 인자에 경로가 있으면 그것(디렉토리면 그 안에 기본 파일명), 없으면 `~/Desktop/AEO_<프로젝트>_<기간>_<YYYY-MM-DD>.pdf`. 상위 폴더 없으면 `mkdir -p`.
4. HTML → PDF 변환. 사용 가능한 첫 방법:
   - **(A) Chromium 계열 headless (1순위).** 존재하는 첫 바이너리로:
     ```
     후보:
       "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
       "/Applications/Chromium.app/Contents/MacOS/Chromium"
       "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
       "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
       ~/Library/Caches/ms-playwright/chromium-*/chrome-mac/Chromium.app/Contents/MacOS/Chromium
     실행:
       "<바이너리>" --headless=new --disable-gpu --no-pdf-header-footer \
         --print-to-pdf="<출력.pdf>" "file://<HTML 절대경로>"
     ```
     (`--no-pdf-header-footer` 안 먹는 구버전이면 빼고 재시도.)
   - **(B) Playwright MCP (2순위).** A 가 전부 없으면 `browser_navigate` 로 `file://<HTML>` 열고 `browser_run_code_unsafe` 로 `await page.pdf({ path: "<출력.pdf>", format: "A4", printBackground: true })`.
   - **(C) 폴백.** 둘 다 실패하면 PDF 못 만들었음을 알리고 생성한 **HTML 경로**를 안내한다. 임의로 성공 보고하지 않는다.
5. 검증 후에만 완료 보고: 파일 존재 + `file <출력.pdf>` 가 `PDF document` + 페이지 수(`mdls -name kMDItemNumberOfPages` 또는 `file`)를 확인한다. 확인되면 임시 `.aeo_report.html`/`.aeo_data.json`/`aeo_chart.png` 는 정리한다(문제 시 남겨서 디버깅).
6. 사용자에게 저장된 **PDF 절대경로**와 핵심 지표 요약(Total Edge / AI Crawler 합계 / AI Share / Top AI / 벤더 상위 3)을 알린다. `open "<출력.pdf>"` 는 사용자가 원할 때만.

## 주의사항
- **Vercel 대시보드는 읽기 전용.** 설정/필터를 영구 변경하지 않는다(페이지 크기·환경 선택은 세션 내 임시 조작).
- **로그인은 사용자가 직접.** 자격증명을 대신 입력하지 않고, 로그인 창에서 사용자가 로그인하도록 안내한다.
- **모든 봇을 담는다.** 페이지네이션이 `1 of 1` 이 될 때까지(=Show 50) 확인. 상위 10개만 담고 "완료"라 하지 않는다.
- **근사치임을 명시.** Requests 는 Vercel 표기(반올림)라 합계는 근사치. 봇 분류는 UA 토큰 휴리스틱(googleother 등 경계 사례 존재) — 리포트 푸터에 이미 명시됨.
- **검증 없이 완료 보고 금지.** PDF 존재·타입 확인 전에는 "생성 완료"라 하지 않는다. 폴백(C)로 빠졌으면 그 사실과 HTML 경로를 알린다.
- **git 을 만지지 않는다.** 자동 commit/push 없음.

## 자주 쓰는 봇 (분류 참고)
- **AI(답변엔진)**: gptbot, oai-searchbot, chatgpt-user, gpt-actions(OpenAI) · claudebot, claude-user(Anthropic) · perplexitybot, perplexity-user(Perplexity) · google-read-aloud, google-extended, googleother(Google) · meta-externalagent(Meta AI) · applebot-extended(Apple) · amazonbot · bytespider · cohere-ai · ccbot 등.
- **Search**: googlebot, bingbot, naverbot(yeti), yandexbot, baiduspider, duckduckbot, applebot, petalbot 등.
- **SEO**: ahrefsbot, semrush, seranking, dataforseobot, mj12bot, dotbot 등.
- **Social**: facebookexternalhit, meta-externalads, twitterbot, linkedinbot, pinterest, slackbot, kakao 등.
- 매칭 안 되면 **Other**(예: vercel-favicon-bot, chrome-privacy-preserving-prefetch-proxy, adsnaver).
