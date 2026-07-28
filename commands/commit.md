현재 프로젝트의 변경점을 분석하고 커밋합니다.

## 인자
$ARGUMENTS — 커밋 대상 설명 (선택사항). 비어 있으면 전체 변경점 자동 분석.

## 커밋 메시지 형식

### 일반 프로젝트
```
[타입] 한글 설명
```

### 모노레포 (frontend/, backend/, infra/ 등 서브디렉토리가 존재하는 경우)
```
[타입](스코프) 한글 설명
```

## 타입
- `feat` — 새 기능
- `fix` — 버그 수정
- `update` — 기존 기능 개선/변경
- `refactor` — 리팩토링 (동작 변경 없음)
- `chore` — 설정, 의존성, 빌드 등
- `docs` — 문서
- `test` — 테스트
- `style` — 코드 포맷, 세미콜론 등 (동작 변경 없음)

## 스코프 (모노레포 전용)
변경된 파일이 속한 최상위 디렉토리명. 예: `frontend`, `backend`, `infra`, `shared`
- 여러 스코프에 걸친 변경이면 스코프 생략
- 루트 설정 파일만 변경되면 스코프 생략

## 작업 순서

1. `git status`로 변경된 파일 확인
2. `git diff`로 변경 내용 분석
3. `git log --oneline -5`로 최근 커밋 스타일 확인
4. 모노레포 여부 판단: 프로젝트 루트에 `frontend/`, `backend/`, `apps/`, `packages/` 같은 서브디렉토리가 있으면 모노레포
5. **변경된 파일을 하나씩 개별 커밋한다.** 각 파일마다 아래를 반복:
   1. 변경 내용에 맞는 타입 선택
   2. 모노레포면 해당 파일의 스코프 판단
   3. 한글로 간결한 커밋 메시지 작성
   4. `git add <파일 경로>`로 **그 파일만** 스테이징 (민감한 파일 .env 등 제외)
   5. 커밋 실행
6. 모든 변경 파일이 커밋될 때까지 5를 반복
   - 단, 분리하면 빌드·테스트가 깨지는 관련 파일(예: 컴포넌트+테스트, 자동 생성물)은 하나의 커밋으로 함께 처리

## 예시

```bash
# 일반 프로젝트
git commit -m "[feat] 검색 필터링 기능 추가"
git commit -m "[fix] 로그인 토큰 만료 처리 수정"
git commit -m "[chore] .gitignore에 tsbuildinfo 추가"

# 모노레포
git commit -m "[feat](frontend) 검색바 컴포넌트 추가"
git commit -m "[fix](backend) 동시 예약 deadlock 해결"
git commit -m "[chore](infra) Terraform 모듈 업데이트"
git commit -m "[refactor] 공통 유틸 함수 정리"  # 여러 스코프에 걸침

# 파일 단위 커밋 (한 작업에서 여러 파일이 바뀐 경우 파일별로 나눠 커밋)
git add src/components/SearchBar.tsx && git commit -m "[feat] 검색바 컴포넌트 추가"
git add src/hooks/useSearch.ts       && git commit -m "[feat] 검색 훅 추가"
git add README.md                    && git commit -m "[docs] 검색 기능 사용법 추가"
```

## 주의사항
- 커밋 메시지는 반드시 한글로 작성
- "~를 추가", "~를 수정", "~를 개선" 등 동사로 끝내기
- **각 파일당 하나의 커밋으로 나눈다 (파일 단위 커밋).** 변경 파일마다 개별 커밋을 만들고, 여러 파일을 한 커밋에 몰아넣지 않는다
  - 예외: 분리하면 빌드·테스트가 깨지는 관련 파일(컴포넌트+테스트 등)은 함께 커밋
- .env, credentials 등 민감한 파일은 절대 커밋하지 않기
- 커밋 전에 사용자에게 메시지를 보여주고 확인받기
