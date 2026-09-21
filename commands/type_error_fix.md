Pylance / pyright / mypy 정적 타입 진단("인수 형식을 알 수 없습니다", "부분적으로 알 수 없습니다", reportUnknown*, reportGeneralTypeIssues 등)을 `# type: ignore` 로 침묵시키지 않고 **타입 계약 누락이라는 근본 원인** 수준에서 수정하는 워크플로우.

## 글로벌 룰 (표면 vs 근본 판단 준용)
@/Users/hdh/Desktop/ai_setting/template/error_handling.md

---

## 실행 순서

### 1. Triage — 진단이 무엇의 신호인지 분류
- **(a) 실제 런타임 버그의 신호**: None 가능성 미처리, 잘못된 인자 타입, 존재하지 않는 속성 접근 등 → 타입 진단이 아니라 버그다. `/root_cause` 워크플로우로 전환.
- **(b) 타입 계약 누락**: 코드는 런타임에 정상 동작하지만 타입체커가 추론하지 못함 → 이 워크플로우 계속.
- 분류 결과와 근거를 한 문장으로 보고한 뒤 진행.

### 2. 원인 추적 — Unknown 의 발원지 찾기
진단이 뜬 라인은 **트리거**일 뿐이다. Unknown 이 처음 생긴 **발원지**를 거슬러 올라가 찾는다.
흔한 발원지:
- **바운드가 느슨한 TypeVar**: `TypeVar(bound=Base)` 처럼 실제로 쓰는 속성이 바운드에 선언돼 있지 않음 → 속성 접근이 전부 Unknown 이 되어 하류로 전파.
- 타입 스텁 없는 서드파티 반환값(Any)이 변수를 타고 전파.
- 빈 컨테이너 리터럴(`x = []`)에 타입 미지정.
- 데코레이터가 시그니처를 소실시킴(untyped decorator).

### 3. 근본 수정 — 패턴 카탈로그

| 발원지 증상 | 근본 수정 |
|---|---|
| TypeVar 바운드가 사용 속성을 모름 | 사용하는 속성을 전부 선언한 **Protocol** 을 만들어 바운드 교체 |
| SQLAlchemy 제네릭에서 컬럼 접근 Unknown | Protocol 에 `Mapped[...]` 로 컬럼 계약 선언 (아래 사례) |
| Optional 미좁힘 | `if x is None: return/raise` 로 조기 좁히기 |
| 빈 리터럴 Unknown | `x: list[str] = []` 처럼 선언부에 타입 명시 |
| 서드파티 Any 전파 | 받는 즉시 명시 타입 변수에 담아 전파 차단 |
| 입력에 따라 반환 타입이 갈림 | `@overload` |
| 구조 있는 dict 뭉치 | `TypedDict` 또는 dataclass |

- **금지**: `# type: ignore`, `cast(Any, ...)` 로 침묵시키는 표면 처리. 불가피하면 `# TODO(root-cause): <사유>` 주석 + 사용자에게 명시 보고.
- **유사 패턴 grep**: 같은 발원지 패턴(같은 TypeVar 바운드, 같은 Any 전파원)이 다른 파일에도 있는지 확인. 작업 범위 안이면 함께 수정, 범위 밖이면 보고만.

### 4. 검증 (반드시 모두 수행)
1. **에디터와 같은 엔진으로 재현 불가 확인**: `npx -y pyright --pythonpath .venv/bin/python <수정 파일 + 그 모듈을 import 하는 파일들>` → **0 errors**. Pylance 화면에서 노란줄이 "사라진 것 같다"는 검증이 아니다 — CLI 로 관찰한다.
2. **런타임 불변 확인**: 타이핑 전용 수정(Protocol, 어노테이션)이면 관련 pytest 가 그대로 통과해야 한다. 동작이 바뀌었다면 그건 타입 수정이 아니라 버그 수정이므로 1단계 (a) 로 재분류.
3. **lint**: `ruff check` + `ruff format --check` 통과.

### 5. 보고 (root_cause 5항목 그대로)
- **처리 방식**: 근본 / 표면
- **근본 원인**: Unknown 발원지 한 문장 (증거 기반)
- **수정 범위**: `파일:라인` + 함께 수정한 유사 패턴
- **검증 방법**: 실행한 pyright/pytest/ruff 명령과 결과
- **잔여 리스크 / 후속 작업**: 없으면 "없음" (저장소에 타입체크 CI 게이트가 없으면 그 사실을 명시)

---

## 사례: SQLAlchemy 제네릭 쿼리 (2026-09-21, reb_platform_backend)

- **증상**: `db.query(model).filter(stale)` 에서 "인수가 'filter' 함수의 'criterion' 매개 변수에 해당합니다 — 인수 형식을 알 수 없습니다".
- **발원지**: `JobT = TypeVar("JobT", bound=Base)`. `Base`(DeclarativeBase) 에는 큐 컬럼이 선언돼 있지 않아 `model.status` 등 모든 클래스 속성 접근이 Unknown → 비교식 → filter 인자로 전파.
- **수정**: 공통 컬럼 13개를 `Mapped[...]` 로 선언한 `QueueJobProtocol(Protocol)` 을 만들어 바운드 교체. `model(...)` 인스턴스화가 필요하면 프로토콜에 `def __init__(self, **kwargs: object) -> None: ...` 스텁(SQLAlchemy declarative `__init__` 미러)을 추가.
- **함정 2개**:
  1. Protocol 의 가변 속성은 **불변성** 매칭 — `Mapped[int]` vs `Mapped[int | None]` 을 모델 선언과 글자 그대로 일치시켜야 한다.
  2. `**kwargs: Any` 는 ruff ANN401 에 걸린다 — `object` 로 선언한다.

---

## 금지 사항
- `# type: ignore` / `cast` 를 붙이고 "수정했다"고 보고하는 것.
- pyright CLI 실행 없이 에디터 화면만 보고 "해결된 것 같다"고 보고하는 것.
- 런타임 버그의 신호(1단계 (a))를 타입 어노테이션으로 덮어 침묵시키는 것.
- 발원지를 찾지 않고 진단이 뜬 라인에만 어노테이션을 덧대는 것 (트리거 ≠ 원인).
