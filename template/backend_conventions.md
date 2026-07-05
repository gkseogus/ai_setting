# Backend Global Conventions

모든 백엔드 프로젝트(FastAPI/Python)에 적용되는 글로벌 코딩 컨벤션.

---

## 1. 레이어 구조

```
app/
├── routers/       # HTTP 요청/응답 처리만 (thin layer)
├── services/      # 비즈니스 로직 (검증, 변환, 조합)
├── queries/       # DB 쿼리 (CRUD, 필터링, 페이지네이션)
├── models/        # SQLAlchemy ORM 모델
├── schemas/       # Pydantic 스키마 (요청/응답 DTO)
├── contents/      # 상수, 매직 스트링, 허용 필드 등
├── core/          # 설정, 공통 유틸
└── db/            # DB 세션, 엔진
```

- **Router**: 요청 파싱, 의존성 주입, 응답 반환만 담당. 비즈니스 로직 금지.
- **Service**: 비즈니스 로직 처리. Query를 호출하여 데이터 조작.
- **Query**: DB 접근만 담당. SQLAlchemy 쿼리 작성. 비즈니스 로직 금지.

```python
# Bad - 라우터에 비즈니스 로직
@router.post("/content")
def create(request: Request, db: Session = Depends(get_db)):
    if not validate(request):  # 비즈니스 로직
        raise HTTPException(...)
    content = Content(**request.model_dump())  # DB 직접 접근
    db.add(content)
    ...

# Good - 라우터는 위임만
@router.post("/content")
def create(request: Request, db: Session = Depends(get_db)) -> Response:
    return some_service(db, request)
```

---

## 2. 상수 분리

비즈니스 상수(매직 스트링, 허용 필드 목록, 역할명, 상태값 등)는 `app/contents/` 폴더에 관심사별 파일로 관리한다.
라우터, 서비스, 쿼리 파일 내에 상수를 인라인으로 정의하지 않는다.

```
app/contents/
├── auth.py         # 인증 관련 상수 (ROLE_ADMIN, ALGORITHM 등)
├── content.py      # 콘텐츠 관련 상수 (STATUS_PUBLISH, ALLOWED_CONTENT_UPDATE_FIELDS 등)
└── persona.py      # 페르소나 관련 상수 (ALLOWED_PERSONA_UPDATE_FIELDS 등)
```

```python
# Bad - 쿼리 파일에 상수 인라인 정의
ALLOWED_CONTENT_UPDATE_FIELDS = {"title", "slug", "status"}

def update_content(db: Session, content: Content, updates: dict) -> Content:
    ...

# Good - contents/에서 import
from app.contents.content import ALLOWED_CONTENT_UPDATE_FIELDS

def update_content(db: Session, content: Content, updates: dict[str, object]) -> Content:
    ...
```

```python
# Bad - 매직 스트링 직접 사용
if user.role != "admin":
    ...

# Good - 상수 import
from app.contents.auth import ROLE_ADMIN

if user.role != ROLE_ADMIN:
    ...
```

> `core/config.py`의 환경변수 설정은 상수가 아니므로 `contents/`로 이동하지 않는다.

---

## 3. 리턴 타입 명시

**모든 함수**는 반환 타입을 명시적으로 선언해야 한다. 예외 없음.

```python
# Bad
def get_user(db, user_id):
    return db.query(User).filter(User.id == user_id).first()

def process_data(data):
    return {"result": data}

# Good
def get_user(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()

def process_data(data: dict) -> dict[str, str]:
    return {"result": data}
```

### 라우터 함수
```python
# 반드시 response_model과 함수 리턴 타입 모두 선언
@router.get("", response_model=PaginatedContents)
def list_contents(db: Session = Depends(get_db)) -> PaginatedContents:
    ...
```

### 서비스 함수
```python
def ingest_content(db: Session, request: IngestRequest) -> IngestResponse:
    ...
```

### 쿼리 함수
```python
def get_content_by_slug(db: Session, slug: str) -> Content | None:
    ...

def get_published_contents(db: Session, offset: int, limit: int) -> tuple[list[Content], int]:
    ...
```

