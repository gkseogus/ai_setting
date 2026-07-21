RDS에 터널을 열어 로컬에서 접속할 수 있게 합니다. 베스천 SSH 터널(reb)과 SSM 포트포워딩(mealiq) 두 방식을 지원합니다.

## 사용법
`/ssh-rds-tunnel` 실행 후 접속할 RDS 정보를 입력하면 자동으로 터널링합니다.

## 인자
- 인자 없이 실행: 등록된 RDS 목록에서 선택
- 인자와 함께 실행: 해당 이름의 RDS에 바로 터널링 (예: `/ssh-rds-tunnel reb-platform-prod`)

## 등록된 RDS 목록

| 이름 | 방식 | RDS 호스트 | 게이트웨이 | SSH Key | 로컬 포트 |
|------|------|-----------|------------|---------|----------|
| reb-platform-prod | ssh | reb-platform-prod.cr8soguyakaq.ap-northeast-2.rds.amazonaws.com:5432 | Bastion 3.39.228.88 | ~/.key/reb.pem | 5432 |
| mealiq-prod | ssm | 동적 조회 (아래 참조) | App EC2 (tag:Name=mealiq-prod-app) | 불필요 | 15433 |

## 작업 순서
1. 인자가 있으면 해당 이름으로, 없으면 사용자에게 위 목록에서 선택하게 합니다.
2. 기존 터널이 열려있으면 알려줍니다 (`lsof -i :{local_port}` 확인).
3. 방식에 따라 터널을 백그라운드로 실행합니다 (아래 방식별 절차).
4. 터널이 열리면 접속 정보를 안내합니다:
   - 호스트: localhost
   - 포트: {local_port}
   - 데이터베이스/유저 정보는 Secrets Manager 또는 .env 참조

## 방식별 절차

### ssh (베스천 경유 — reb)
```bash
ssh -i {key} -N -L {local_port}:{rds_host}:{rds_port} {user}@{bastion_ip}
```
- SSH 유저 기본값: ec2-user

### ssm (App EC2 경유 — mealiq)
1. Session Manager Plugin 설치 확인: `session-manager-plugin --version` — 없으면 `brew install --cask session-manager-plugin` 안내.
2. 인스턴스 ID와 RDS 주소를 동적 조회합니다 (apply 전이면 리소스가 없다고 안내하고 중단):
   ```bash
   INSTANCE_ID=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=mealiq-prod-app" "Name=instance-state-name,Values=running" \
     --query "Reservations[0].Instances[0].InstanceId" --output text --region ap-northeast-2)
   RDS_ADDRESS=$(aws rds describe-db-instances --db-instance-identifier mealiq-prod \
     --query "DBInstances[0].Endpoint.Address" --output text --region ap-northeast-2)
   ```
3. SSM 포트포워딩 세션을 백그라운드로 시작합니다:
   ```bash
   aws ssm start-session \
     --target "$INSTANCE_ID" \
     --document-name AWS-StartPortForwardingSessionToRemoteHost \
     --parameters "{\"host\":[\"$RDS_ADDRESS\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"{local_port}\"]}" \
     --region ap-northeast-2
   ```
- mealiq 로컬 포트 15433 이유: reb 터널(5432)·로컬 dev postgres(5433)와 충돌 방지.
- 참고 runbook: mealiq_infra/docs/ssm-tunnel.md

## 새 RDS 등록
사용자가 "등록해줘"라고 하면 위 목록 테이블에 새 항목을 추가합니다. 방식(ssh/ssm)을 먼저 확인하고, 목록에 없는 정보는 순서대로 질문합니다:
- 방식 ssh: RDS 호스트/포트 · Bastion IP · SSH Key 경로(기본 ~/.key/reb.pem) · SSH 유저(기본 ec2-user) · 로컬 포트
- 방식 ssm: 인스턴스 조회 태그(또는 인스턴스 ID) · RDS 식별자(또는 호스트) · 로컬 포트

이 파일을 수정하면 /Users/hdh/Desktop/ai_setting/commands/ssh-rds-tunnel.md 에도 동일하게 반영합니다.
