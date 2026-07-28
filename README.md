# ai_setting

AI 코딩 에이전트별 환경 세팅 및 공유 설정을 관리하는 저장소.

## 빠른 설치

```bash
git clone https://github.com/<your-org>/ai_setting.git ~/ai_setting
cd ~/ai_setting
./setup.sh
```

새 디바이스에서 위 3줄만 실행하면 Claude Code 커스텀 세팅이 완료됩니다.

## 구조

```
ai_setting/
├── setup.sh                        # 원클릭 세팅 스크립트
├── template/                       # 템플릿 파일
│   ├── frontend_conventions.md     # 프론트엔드 글로벌 컨벤션 (14항목, 문서 업데이트·테스트 코드 포함)
│   ├── backend_conventions.md      # 백엔드 글로벌 컨벤션 (11항목, 상수 분리·문서 업데이트·테스트 코드 포함)
│   ├── error_handling.md           # 에러 처리 룰 (표면 vs 근본 판단, 5단계)
│   ├── pull_request_template.md    # PR 템플릿 원본
│   ├── weekly_report_template.html # /weekly_report PDF 고정 디자인 (Re:B 톤)
│   ├── aeo_report_template.html    # /aeo_report PDF 고정 디자인 (Re:B 톤)
│   └── aeo_report_gen.py           # /aeo_report 봇 분류·AEO 지표 계산·템플릿 채우기 생성기
├── commands/                       # 커스텀 슬래시 커맨드 (에이전트 공통)
│   ├── commit.md                   # /commit 커맨드
│   ├── create_pr.md                # /create_pr 커맨드
│   ├── frontend_convention.md      # /frontend_convention 커맨드
│   ├── backend_convention.md       # /backend_convention 커맨드
│   ├── ssh-rds-tunnel.md           # /ssh-rds-tunnel 커맨드 (SSH/SSM 터널)
│   ├── notion_diary.md             # /notion_diary 커맨드
│   ├── weekly_report.md            # /weekly_report 커맨드 (노션 일지 → 주간 보고서 PDF)
│   ├── jira_project.md             # /jira_project 커맨드
│   ├── root_cause.md               # /root_cause 커맨드 (에러 근본 원인 추적 + 검증)
│   └── aeo_report.md               # /aeo_report 커맨드 (Vercel Bot Name → AEO 지표 PDF)
├── claude/                         # Claude Code 세팅
│   ├── claude-setup.md             # 설치 및 설정 가이드 (상세)
│   └── settings.local.json         # 권한 설정 템플릿
└── README.md
```

## setup.sh가 하는 일

| 단계 | 내용 |
|------|------|
| 1 | Claude Code 설치 확인 (없으면 npm 설치) |
| 2 | `~/.claude/commands/`, `~/.claude/hud/` 디렉토리 생성 |
| 3 | `~/.claude/settings.json` 생성 (플러그인, HUD, 환경변수) |
| 4 | `~/.claude/settings.local.json` 복사 (권한 설정) |
| 5 | `~/CLAUDE.md` 생성 (프론트엔드/백엔드/에러 처리 룰 참조) |
| 6 | `/commit`, `/create_pr`, `/frontend_convention`, `/backend_convention`, `/ssh-rds-tunnel`, `/notion_diary`, `/weekly_report`, `/jira_project`, `/root_cause`, `/aeo_report` 슬래시 커맨드 등록 |
| 7 | OMC, Figma 플러그인 설치 |
| 8 | MCP 서버 등록 (Playwright, GitHub CLI, GWS CLI, Notion, Atlassian) + Skill Creator 플러그인 |

## MCP 서버

| MCP 서버 | 패키지/커맨드 | 용도 |
|-----------|---------------|------|
| Playwright | `npx @playwright/mcp@latest` | 브라우저 자동화, E2E 테스트 |
| GitHub CLI | `gh mcp` (via `shuymn/gh-mcp`) | GitHub 이슈/PR/리포 관리 |
| GWS CLI | `npx gws-mcp-server@latest` | Google Workspace (Drive, Sheets, Calendar, Gmail) |
| Notion | `https://mcp.notion.com/mcp` (HTTP, OAuth) | Notion 페이지/DB 조회 및 편집 |
| Atlassian | `https://mcp.atlassian.com/v1/mcp` (HTTP, OAuth) | Jira 이슈/프로젝트, Confluence 페이지 조회 및 생성 |
| Skill Creator | `claude plugin install skill-creator` | 커스텀 스킬 생성 (플러그인) |

## 에이전트별 세팅

| 에이전트 | 디렉토리 | 상태 |
|----------|----------|------|
| Claude Code | `claude/` | 설정 완료 |

## 커스텀 슬래시 커맨드

| 명령어 | 설명 |
|--------|------|
| `/commit` | 변경점 분석 후 `[타입] 한글 설명` 형식으로 **파일 단위 커밋** (파일마다 개별 커밋, 모노레포 자동 감지) |
| `/create_pr` | 커밋 분석 후 PR 템플릿 기반 GitHub PR 자동 생성 |
| `/frontend_convention` | 프론트엔드 컨벤션 기준으로 코드 검토 및 자동 수정 (상수/타입/훅/API 규칙 + 문서·테스트 동반 갱신 검사) |
| `/backend_convention` | 백엔드 컨벤션 기준으로 코드 검토 및 자동 수정 (레이어 분리, 상수 분리, 리턴 타입, 네이밍, 린트 + 문서·테스트 동반 갱신 검사) |
| `/ssh-rds-tunnel` | RDS 터널 연결 — 베스천 SSH(reb) 또는 SSM 포트포워딩(mealiq) 방식 자동 분기 (등록된 RDS 선택 또는 직접 입력) |
| `/notion_diary` | 현재 세션에서 한 작업을 노션 일지(`일지 > YYYY-MM > YYYY-MM-DD`)에 음슴체로 비개발자도 볼 수 있게 자동 정리 |
| `/weekly_report` | 이번 주(월~금) 노션 일지를 모아 대표 보고용 주간 업무 보고서(진행/완료·결론/지연·확인 필요/다음 주 예정/대표 결정 사항)를 평어·개조식으로 재구성해 PDF(기본 `~/Desktop`, 인자로 경로 지정)로 저장 |
| `/jira_project` | 새 기능/이니셔티브 단위로 Jira 에 Epic 1개 + 하위 Story/Task 트리를 한 번에 등록 (기본 프로젝트 `KAN`) |
| `/root_cause` | 에러/버그 발생 시 "뿌리 뽑기 vs 싹 자르기" Triage → 근본 원인 추적(5 Whys + 유사 패턴) → 수정 → 검증(증상 재현 불가/유사/회귀/테스트) → 5항목 보고 |
| `/aeo_report` | Vercel Observability Edge Requests(Bot Name) → AEO 지표 리포트 PDF. AI 답변엔진(OpenAI/Anthropic/Google/Perplexity 등) 크롤러 유입·점유율·캐시율을 벤더별 집계 + 전체 봇 분류(AI/Search/SEO/Social/Other). 기본 `~/Desktop`, 인자로 프로젝트/기간/경로 지정 |
