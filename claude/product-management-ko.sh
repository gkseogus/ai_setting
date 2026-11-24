#!/bin/bash
# product-management 플러그인의 스킬·커맨드 설명(description)을 한글로 바꾼다.
# 플러그인이 새 버전으로 올라가면 캐시 폴더가 새로 생겨 영어로 돌아가므로 그때 다시 실행한다.
# 새 스킬이 추가되면 아래에 set_desc 한 줄을 추가한다.
set -e

CACHE="$HOME/.claude/plugins/cache/knowledge-work-plugins/product-management"
COUNT=0

set_desc() { # <버전 폴더 기준 경로> <한글 설명>
  local f
  for f in "$CACHE"/*/"$1"; do
    [ -f "$f" ] || continue
    DESC="$2" awk '!hit && /^description:/ { print "description: " ENVIRON["DESC"]; hit = 1; next } { print }' "$f" > "$f.tmp"
    mv "$f.tmp" "$f"
    COUNT=$((COUNT + 1))
  done
}

set_desc commands/brainstorm.md '제품 아이디어, 문제 영역, 전략적 질문을 날카로운 사고 파트너와 함께 브레인스토밍합니다'
set_desc skills/competitive-brief/SKILL.md '하나 이상의 경쟁사나 기능 영역에 대한 경쟁 분석 브리프를 작성합니다. 제품 전략이나 기능 우선순위를 정할 때, 영업용 배틀 카드를 만들 때, 이사회·투자자 자료를 준비할 때, 어디서 차별화하고 어디서 동등 수준만 맞출지 결정할 때 사용합니다.'
set_desc skills/metrics-review/SKILL.md '추세 분석과 실행 가능한 인사이트로 제품 지표를 검토·분석합니다. 주간·월간·분기 지표 리뷰를 진행할 때, 갑작스러운 급등이나 급락을 조사할 때, 목표 대비 성과를 비교할 때, 원시 수치를 권장 조치가 담긴 스코어카드로 바꿀 때 사용합니다.'
set_desc skills/product-brainstorming/SKILL.md '사고 파트너로서 제품 아이디어를 브레인스토밍하고, 문제 영역을 탐색하고, 가정에 도전합니다. 새로운 기회를 탐색할 때, 제품 문제의 해결책을 만들어 낼 때, 아이디어를 검증할 때, PM이 방향을 정하기 전에 날카로운 스파링 파트너와 생각을 소리 내어 정리해야 할 때 사용합니다.'
set_desc skills/roadmap-update/SKILL.md '제품 로드맵을 업데이트하거나 새로 만들거나 우선순위를 다시 정합니다. 새 이니셔티브를 추가하면서 무엇을 뒤로 미룰지 정할 때, 새 정보가 들어와 우선순위를 바꿀 때, 의존성 지연으로 일정을 옮길 때, Now/Next/Later 뷰를 처음부터 만들 때 사용합니다.'
set_desc skills/sprint-planning/SKILL.md '스프린트를 계획합니다 — 작업 범위를 정하고, 가용 인력을 추정하고, 목표를 세우고, 스프린트 계획 초안을 작성합니다. 새 스프린트를 시작할 때, 팀 가용 시간(휴가·회의 반영)에 맞춰 백로그 규모를 잡을 때, 무엇이 P0이고 무엇이 스트레치인지 정할 때, 지난 스프린트에서 넘어온 작업을 처리할 때 사용합니다.'
set_desc skills/stakeholder-update/SKILL.md '대상과 주기에 맞춘 이해관계자 업데이트를 작성합니다. 경영진용 주간·월간 현황을 쓸 때, 출시를 알릴 때, 리스크나 블로커를 에스컬레이션할 때, 같은 진행 상황을 임원 브리프·엔지니어링 상세·고객용 버전으로 바꿔 쓸 때 사용합니다.'
set_desc skills/synthesize-research/SKILL.md '인터뷰, 설문, 피드백에서 나온 사용자 리서치를 구조화된 인사이트로 종합합니다. 인터뷰 노트·설문 응답·지원 티켓 더미를 정리해야 할 때, 주제를 뽑아 빈도와 영향도로 발견 사항의 순위를 매겨야 할 때, 원시 피드백을 로드맵 제안으로 바꾸고 싶을 때 사용합니다.'
set_desc skills/write-spec/SKILL.md '문제 정의나 기능 아이디어로부터 기능 명세서 또는 PRD를 작성합니다. 모호한 아이디어나 사용자 요청을 구조화된 문서로 바꿀 때, 목표와 비목표로 기능 범위를 정할 때, 성공 지표와 인수 조건을 정의할 때, 큰 요청을 단계별 명세로 나눌 때 사용합니다.'

if [ "$COUNT" -eq 0 ]; then
  echo "product-management 플러그인을 찾지 못했습니다: $CACHE" >&2
  exit 1
fi
echo "  product-management 설명 ${COUNT}개를 한글로 변경 (새 세션부터 적용)"
