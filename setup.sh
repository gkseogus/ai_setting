#!/bin/bash
set -e

echo "=== Claude Code 환경 세팅 시작 ==="

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[$1/$TOTAL] $2${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

TOTAL=9
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Claude Code 설치 확인
step 1 "Claude Code 설치 확인"
if command -v claude &>/dev/null; then
  echo "  Claude Code 이미 설치됨: $(claude --version 2>/dev/null || echo 'installed')"
else
  echo "  Claude Code 설치 중..."
  npm install -g @anthropic-ai/claude-code
fi

# 2. ~/.claude 디렉토리 구조 생성
step 2 "디렉토리 구조 생성"
mkdir -p ~/.claude/commands ~/.claude/hud

# 3. settings.json 복사
step 3 "settings.json 설정"
if [ -f ~/.claude/settings.json ]; then
  warn "settings.json 이미 존재 — 기존 파일 백업 후 덮어쓰기"
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
fi
cat > ~/.claude/settings.json << 'JSON'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "statusLine": {
    "type": "command",
    "command": "node $HOME/.claude/hud/omc-hud.mjs"
  },
  "enabledPlugins": {
    "figma@claude-plugins-official": true,
    "oh-my-claudecode@omc": true
  },
  "extraKnownMarketplaces": {
    "omc": {
      "source": {
        "source": "git",
        "url": "https://github.com/Yeachan-Heo/oh-my-claudecode.git"
      }
    }
  }
}
JSON
echo "  settings.json 적용 완료"

# 4. settings.local.json 복사
step 4 "settings.local.json 설정 (권한)"
if [ -f ~/.claude/settings.local.json ]; then
  warn "settings.local.json 이미 존재 — 기존 파일 백업 후 덮어쓰기"
  cp ~/.claude/settings.local.json ~/.claude/settings.local.json.bak
fi
cp "$SCRIPT_DIR/claude/settings.local.json" ~/.claude/settings.local.json
echo "  settings.local.json 적용 완료"

# 5. 글로벌 CLAUDE.md 생성
step 5 "글로벌 CLAUDE.md 생성"
cat > ~/CLAUDE.md << CLAUDEMD
# Global Claude Code Rules

## Language
사용자에게 보고·답변할 때만 한국어로 한다. 코드·주석·커밋 메시지·문서 등 산출물의 언어는 기존 프로젝트 관례를 따른다.

## Frontend Conventions
프론트엔드(React/Next.js) 프로젝트 작업 시 아래 컨벤션을 반드시 따른다.
@$SCRIPT_DIR/template/frontend_conventions.md

## Backend Conventions
백엔드(FastAPI/Python) 프로젝트 작업 시 아래 컨벤션을 반드시 따른다.
@$SCRIPT_DIR/template/backend_conventions.md