---

## 4. 파라미터 타입 명시

함수 파라미터도 반드시 타입을 명시한다. `**kwargs` 사용 금지. 명시적 파라미터로 선언한다.

```python
# Bad
def create_content(db: Session, **kwargs) -> Content:
    ...

# Good
def create_content(
    db: Session,
    title: str,
    slug: str,
    sections: list[dict[str, str]],
    layout: list[dict[str, str]],
    meta_description: str = "",
    status: str = "publish",
) -> Content:
    ...
```

---

## 5. 네이밍 규칙

### 함수명
- Router: `HTTP동사_리소스` (예: `list_contents`, `get_content`, `create_content_route`)
- Service: `동사_명사` (예: `ingest_content`, `validate_layout`)
- Query: `DB동작_대상` (예: `get_content_by_slug`, `get_published_contents`, `create_content`)

### 스키마 네이밍
- Request DTO: `동사+Request` (예: `IngestRequest`)
- Response DTO: `명사+Response` (예: `ContentResponse`, `IngestResponse`)
- 리스트 아이템: `명사+ListItem` (예: `ContentListItem`)

### 파일 네이밍
`routers/`, `schemas/`, `services/`, `queries/` 디렉터리 안의 파일은 레이어별 접미사를 붙인다.

| 디렉터리 | 접미사 | 예시 |
|----------|--------|------|
| `routers/` | `_route.py` | `content_route.py`, `ingest_route.py` |
| `schemas/` | `_schema.py` | `content_schema.py`, `ingest_schema.py` |
| `services/` | `_service.py` | `content_service.py`, `ingest_service.py` |
| `queries/` | `_query.py` | `content_query.py`, `user_query.py` |

```
# Bad
routers/contents.py
schemas/content.py
services/content.py
queries/content.py

# Good
routers/content_route.py
schemas/content_schema.py
services/content_service.py
queries/content_query.py
```

> `models/`, `core/`, `db/` 등 다른 디렉터리의 파일에는 접미사를 붙이지 않는다.

### 모델 네이밍
- SQLAlchemy 모델: 단수형 PascalCase (예: `Content`, `User`)
- 테이블명: 복수형 snake_case (예: `contents`, `users`)

---

## 6. Pydantic 스키마 규칙

- ORM → Pydantic 변환 시 `model_validate()` 명시적 사용.
- `model_config = {"from_attributes": True}` 설정.

```python
# ORM 결과를 Pydantic으로 변환
items = [ContentListItem.model_validate(row) for row in rows]
```

---

## 7. 에러 처리

- Router에서 HTTPException 발생.
- Service/Query에서는 HTTPException 사용 금지. 값 반환 또는 커스텀 예외 사용.

```python
# Bad - 서비스에서 HTTPException
def get_user_service(db: Session, user_id: int) -> User:
    user = get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404)  # 금지
    return user

# Good - 서비스는 None 반환, 라우터에서 처리
def get_user_service(db: Session, user_id: int) -> User | None:
    return get_user(db, user_id)

@router.get("/{user_id}")
def get_user_route(user_id: int, db: Session = Depends(get_db)) -> UserResponse:
    user = get_user_service(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)
```

---

## 8. 설정 관리

- 환경변수 및 시크릿은 `app/core/config.py`에서 관리.
- 프로덕션: AWS Secrets Manager 사용.
- 로컬 개발: `.env` 파일 사용.
- `.env` 파일은 절대 커밋하지 않는다 (`.gitignore` 포함).

---

## 9. 린트 & 포맷터

- **Ruff**: 린트 + 포맷터 통합 사용.
- `pyproject.toml`에 설정 통합.

```toml
[tool.ruff]
target-version = "py311"
line-length = 120

[tool.ruff.lint]
select = ["E", "F", "I", "ANN", "B", "UP"]

[tool.ruff.lint.per-file-ignores]
"alembic/*" = ["ANN"]
```

- `ANN`: 리턴 타입 / 파라미터 타입 누락 시 에러.
- 커밋 전 `ruff check --fix && ruff format` 실행.

