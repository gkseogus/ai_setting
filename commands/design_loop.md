Figma 디자인(또는 텍스트 설명)을 **taste-skill 규칙으로 구현 → Playwright 로 캡처 → Impeccable 로 검수 → 원본과 비교**하는 디자인 루프.

인자: `$ARGUMENTS` = `<figma-url | 화면 설명> [로컬 URL, 기본 http://localhost:3000]`

## 글로벌 룰 (반드시 먼저 읽기)
@/Users/hdh/Desktop/ai_setting/template/frontend_conventions.md

**규칙 우선순위**: 프로젝트 컨벤션(위 파일) > `design-taste-frontend` 스킬 > Impeccable 지적 사항.
충돌하면(Tailwind 클래스 순서, `cn()`, 1파일 1컴포넌트, `contents/` 상수 분리 등) 항상 컨벤션을 따른다.

---

## 실행 순서

### 0. 사전 확인
- 프로젝트에 Impeccable 컨텍스트가 없으면 `/impeccable init` 을 먼저 1회 실행하라고 안내한다.
- dev 서버가 꺼져 있으면 `run_in_background` 로 실행한다 (`npm run dev` 등 프로젝트 스크립트).

### 1. 디자인 읽기 — **Framelink 전용**
- Figma URL 이면 `mcp__framelink__get_figma_data` 로 노드 데이터를 받고, 필요한 에셋은 `mcp__framelink__download_figma_images` 로 `public/` 아래에 저장한다.
- 원본 비교용 프레임 이미지도 같은 도구로 1장 받는다.
- **공식 Figma MCP(`mcp__plugin_figma_figma__*`) 로 읽지 않는다.** 무료 플랜은 월 6회 한도라 읽기에 쓰면 금방 소진된다.
- 텍스트 설명이면 이 단계를 건너뛴다.

### 2. 구현
- `design-taste-frontend` 스킬을 로드해 레이아웃·타이포·모션·간격을 적용한다.
- 모바일 퍼스트, 컨벤션의 폴더 구조·네이밍·타입 규칙을 지킨다.

### 3. 캡처 — Playwright MCP
- 대상 URL 로 이동한 뒤 `browser_resize` 로 **375px, 1440px** 두 뷰포트에서 `browser_take_screenshot` 을 찍는다.
- `browser_console_messages` 로 콘솔 에러를 수집한다. 에러가 있으면 먼저 고친다.

### 4. 검수 — Impeccable
- `/impeccable audit` → 지적 사항 수정 → `/impeccable polish`.
- 지적이 컨벤션과 충돌하면 수정하지 않고 보고에 "컨벤션 우선으로 무시함" 이라고 남긴다.

### 5. 원본 비교
- Figma 원본이 있으면 `oh-my-claudecode:visual-verdict` 로 1단계 원본 이미지와 3단계 스크린샷을 비교한다.
- 불일치가 있으면 2단계로 돌아간다. **최대 3회** 반복한 뒤에도 남은 차이는 보고에 적는다.

### 6. Figma 에 반영 (선택)
- 사용자가 **명시적으로 요청했을 때만** 공식 Figma MCP 를 쓴다.
- 호출 전에 "공식 Figma MCP 는 무료 플랜에서 월 6회 한도를 소모합니다. 진행할까요?" 라고 묻고 동의를 받는다.

### 7. 보고
- **구현 파일**: `파일:라인` 목록
- **스크린샷**: 375 / 1440 경로
- **Impeccable**: audit 에서 지적된 항목과 처리 결과 (수정 / 컨벤션 우선으로 무시)
- **원본 비교**: 반복 횟수와 남은 차이
- **Figma MCP 사용량**: Framelink 호출 수, 공식 MCP 호출 수 (기본 0)
