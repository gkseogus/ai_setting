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
├── core/          # 설정, 상수, 공통 유틸
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

## 2. 리턴 타입 명시

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

## 3. 파라미터 타입 명시

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

## 4. 네이밍 규칙

### 함수명
- Router: `HTTP동사_리소스` (예: `list_contents`, `get_content`, `create_content_route`)
- Service: `동사_명사` (예: `ingest_content`, `validate_layout`)
- Query: `DB동작_대상` (예: `get_content_by_slug`, `get_published_contents`, `create_content`)

### 스키마 네이밍
- Request DTO: `동사+Request` (예: `IngestRequest`)
- Response DTO: `명사+Response` (예: `ContentResponse`, `IngestResponse`)
- 리스트 아이템: `명사+ListItem` (예: `ContentListItem`)

### 모델 네이밍
- SQLAlchemy 모델: 단수형 PascalCase (예: `Content`, `User`)
- 테이블명: 복수형 snake_case (예: `contents`, `users`)

---

## 5. Pydantic 스키마 규칙

- ORM → Pydantic 변환 시 `model_validate()` 명시적 사용.
- `model_config = {"from_attributes": True}` 설정.

```python
# ORM 결과를 Pydantic으로 변환
items = [ContentListItem.model_validate(row) for row in rows]
```

---

## 6. 에러 처리

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

## 7. 설정 관리

- 환경변수 및 시크릿은 `app/core/config.py`에서 관리.
- 프로덕션: AWS Secrets Manager 사용.
- 로컬 개발: `.env` 파일 사용.
- `.env` 파일은 절대 커밋하지 않는다 (`.gitignore` 포함).

---

## 8. 린트 & 포맷터

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
