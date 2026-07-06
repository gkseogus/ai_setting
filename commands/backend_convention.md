백엔드 컨벤션을 적용하여 현재 프로젝트의 코드를 검토하고 위반 사항을 수정합니다.

## 컨벤션 파일
@/Users/hdh/Desktop/ai_setting/template/backend_conventions.md

## 작업 순서
1. 위 컨벤션 파일을 읽고 내용을 숙지합니다.
2. 현재 프로젝트의 app/ 디렉토리를 탐색합니다.
3. 컨벤션 위반 사항을 찾아 리스트업합니다.
4. 사용자에게 위반 사항을 보여주고 수정 여부를 확인합니다.
5. 승인된 항목에 대해 수정을 진행합니다.
6. ruff check --fix && ruff format 실행하여 린트/포맷 적용합니다.

## 주요 검사 항목
- 레이어 분리: 라우터(routers), 서비스(services), 쿼리(queries)로 구분되어 있는지
- 라우터에 비즈니스 로직이 포함되어 있지 않은지
- 서비스/쿼리에서 HTTPException을 사용하지 않는지
- 상수(매직 스트링, 허용 필드, 역할명, 상태값 등)가 `app/contents/`에 관심사별로 분리되어 있는지
- 모든 함수에 리턴 타입이 명시적으로 선언되어 있는지
- 모든 함수 파라미터에 타입이 명시되어 있는지
- **kwargs 대신 명시적 파라미터를 사용하는지
- 함수 네이밍 규칙: Router(HTTP동사_리소스), Service(동사_명사), Query(DB동작_대상)
- 스키마 네이밍: Request/Response/ListItem 접미사
- 파일 네이밍: routers/ → _route.py, schemas/ → _schema.py, services/ → _service.py, queries/ → _query.py
- ORM → Pydantic 변환 시 model_validate() 사용 여부
- 설정이 core/config.py에서 관리되는지
- .env 파일이 .gitignore에 포함되어 있는지
- 코드 변경 시 관련 문서(README, 라우터 summary/description, `Field(description=...)`, .env.example, Alembic 리비전)가 같은 작업 단위에서 갱신되었는지
- 기능 추가/수정 시 관련 테스트(tests/ 하위 레이어 미러링, 정상 + 실패/예외 흐름)가 같은 커밋 범위에 추가·갱신되었는지 (버그 수정은 회귀 테스트 필수)
- 테스트가 `@pytest.mark.skip`으로 비활성화된 채 커밋되지 않았는지 (부득이하면 reason 명시)
