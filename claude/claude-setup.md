# Claude Code Setup Guide

새 디바이스에서 Claude Code 환경을 세팅하기 위한 가이드.

---

## 빠른 설치 (원클릭)

```bash
git clone https://github.com/<your-org>/ai_setting.git ~/ai_setting
cd ~/ai_setting
chmod +x setup.sh
./setup.sh
```

이 스크립트가 아래 1~10 단계를 자동으로 수행합니다.

---

## 1. Claude Code 설치

```bash
npm install -g @anthropic-ai/claude-code
```

## 2. 플러그인 설치

### oh-my-claudecode (OMC)

```bash
claude plugin install oh-my-claudecode --marketplace omc
```

### Figma Plugin

```bash
claude plugin install figma --marketplace claude-plugins-official
```

## 3. settings.json

`~/.claude/settings.json` 에 아래 내용 저장:

```json
{
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
  },
  "statusLine": {
    "type": "command",
    "command": "node $HOME/.claude/hud/omc-hud.mjs"
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 4. settings.local.json (권한 설정)

`~/.claude/settings.local.json` — 공통 허용 권한:

```json
{
  "permissions": {
    "allow": [
      "Bash(brew --version)",
      "Bash(git clone:*)",
      "Bash(docker --version)",
      "Bash(brew list:*)",
      "Bash(brew install:*)",
      "Bash(aws ec2:*)",
      "Bash(aws configure:*)",
      "Bash(aws ssm:*)",
      "Bash(aws s3:*)",
      "Bash(aws sts:*)",
      "Bash(aws bedrock:*)",
      "Bash(docker compose:*)",
      "Bash(docker volume:*)",
      "Bash(docker exec:*)",
      "Bash(python3:*)",
      "Bash(python:*)",
      "Bash(pip3 install:*)",
      "Bash(pip install:*)",
      "Bash(pip list:*)",
      "Bash(python -c \":*)",
      "Bash(python manage.py migrate)",
      "Bash(python manage.py runserver)",
      "Bash(npm install:*)",
      "Bash(npm run:*)",
      "Bash(npm -v)",
      "Bash(npm --version)",
      "Bash(npm init:*)",
      "Bash(npm create:*)",
      "Bash(npx tsc:*)",
      "Bash(npx next:*)",
      "Bash(npx prettier:*)",
      "Bash(npx vercel:*)",
      "Bash(node:*)",
      "Bash(git config:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git rm:*)",
      "Bash(git remote:*)",
      "Bash(git stash:*)",
      "Bash(git checkout:*)",
      "Bash(git rebase:*)",
      "Bash(gh api:*)",
      "Bash(gh auth:*)",
      "Bash(gh repo:*)",
      "Bash(chmod:*)",
      "Bash(kill:*)",
      "Bash(xargs kill:*)",
      "Bash(ssh-keygen:*)",
      "Bash(ssh:*)",
      "Bash(scp:*)",
      "Bash(brew services:*)",
      "Bash(claude mcp:*)",
      "Bash(claude --version)",
      "Bash(redis-cli ping:*)",
      "Bash(ls:*)",
      "Bash(curl:*)",
      "Bash(dig:*)",
      "Bash(omc:*)",
      "Bash(tmux list-sessions:*)",
      "Bash(tmux kill-session:*)",
      "Bash(tmux kill-server:*)",
      "Bash(tmux list-panes:*)",
      "Bash(tmux capture-pane:*)",
      "Bash(terraform output:*)",
      "mcp__plugin_oh-my-claudecode_t__python_repl",
      "mcp__plugin_oh-my-claudecode_t__state_write",
      "mcp__plugin_oh-my-claudecode_t__state_clear",
      "mcp__plugin_oh-my-claudecode_t__state_list_active",
      "mcp__plugin_oh-my-claudecode_t__lsp_document_symbols",
      "Read(//usr/local/bin/**)",
      "Read(//opt/homebrew/bin/**)"
    ]
  }
}
```

## 5. 글로벌 CLAUDE.md

`~/CLAUDE.md` — 모든 프로젝트에 적용되는 글로벌 규칙:

```markdown
# Global Claude Code Rules

