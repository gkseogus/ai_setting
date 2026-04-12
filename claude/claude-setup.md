# Claude Code Setup Guide

새 디바이스에서 Claude Code 환경을 세팅하기 위한 가이드.

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

`~/.claude/settings.local.json` — 프로젝트별 허용 권한:

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
      "Bash(docker compose:*)",
      "Bash(python3:*)",
      "Bash(pip3 install:*)",
      "Bash(pip install:*)",
      "Bash(pip list:*)",
      "Bash(python -c \":*)",
      "Bash(python manage.py migrate)",
      "Bash(python manage.py runserver)",
      "Bash(npm install:*)",
      "Bash(npm run:*)",
      "Bash(npm -v)",
      "Bash(node:*)",
      "Bash(git config:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(gh api:*)",
      "Bash(gh auth:*)",
      "Bash(chmod:*)",
      "Bash(kill:*)",
      "Bash(xargs kill:*)",
      "Bash(ssh-keygen:*)",
      "Bash(docker volume:*)",
      "Bash(docker exec:*)",
      "Bash(brew services:*)",
      "Bash(claude mcp:*)",
      "Bash(redis-cli ping:*)",
      "Read(//usr/local/bin/**)",
      "Read(//opt/homebrew/bin/**)"
    ]
  }
}
```

## 5. HUD 설정

OMC 설치 후 자동 설정되지만, 수동 설정 시:

```bash
# HUD 디렉터리 생성
mkdir -p ~/.claude/hud

# HUD 설정
/oh-my-claudecode:hud setup
```

## 6. AWS CLI 설정 (Bedrock 사용 시)

```bash
aws configure
# AWS Access Key ID: [키 입력]
# AWS Secret Access Key: [시크릿 입력]
# Default region name: ap-northeast-2
# Default output format: json
```

## 7. OMC 스킬 목록

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

## 8. 프로젝트 커스텀 스킬

`.claude/skills/` 디렉토리에 수기로 등록한 프로젝트 전용 스킬. `user_invocable: true`로 설정하면 `/<skill-name>`으로 직접 호출 가능.

| 스킬 | 명령어 | 설명 |
|------|--------|------|
| create-pr | `/create-pr` | PR 템플릿 기준으로 커밋 분석 후 GitHub PR 자동 생성 |
| ssm-rds | `/ssm-rds` | AWS SSM 포트포워딩으로 RDS 로컬 접속 터널 시작 |
| omc-reference | (자동 로드) | OMC 에이전트 카탈로그, 도구, 팀 파이프라인, 커밋 프로토콜 참조 |

### create-pr

현재 브랜치의 커밋을 분석하고 `.github/pull_request_template.md` 형식에 맞춰 PR을 자동 생성한다.

```bash
/create-pr              # main 기준 PR 생성
/create-pr develop      # develop 기준 PR 생성
/create-pr --dry-run    # PR 본문 미리보기만
```

동작 흐름:
1. `git log main..HEAD`로 커밋 분석
2. 커밋 prefix(`[fix]`, `[feat]` 등)에서 변경 유형 자동 판별
3. PR 템플릿의 각 섹션(변경사항, 변경유형, 테스트, 참고사항) 자동 채움
4. `gh pr create`로 PR 생성

### ssm-rds

AWS SSM 포트포워딩을 통해 Bastion EC2 → RDS 터널을 시작하여 로컬에서 RDS에 접속한다.

```bash
/ssm-rds              # 포트포워딩 터널 시작 (127.0.0.1:15432)
/ssm-rds --password   # RDS 비밀번호도 함께 조회
/ssm-rds --kill       # 기존 SSM 세션 종료
```

동작 흐름:
1. AWS CLI, SSM Plugin 설치 여부 확인
2. 기존 15432 포트 리스닝 세션 확인
3. Bastion 인스턴스 ID 및 RDS 엔드포인트 자동 조회
4. SSM 포트포워딩 명령어 생성 및 실행 안내
5. 접속 정보 출력 (Host: `127.0.0.1`, Port: `15432`, DB: `mealiq`)

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

## 9. 세팅 순서 요약

```
1. npm install -g @anthropic-ai/claude-code
2. settings.json 복사
3. settings.local.json 복사
4. claude plugin install oh-my-claudecode --marketplace omc
5. claude plugin install figma --marketplace claude-plugins-official
6. /oh-my-claudecode:hud setup
7. aws configure (필요 시)
8. Claude Code 재시작
```

## 9. 프론트엔드 글로벌 컨벤션

별도 파일 참조: `frontend-conventions.md`
