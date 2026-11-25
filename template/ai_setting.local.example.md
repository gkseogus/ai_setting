# ai_setting 개인 설정

저장소 밖(`~/.claude/ai_setting.local.md`)에 두는 개인·회사 전용 값이다. 저장소에 커밋하지 않는다.
`setup.sh` 가 이 파일이 없을 때만 이 예시를 복사한다. 쓰는 커맨드의 절만 채우면 된다.
커맨드는 자기 이름의 `## <커맨드>` 절을 읽는다 (`## brand` 는 `/weekly_report` 가 읽는다). 값이 비어 있으면 커맨드가 묻거나 기본 동작으로 처리한다.

## brand
- 이름: (예: Acme Inc. — 비우면 보고서에 회사명을 넣지 않음)
- 보고서 라벨: (예: A C M E &nbsp; I N C. — 주간 보고서 상단 자간 라벨)

## weekly_report
- 작성자: (예: 홍길동)

## aeo_report
- 기본 프로젝트: (Vercel `팀/프로젝트`, 예: my-team/my-site)

## jira_project
- 사이트: (예: https://my-company.atlassian.net)
- 기본 프로젝트 키: (예: PROJ — 아래 우선순위·필수 필드·transition 값은 이 프로젝트에만 쓴다)
- 기본 담당자: (이름, 알면 accountId 도 함께)
- 이슈 타입 이름: (예: `Epic` / `Story` / `Task` — 한글 사이트면 `에픽` / `스토리` / `작업`)
- 필수 필드: (생성 시 꼭 넣어야 하는 필드, 예: 시작 날짜 `customfield_10015`, 기한 `duedate`)
- 우선순위 id: (예: `Highest` 1 / `High` 2 / `Medium` 3 / `Low` 4 / `Lowest` 5)
- transition id: (예: 할 일 `11` / 진행 중 `21` / 완료 `31`)

## ssh-rds-tunnel
- AWS 리전: (예: ap-northeast-2)

| 이름 | 방식 | RDS | 게이트웨이 | SSH Key | 로컬 포트 |
|------|------|-----|------------|---------|----------|

행 예시 (위 표에 이 형식으로 추가):
- `` | my-app-prod | ssm | RDS 식별자 `my-app-prod` (주소 동적 조회) | App EC2 `tag:Name=my-app-prod-app` | 불필요 | 15432 | ``
- `` | my-legacy-prod | ssh | `my-legacy.xxxx.rds.amazonaws.com:5432` | Bastion `<배스천 IP>` | `~/.ssh/my-key.pem` | 15433 | ``

메모
- (계정 구분, runbook 경로 등 터널을 열 때 알려 줄 내용)
