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
4. **Epic 먼저 생성** — `createJiraIssue` 호출.
   - 응답의 `key` (예: `KAN-101`) 를 보관.
5. **하위 Story/Task 들을 순차 생성** — 각각 `createJiraIssue` 호출 시 `fields.parent = { key: "<Epic key>" }` 로 묶는다.
   - 일부 Jira Cloud 환경에서는 `customfield_10014` (Epic Link) 로 묶어야 하는 경우도 있다. 위 방법이 실패하면 그 필드로 재시도한다.
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

## 예시 (참고용, 출력은 동일 구조로)

인자:
```
KAN Re:B Attendance 자동 퇴근 워커 정상화 + 17:00 KST 기록
```

생성되는 트리:
```
Epic: KAN-101 — Re:B Attendance — 자동 퇴근 워커 정상화 + 17:00 KST 기록
  └── KAN-102 — [수정] 자동 퇴근 cron 스케줄 매일 KST 00:00 1회로 고정
  └── KAN-103 — [수정] 자동 퇴근 기록 시각을 17:00 KST 로 변경
  └── KAN-104 — [추가] 자동 퇴근 워커 e2e 테스트 17건
  └── KAN-105 — [문서] 자동 퇴근 정책 README 갱신

링크:
- https://rebstudios.atlassian.net/browse/KAN-101
- https://rebstudios.atlassian.net/browse/KAN-102
- https://rebstudios.atlassian.net/browse/KAN-103
- https://rebstudios.atlassian.net/browse/KAN-104
- https://rebstudios.atlassian.net/browse/KAN-105
- 보드: https://rebstudios.atlassian.net/jira/software/projects/KAN/list
```
