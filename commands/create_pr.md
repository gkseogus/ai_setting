현재 브랜치의 커밋을 분석하고 PR을 자동 생성합니다.

## 인자
$ARGUMENTS — base 브랜치 (기본값: main)

## PR 템플릿
@/Users/hdh/Desktop/ai_setting/template/pull_request_template.md

## 작업 순서

1. `git log`로 base 브랜치 대비 현재 브랜치의 커밋 분석
2. `git diff <base>...HEAD`로 전체 변경 내용 파악
3. 커밋 prefix(`[feat]`, `[fix]` 등)에서 변경 유형 자동 판별
4. PR 템플릿의 각 섹션 자동 채움:
   - **변경 사항**: 커밋 메시지 기반 요약 (한글)
   - **변경 유형**: 커밋 prefix 기반 체크박스 선택
   - **테스트**: 변경 내용에 따라 테스트 항목 제안
   - **참고 사항**: 주요 변경 파일 및 리뷰 포인트
5. PR 제목은 `[타입] 한글 설명` 형식 (70자 이내)
6. 사용자에게 PR 내용을 보여주고 확인받기
7. `gh pr create`로 PR 생성
8. PR URL 반환

## 사용 예시

```bash
/create_pr              # main 기준 PR 생성
/create_pr develop      # develop 기준 PR 생성
```

## 주의사항
- PR 제목과 본문은 한글로 작성
- 커밋이 없으면 PR 생성하지 않기
- 원격에 push되지 않은 경우 push 여부 확인