---

## 10. 문서 업데이트

코드 변경 시 관련 문서를 **같은 작업 단위 안에서 함께 업데이트**한다. 문서 갱신을 별도 작업으로 미루지 않는다.

### 업데이트 대상
- `README.md`: 설치/실행, 마이그레이션, 환경변수, 실행 명령이 바뀌면 반드시 갱신한다.
- API 문서: FastAPI는 라우터의 `summary` / `description` / `response_model` 과 스키마의 `Field(description=...)` 를 최신 상태로 유지한다. OpenAPI(`/docs`)가 실제 동작과 일치해야 한다.
- `.env.example`: 새 환경변수(`app/core/config.py` 추가분)를 즉시 반영한다. 실제 값·시크릿은 넣지 않는다.
- 마이그레이션: 스키마(모델) 변경 시 Alembic 리비전을 같은 작업에서 생성하고, 필요한 실행 순서를 문서에 남긴다.

### 규칙
- 엔드포인트를 추가/변경/삭제하면 요청·응답 스키마 설명을 함께 갱신한다. 죽은 문서·예시를 남기지 않는다.
- 스키마 필드가 바뀌면 `response_model` 과 문서 예시를 동기화한다.
- 상수(`app/contents/`)의 의미가 문서에 설명돼 있다면 함께 수정한다.

```python
# Good - 새 필드 추가 시 스키마 description 과 README 예시를 함께 갱신
class ContentResponse(BaseModel):
    slug: str = Field(description="콘텐츠 고유 슬러그")
    model_config = {"from_attributes": True}
```

---

## 11. 테스트 코드

기능을 추가하거나 수정하면 **관련 테스트를 같은 커밋 범위에서 함께 추가·갱신**한다. 테스트 없이 "동작한다"고 보고하지 않는다.

### 도구
- **pytest** + `pytest-asyncio`(비동기 라우터/서비스).
- 라우터 테스트: FastAPI `TestClient` 또는 `httpx.AsyncClient`.
- DB 의존 테스트: 트랜잭션 롤백 픽스처 또는 별도 테스트 DB/SQLite 사용. 운영 DB에 붙지 않는다.

### 파일 위치 & 네이밍
- 테스트는 `tests/` 하위에 레이어 구조를 미러링한다.
- 파일명은 `test_대상.py`, 함수명은 `test_동작` 으로 작성한다.

```
tests/
├── routers/test_content_route.py
├── services/test_content_service.py
└── queries/test_content_query.py
```

### 레이어별 테스트 범위
- **Router**: 상태 코드, 응답 스키마, 인증/권한, 에러(404/400 등) 분기.
- **Service**: 비즈니스 로직 · 검증 · 변환. Query는 목킹하거나 테스트 DB로 검증.
- **Query**: 실제 세션으로 CRUD·필터·페이지네이션 결과 검증.

### 작성 규칙
- 픽스처(`conftest.py`)로 DB 세션·클라이언트·샘플 데이터를 공유한다. 테스트 간 상태를 격리한다(각 테스트 후 롤백).
- 정상 흐름 + 실패/예외 흐름(§7의 404/400 등)을 각각 최소 1개 검증한다.
- 버그 수정 시 **해당 버그를 재현하는 회귀 테스트**를 반드시 추가한다.
- 파라미터 조합이 많으면 `@pytest.mark.parametrize` 로 표현한다.
- 테스트 함수도 §3·§4 규칙(리턴/파라미터 타입 명시)을 따른다. 단 `ANN` 은 `tests/*` 에서 완화할 수 있다.

```python
# Good - 정상 + 에러 흐름을 함께 검증
def test_get_content_returns_404_when_missing(client: TestClient) -> None:
    res = client.get("/contents/unknown-slug")
    assert res.status_code == 404
```

### 금지 사항
- 테스트를 비활성화(`@pytest.mark.skip`)한 채 커밋하는 것. 부득이하면 사유를 주석/`reason=` 으로 남긴다.
- 타입체크·lint 통과만으로 검증을 대체하는 것. 실제 동작을 테스트로 관찰해야 한다.