## Error Handling — 표면 vs 근본 판단
모든 에러 / 버그 / 예외를 다룰 때 반드시 아래 룰(Triage → Root Cause → Fix → Verification → Report)을 따른다.
정밀 검증이 필요한 상황에서는 \`/root_cause\` 슬래시 커맨드를 호출한다.
@$SCRIPT_DIR/template/error_handling.md
CLAUDEMD
echo "  ~/CLAUDE.md 생성 완료"

# 6. 커스텀 슬래시 커맨드 복사
step 6 "커스텀 슬래시 커맨드 등록"
cp "$SCRIPT_DIR/commands/commit.md" ~/.claude/commands/commit.md
echo "  /commit 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/create_pr.md" ~/.claude/commands/create_pr.md
echo "  /create_pr 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/frontend_convention.md" ~/.claude/commands/frontend_convention.md
echo "  /frontend_convention 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/backend_convention.md" ~/.claude/commands/backend_convention.md
echo "  /backend_convention 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/ssh-rds-tunnel.md" ~/.claude/commands/ssh-rds-tunnel.md
echo "  /ssh-rds-tunnel 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/notion_diary.md" ~/.claude/commands/notion_diary.md
echo "  /notion_diary 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/weekly_report.md" ~/.claude/commands/weekly_report.md
echo "  /weekly_report 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/jira_project.md" ~/.claude/commands/jira_project.md
echo "  /jira_project 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/root_cause.md" ~/.claude/commands/root_cause.md
echo "  /root_cause 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/aeo_report.md" ~/.claude/commands/aeo_report.md
echo "  /aeo_report 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/type_error_fix.md" ~/.claude/commands/type_error_fix.md
echo "  /type_error_fix 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/design_loop.md" ~/.claude/commands/design_loop.md
echo "  /design_loop 커맨드 등록 완료"

cp "$SCRIPT_DIR/commands/final_test.md" ~/.claude/commands/final_test.md
echo "  /final_test 커맨드 등록 완료"

# 7. 플러그인 설치
step 7 "플러그인 설치"
echo "  OMC 플러그인 설치..."
claude plugin install oh-my-claudecode --marketplace omc 2>/dev/null || warn "OMC 플러그인 설치 실패 (수동 설치 필요)"
echo "  Figma 플러그인 설치..."
claude plugin install figma --marketplace claude-plugins-official 2>/dev/null || warn "Figma 플러그인 설치 실패 (수동 설치 필요)"

# 8. MCP 서버 등록
step 8 "MCP 서버 등록"

echo "  Playwright MCP 등록..."
claude mcp add playwright -s user -- npx @playwright/mcp@latest 2>/dev/null || warn "Playwright MCP 등록 실패"

echo "  GitHub CLI MCP 등록..."
if ! gh extension list 2>/dev/null | grep -q "gh-mcp"; then
  echo "  gh-mcp 확장 설치 중..."
  gh extension install shuymn/gh-mcp 2>/dev/null || warn "gh-mcp 확장 설치 실패"
fi
claude mcp add github-cli -s user -- gh mcp 2>/dev/null || warn "GitHub CLI MCP 등록 실패"

echo "  GWS CLI MCP 등록..."
claude mcp add gws-cli -s user -- npx gws-mcp-server@latest 2>/dev/null || warn "GWS CLI MCP 등록 실패"

echo "  Notion MCP 등록..."
claude mcp add --transport http notion -s user https://mcp.notion.com/mcp 2>/dev/null || warn "Notion MCP 등록 실패"

echo "  Atlassian MCP 등록..."
# SSE 엔드포인트(v1/sse)는 2026-06-30 이후 지원 종료 — Streamable HTTP(v1/mcp) 사용
claude mcp add --transport http atlassian -s user https://mcp.atlassian.com/v1/mcp 2>/dev/null || warn "Atlassian MCP 등록 실패"

echo "  Skill Creator 플러그인 설치..."
claude plugin install skill-creator 2>/dev/null || warn "Skill Creator 플러그인 설치 실패"

# 9. 디자인 스택
step 9 "디자인 스택 (taste-skill, Impeccable, Framelink)"

echo "  taste-skill 설치..."
npx -y skills add leonxlnx/taste-skill --skill design-taste-frontend --agent claude-code -g -y 2>/dev/null || warn "taste-skill 설치 실패"

echo "  Impeccable 플러그인 설치..."
claude plugin marketplace add pbakaus/impeccable 2>/dev/null || true
claude plugin install impeccable@impeccable 2>/dev/null || warn "Impeccable 설치 실패 (/plugin 에서 수동 설치)"

echo "  Framelink(Figma) MCP 등록..."
# 공식 Figma MCP 는 무료(Starter) 플랜에서 월 6회 한도 → 읽기는 Framelink(PAT, REST API)로 처리
if [ -n "$FIGMA_API_KEY" ]; then
  claude mcp add framelink -s user -e FIGMA_API_KEY="$FIGMA_API_KEY" -- npx -y figma-developer-mcp --stdio --no-telemetry 2>/dev/null || warn "Framelink MCP 등록 실패"
else
  warn "FIGMA_API_KEY 미설정 — Framelink 등록 건너뜀 (export FIGMA_API_KEY=... 후 재실행)"
fi

echo ""
echo -e "${GREEN}=== 세팅 완료! ===${NC}"
echo ""
echo "다음 단계:"
echo "  1. Claude Code 재시작"
echo "  2. aws configure (AWS 사용 시)"
echo "  3. /oh-my-claudecode:hud setup (HUD 수동 설정 시)"
echo "  4. GWS CLI 인증: npx gws auth login (Google Workspace 사용 시)"
echo "  5. Notion MCP 인증: Claude Code에서 /mcp 실행 후 notion 항목 OAuth 인증"
echo "  6. Atlassian MCP 인증: Claude Code에서 /mcp 실행 후 atlassian 항목 OAuth 인증"
echo "  7. Figma: PAT 발급(Settings > Security > Personal access tokens) → export FIGMA_API_KEY=... → ./setup.sh 재실행"
echo "  8. Figma 공식 MCP 인증: /mcp 실행 후 plugin:figma 항목 OAuth 인증 (쓰기 전용, 무료 월 6회)"
echo "  9. 프론트 프로젝트 루트에서 /impeccable init 1회 실행"
