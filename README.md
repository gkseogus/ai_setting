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
│   ├── frontend_conventions.md     # 프론트엔드 글로벌 컨벤션
│   └── pull_request_template.md    # PR 템플릿 원본
├── commands/                       # 커스텀 슬래시 커맨드 (에이전트 공통)
│   ├── commit.md                   # /commit 커맨드
│   ├── create_pr.md                # /create_pr 커맨드
│   └── frontend_convention.md      # /frontend_convention 커맨드
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
| 5 | `~/CLAUDE.md` 생성 (프론트엔드 컨벤션 참조) |
| 6 | `/frontend_convention` 슬래시 커맨드 등록 |
| 7 | OMC, Figma 플러그인 설치 |

## 에이전트별 세팅

| 에이전트 | 디렉토리 | 상태 |
|----------|----------|------|
| Claude Code | `claude/` | 설정 완료 |

## 커스텀 슬래시 커맨드

| 명령어 | 설명 |
|--------|------|
| `/commit` | 변경점 분석 후 `[타입] 한글 설명` 형식으로 커밋 (모노레포 자동 감지) |
| `/create_pr` | 커밋 분석 후 PR 템플릿 기반 GitHub PR 자동 생성 |
| `/frontend_convention` | 프론트엔드 컨벤션 기준으로 코드 검토 및 자동 수정 |
