새 기능/이니셔티브 단위로 Jira 에 Epic 하나 + 그 아래 Story / Task 들을 한 번에 등록한다.

## 인자
$ARGUMENTS — 새로 시작할 프로젝트(기능/이니셔티브) 설명. 자유 텍스트로 받는다.

예시 인자:
- `KAN 자동 퇴근 워커 리팩토링 — 워커가 한국시간 자정에 한 번만 발사되도록 정상화`
- `프로젝트 PETSIAGE 알림 센터 — 사용자에게 인앱/이메일 알림을 한곳에서 관리하는 통합 모듈`
- 비어 있으면 사용자에게 어떤 프로젝트(기능)인지 한 번 물어본다.

## 어디에 쓰는가
사용자의 Jira 워크스페이스는 `https://rebstudios.atlassian.net` 이고, 기본 프로젝트 키는 `KAN` 이다.
새 기능을 시작할 때마다 Epic 1개와 그 아래 실행 단위(Story / Task)를 묶음으로 자동 등록한다. 단일 티켓을 만드는 용도가 아니라, "이 기능 한 번 갈아엎으려면 어떤 작업들이 필요한지" 를 트리로 펼치는 용도다.

```
Epic (상위 묶음)
├── Story / Task — 추가 작업
├── Story / Task — 수정 작업
└── Story / Task — 부수 작업(테스트, 문서, 리팩토링 등)
```

## 작성 양식 (반드시 이 구조 그대로)

### Epic
- **Summary**: `<프로젝트명> — <한 줄 요약 제목>`
- **Priority**: 아래 "우선순위 배분 기준" 에 따라 부여한다 (기본 `High`).
- **Description** (Atlassian Document Format / Markdown 둘 다 허용):

```
## 목적
<왜 하는지. 어떤 문제가 있고, 이번 작업으로 무엇이 바뀌는지>

## 범위
<이 Epic 에 포함되는 것 / 포함되지 않는 것>

## 완료 조건
- <명확히 검증 가능한 항목 1>
- <항목 2>
```

### 하위 Story / Task (각각 1개씩 별도 이슈)
- **Summary**: `[<카테고리>] <행동 한 줄>` — 카테고리는 `추가`, `수정`, `테스트`, `문서`, `리팩토링`, `인프라` 중 하나.
- **Priority**: 아래 "우선순위 배분 기준" 에 따라 카테고리/성격별로 부여한다.
- **Description**:

```
## 무엇을
<무엇을 하는지 비개발자도 이해할 수 있게>

## 왜
<상위 Epic 의 어떤 부분을 풀어내는 작업인지>

## 작업 메모
- <필요한 파일/엔드포인트/주의점이 있다면 짧게>
```

- 모든 하위 이슈는 위 Epic 을 `parent` 로 묶는다 (Epic Link).
- 한 묶음의 하위 이슈는 3~7개 사이가 이상적. 너무 잘게 쪼개지 않는다.

## 우선순위 배분 기준

모든 이슈(Epic + 자식)에 `priority` 를 반드시 부여한다. KAN 프로젝트 우선순위 값은 `Highest`(id 1) / `High`(id 2) / `Medium`(id 3) / `Low`(id 4) / `Lowest`(id 5). 생성 시 `additional_fields.priority` 또는 생성 후 `editJiraIssue` 로 `{ "priority": { "id": "<id>" } }` 를 넣는다. 프로젝트마다 우선순위 이름/id 가 다를 수 있으므로 `getJiraIssueTypeMetaWithFields` 로 `priority.allowedValues` 를 먼저 확인하고 매핑한다.

기본 배분 규칙:

| 성격 / 카테고리 | 우선순위 |
|----------------|---------|
| 데이터 손상 · 보안 · 결제 · 인증/권한 관련 | `Highest` |
| 핵심 기능 구현 (`추가` · `수정` 중 사용자 가치를 직접 만드는 것), 장애 복구 | `High` |
| 일반 `테스트`, `인프라`, 부수적 `추가`/`수정` | `Medium` |
| `문서`, `리팩토링`, 정리성 작업 | `Low` |
| 있으면 좋지만 미뤄도 되는 nice-to-have | `Lowest` |

- **Epic 우선순위**는 자식 중 가장 높은 우선순위를 따른다 (자식에 `High` 가 있으면 Epic 도 최소 `High`). 기본값은 `High`.
- 인자에 사용자가 우선순위를 명시했으면(예: "이거 급함", "Highest 로") 그 지시를 우선한다.
- 카테고리만으로 애매하면 "이 작업이 안 되면 기능이 동작하지 않는가?" 로 판단한다. 그렇다면 `High` 이상, 아니면 `Medium` 이하.

## 말투 규칙
- Summary 는 **명사형 한 줄**. 예: "자동 퇴근 워커 cron 스케줄 KST 00:00 1회로 고정".
- Description 은 **음슴체 또는 평어** ("~함", "~한다"). 존댓말 금지.
- **비개발자도 이해할 수 있게** — 기술 용어 최소화. 어쩔 수 없이 쓰면 괄호로 짧게 풀어준다.
- **이모지 금지** — 사용자가 명시적으로 요청한 경우만 예외.

