RDS에 터널을 열어 로컬에서 접속할 수 있게 합니다. SSM 포트포워딩(App EC2 경유)과 베스천 SSH 터널 두 방식을 지원합니다.

## 사용법
`/ssh-rds-tunnel` 실행 후 접속할 RDS 정보를 입력하면 자동으로 터널링합니다.

## 인자
- 인자 없이 실행: 등록된 RDS 목록에서 선택
- 인자와 함께 실행: 해당 이름의 RDS에 바로 터널링 (예: `/ssh-rds-tunnel my-app-prod`)

## 등록된 RDS 목록
개인 기본값은 `~/.claude/ai_setting.local.md` 의 `## ssh-rds-tunnel` 절에서 읽습니다. 파일이나 값이 없으면 사용자에게 묻습니다.
- 목록: 절 안의 표(이름 · 방식 · RDS · 게이트웨이 · SSH Key · 로컬 포트). 파일이나 표가 없거나 표에 행이 없으면 방식(ssh/ssm)과 접속 정보를 직접 입력받습니다 (항목은 아래 "새 RDS 등록" 참조).
- 리전(`{region}`): 절의 `AWS 리전` 값. 없으면 `aws configure get region` 결과를 씁니다.
- 메모: 절의 `메모` 에 고른 항목 관련 내용(계정 구분, runbook 경로 등)이 있으면 터널을 열 때 함께 안내합니다.

## 작업 순서
1. 인자가 있으면 해당 이름으로, 없으면 사용자에게 위 목록에서 선택하게 합니다.
2. 기존 터널이 열려있으면 알려줍니다 (`lsof -i :{local_port}` 확인).
3. 방식에 따라 터널을 백그라운드로 실행합니다 (아래 방식별 절차).
4. 터널이 열리면 접속 정보를 안내합니다:
   - 호스트: localhost
   - 포트: {local_port}
   - 데이터베이스/유저 정보는 Secrets Manager 또는 .env 참조
   - 해당 항목 관련 `메모` 가 있으면 함께 안내

## 방식별 절차

### ssh (베스천 경유)
```bash
ssh -i {key} -N -L {local_port}:{rds_host}:{rds_port} {user}@{bastion_ip}
```
- SSH 유저 기본값: ec2-user
- SSH Key 경로는 기본값이 없습니다. 목록에 없으면 사용자에게 묻습니다.

### ssm (App EC2 경유)
1. Session Manager Plugin 설치 확인: `session-manager-plugin --version` — 없으면 `brew install --cask session-manager-plugin` 안내.
2. 인스턴스 ID와 RDS 주소를 동적 조회합니다 (apply 전이면 리소스가 없다고 안내하고 중단). `{tag}` 는 게이트웨이 EC2 의 Name 태그, `{rds_identifier}` 는 RDS 식별자입니다:
   ```bash
   INSTANCE_ID=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values={tag}" "Name=instance-state-name,Values=running" \
     --query "Reservations[0].Instances[0].InstanceId" --output text --region {region})
   RDS_ADDRESS=$(aws rds describe-db-instances --db-instance-identifier {rds_identifier} \
     --query "DBInstances[0].Endpoint.Address" --output text --region {region})
   ```
3. SSM 포트포워딩 세션을 백그라운드로 시작합니다 (RDS 포트가 5432 가 아니면 `portNumber` 를 바꿉니다):
   ```bash
   aws ssm start-session \
     --target "$INSTANCE_ID" \
     --document-name AWS-StartPortForwardingSessionToRemoteHost \
     --parameters "{\"host\":[\"$RDS_ADDRESS\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"{local_port}\"]}" \
     --region {region}
   ```
- 로컬 포트는 로컬 dev postgres(5432 등)와 겹치지 않는 번호를 씁니다 (예: 15432).

## 새 RDS 등록
사용자가 "등록해줘"라고 하면 `~/.claude/ai_setting.local.md` 의 `## ssh-rds-tunnel` 표에 새 행을 추가합니다. 파일이 없으면 `{{AI_SETTING_DIR}}/template/ai_setting.local.example.md` 를 복사해 만든 뒤 추가합니다. 방식(ssh/ssm)을 먼저 확인하고, 목록에 없는 정보는 순서대로 질문합니다:
- 방식 ssh: RDS 호스트/포트 · Bastion IP · SSH Key 경로 · SSH 유저(기본 ec2-user) · 로컬 포트
- 방식 ssm: 인스턴스 조회 태그(또는 인스턴스 ID) · RDS 식별자(또는 호스트) · 로컬 포트