## Frontend Conventions
프론트엔드(React/Next.js) 프로젝트 작업 시 아래 컨벤션을 반드시 따른다.
@~/ai_setting/template/frontend_conventions.md
```

## 6. 커스텀 슬래시 커맨드

`~/.claude/commands/` 디렉토리에 `.md` 파일을 넣으면 `/<파일명>`으로 호출 가능.

### /commit — 변경점 분석 후 커밋

`~/.claude/commands/commit.md`:

변경된 파일을 분석하고 `[타입] 한글 설명` 형식으로 커밋합니다.
모노레포일 경우 `[타입](스코프) 한글 설명` 형식으로 자동 전환됩니다.

```bash
/commit                    # 전체 변경점 자동 분석 후 커밋
/commit 검색 기능 추가       # 설명 지정
```

### /frontend_convention — 프론트엔드 컨벤션 검토

`~/.claude/commands/frontend_convention.md`:

```markdown
프론트엔드 컨벤션을 적용하여 현재 프로젝트의 코드를 검토하고 위반 사항을 수정합니다.

## 컨벤션 파일
@~/ai_setting/template/frontend_conventions.md

## 작업 순서
1. 위 컨벤션 파일을 읽고 내용을 숙지합니다.
2. 현재 프로젝트의 src/ 디렉토리를 탐색합니다.
3. 컨벤션 위반 사항을 찾아 리스트업합니다.
4. 사용자에게 위반 사항을 보여주고 수정 여부를 확인합니다.
5. 승인된 항목에 대해 수정을 진행합니다.
```

## 7. HUD 설정

OMC 설치 후 자동 설정되지만, 수동 설정 시:

```bash
# HUD 디렉터리 생성
mkdir -p ~/.claude/hud

# HUD 설정
/oh-my-claudecode:hud setup
```

## 8. AWS CLI 설정 (Bedrock 사용 시)

```bash
aws configure
# AWS Access Key ID: [키 입력]
# AWS Secret Access Key: [시크릿 입력]
# Default region name: ap-northeast-2
# Default output format: json
```

## 9. OMC 스킬 목록

설치 시 포함되는 주요 스킬:

| 스킬 | 용도 | 사용법 |
|------|------|--------|
| autopilot | 자율 실행 | `/oh-my-claudecode:autopilot` |
| ralph | 반복 루프 실행 | `/oh-my-claudecode:ralph` |
| ultrawork | 병렬 실행 | `/oh-my-claudecode:ultrawork` |
| team | 팀 에이전트 | `/oh-my-claudecode:team` |
| plan | 전략 플래닝 | `/oh-my-claudecode:plan` |
| omc-teams | tmux CLI 워커 | `/oh-my-claudecode:omc-teams N:claude "task"` |
| cancel | 모드 취소 | `/oh-my-claudecode:cancel` |
| hud | HUD 설정 | `/oh-my-claudecode:hud` |
| trace | 원인 추적 | `/oh-my-claudecode:trace` |
| deep-interview | 심층 인터뷰 | `/oh-my-claudecode:deep-interview` |
| ccg | Claude-Codex-Gemini | `/oh-my-claudecode:ccg` |
| ai-slop-cleaner | AI 슬롭 제거 | `/oh-my-claudecode:ai-slop-cleaner` |
| deepinit | 코드베이스 초기화 | `/oh-my-claudecode:deepinit` |
| external-context | 외부 문서 검색 | `/oh-my-claudecode:external-context` |

## 10. 프로젝트 커스텀 스킬

`.claude/skills/` 디렉토리에 수기로 등록한 프로젝트 전용 스킬. `user_invocable: true`로 설정하면 `/<skill-name>`으로 직접 호출 가능.

| 스킬 | 명령어 | 설명 |
|------|--------|------|
| create-pr | `/create-pr` | PR 템플릿 기준으로 커밋 분석 후 GitHub PR 자동 생성 |
| ssm-rds | `/ssm-rds` | AWS SSM 포트포워딩으로 RDS 로컬 접속 터널 시작 |

### 커스텀 스킬 추가 방법

```bash
mkdir -p .claude/skills/<skill-name>
```

`.claude/skills/<skill-name>/SKILL.md` 작성:

```markdown
---
name: <skill-name>
description: 스킬 설명
user_invocable: true
---

# 스킬 내용
```

## 세팅 순서 요약

```
1. git clone https://github.com/<your-org>/ai_setting.git ~/ai_setting
2. cd ~/ai_setting && ./setup.sh
3. Claude Code 재시작
4. aws configure (필요 시)
```