## 작업 순서

1. 인자에서 다음을 추출한다.
   - 프로젝트 키 (예: `KAN`) — 인자에 명시되어 있으면 그것, 아니면 사용자에게 한 번 물어본다. 디폴트는 `KAN`.
   - Epic Summary (한 줄)
   - 하위 이슈 후보 목록
2. `getAccessibleAtlassianResources` 로 `cloudId` 를 가져온다.
3. `getJiraProjectIssueTypesMetadata` 로 해당 프로젝트의 issueType 메타데이터를 확인한다.
   - Epic / Story / Task 의 정확한 `issuetype.id` 또는 name 을 잡는다. 프로젝트마다 다를 수 있으므로 응답을 보고 매핑한다.
   - 함께 `getJiraIssueTypeMetaWithFields` 로 `priority.allowedValues` 와 필수 필드를 확인한다. 각 이슈에 "우선순위 배분 기준" 에 따른 priority id 를 미리 매핑해 둔다.
4. **Epic 먼저 생성** — `createJiraIssue` 호출. priority 를 함께 부여한다.
   - 응답의 `key` (예: `KAN-101`) 를 보관.
5. **하위 Story/Task 들을 순차 생성** — 각각 `createJiraIssue` 호출 시 `fields.parent = { key: "<Epic key>" }` 로 묶고, 카테고리별 priority 를 함께 부여한다.
   - 일부 Jira Cloud 환경에서는 `customfield_10014` (Epic Link) 로 묶어야 하는 경우도 있다. 위 방법이 실패하면 그 필드로 재시도한다.
   - priority 를 생성 시 못 넣었으면 생성 직후 `editJiraIssue` 로 보정한다.
6. 생성된 이슈 키를 모아 요약을 출력한다. 형식:

```
Epic: <Epic key> — <Epic summary>
  └── <key> — <summary>
  └── <key> — <summary>
  ...

링크:
- https://rebstudios.atlassian.net/browse/<Epic key>
- https://rebstudios.atlassian.net/browse/<자식 key>
- ...
```

7. 사용자가 칸반 보드를 한 번에 보고 싶을 가능성이 높으니, 위 링크 외에 보드 URL 도 같이 출력한다:
   `https://rebstudios.atlassian.net/jira/software/projects/<프로젝트 키>/list`

## 주의사항
- **이슈를 통째로 덮어쓰지 않는다.** 기존 이슈는 건드리지 않고 새로 만든다. 기존 Epic 에 추가만 하고 싶다면 사용자가 인자에 기존 Epic key 를 적어 줘야 한다 (예: `KAN-39 아래에 추가: ...`). 이 경우 4번 단계를 건너뛰고 5번부터 진행한다.
- **사용자에게 확인 받기** — Epic 1개 + 자식 N개 구조를 만들기 직전, "다음 구조로 생성해도 될까요?" 라고 한 번 보여주고 진행한다. 인자가 충분히 구체적이면 생략해도 되지만, 자식이 8개 이상이거나 카테고리가 애매하면 반드시 묻는다.
- **자동 commit / push 금지** — 이 커맨드는 git 에 아무 것도 만지지 않는다. Jira 만 다룬다.
- **Story 와 Task 의 구분이 애매하면 Task 로 통일한다.** 일반 백오피스/내부 작업은 Task, 사용자 가치를 만드는 작업은 Story.
- **이슈 타입이 프로젝트에 없으면** — 예: 일부 프로젝트는 Epic 대신 "Initiative" 만 쓰는 경우가 있다. 3번 단계에서 확인한 metadata 에 맞춰 가장 가까운 상위 타입으로 대체한다.
- 본문에 PR 링크 / 외부 문서 링크가 있으면 Description 끝에 "참고" 섹션으로 모은다.
- **모든 이슈에 priority 를 빠뜨리지 않는다.** 생성 후 요약 출력 시 각 이슈 옆에 부여한 우선순위를 함께 표기한다.

## 예시 (참고용, 출력은 동일 구조로)

인자:
```
KAN Re:B Attendance 자동 퇴근 워커 정상화 + 17:00 KST 기록
```

생성되는 트리:
```
Epic: KAN-101 — Re:B Attendance — 자동 퇴근 워커 정상화 + 17:00 KST 기록  (High)
  └── KAN-102 — [수정] 자동 퇴근 cron 스케줄 매일 KST 00:00 1회로 고정  (High)
  └── KAN-103 — [수정] 자동 퇴근 기록 시각을 17:00 KST 로 변경  (High)
  └── KAN-104 — [추가] 자동 퇴근 워커 e2e 테스트 17건  (Medium)
  └── KAN-105 — [문서] 자동 퇴근 정책 README 갱신  (Low)

링크:
- https://rebstudios.atlassian.net/browse/KAN-101
- https://rebstudios.atlassian.net/browse/KAN-102
- https://rebstudios.atlassian.net/browse/KAN-103
- https://rebstudios.atlassian.net/browse/KAN-104
- https://rebstudios.atlassian.net/browse/KAN-105
- 보드: https://rebstudios.atlassian.net/jira/software/projects/KAN/list
```
