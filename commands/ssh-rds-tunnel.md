RDS에 SSH 터널을 열어 로컬에서 접속할 수 있게 합니다.

## 사용법
`/ssh-rds-tunnel` 실행 후 접속할 RDS 정보를 입력하면 자동으로 터널링합니다.

## 인자
- 인자 없이 실행: 등록된 RDS 목록에서 선택
- 인자와 함께 실행: 해당 이름의 RDS에 바로 터널링 (예: `/ssh-rds-tunnel reb-platform-prod`)

## 등록된 RDS 목록

| 이름 | RDS 호스트 | Bastion IP | SSH Key | 로컬 포트 |
|------|-----------|------------|---------|----------|
| reb-platform-prod | reb-platform-prod.cr8soguyakaq.ap-northeast-2.rds.amazonaws.com:5432 | 3.39.228.88 | ~/.key/reb.pem | 5432 |

## 작업 순서
1. 인자가 있으면 해당 이름으로, 없으면 사용자에게 위 목록에서 선택하게 합니다.
2. 목록에 없는 경우 사용자에게 순서대로 질문합니다:
   - RDS 호스트 주소 (예: xxx.rds.amazonaws.com)
   - RDS 포트 (기본: 5432)
   - Bastion IP 주소
   - SSH Key 경로 (기본: ~/.key/reb.pem)
   - SSH 유저 (기본: ec2-user)
   - 로컬 포트 (기본: RDS 포트와 동일)
3. 기존 터널이 열려있으면 알려줍니다.
4. SSH 터널을 백그라운드로 실행합니다:
   `ssh -i {key} -N -L {local_port}:{rds_host}:{rds_port} {user}@{bastion_ip}`
5. 터널이 열리면 접속 정보를 안내합니다:
   - 호스트: localhost
   - 포트: {local_port}
   - 데이터베이스/유저 정보는 Secrets Manager 또는 .env 참조

## 새 RDS 등록
사용자가 "등록해줘"라고 하면 위 목록 테이블에 새 항목을 추가합니다.
