# Frontend Global Conventions

모든 프론트엔드 프로젝트(React/Next.js 등)에 적용되는 글로벌 코딩 컨벤션.

---

## 1. 상수 분리

컴포넌트 내 상수(라벨 맵, 옵션 배열, 색상, 설명 텍스트 등)는 `src/contents/` 폴더에 별도 파일로 관리한다.

```
src/contents/
├── dataPreview.ts      # DataPreview 관련 상수
├── pipelineProgress.ts # PipelineProgress 관련 상수
└── historyPage.ts      # HistoryPage 관련 상수/유틸
```

## 2. 화살표 함수

모든 함수는 화살표 함수로 작성한다. `function` 키워드 사용 금지. 컴포넌트 포함.

```tsx
// Bad
function MyComponent() { ... }
export default function MyComponent() { ... }

// Good
const MyComponent = () => { ... };
export default MyComponent;
```

## 3. useEffect 위치

`useEffect`는 return문 바로 위에 선언한다. 단, 인라인 컴포넌트가 있으면 인라인 컴포넌트 위에 선언한다.

```tsx
const MyComponent = () => {
  const [data, setData] = useState(null);

  // ... other hooks, handlers ...

  // useEffect는 return 바로 위
  useEffect(() => {
    fetchData();
  }, []);

  return <div>...</div>;
};
```

## 4. import 절대경로

`@/` 별칭을 사용한 절대경로만 허용한다. `../` 상대경로 사용 금지.

```tsx
// Bad
import { fn } from "../lib/api";
import Component from "../components/Component";

// Good
import { fn } from "@/lib/api";
import Component from "@/components/Component";
```

설정 필요:
- `tsconfig.app.json`: `"baseUrl": "."`, `"paths": { "@/*": ["src/*"] }`
- `vite.config.ts`: `resolve.alias: { "@": path.resolve(__dirname, "src") }`

## 5. 타입 네이밍

- `interface` → 접미사 `Face` 붙이기
- `type` → 접미사 `Type` 붙이기

```tsx
// Bad
interface CompanyInfo { ... }
type StepStatus = "pending" | "running";

// Good
interface CompanyInfoFace { ... }
type StepStatusType = "pending" | "running";
```

## 6. 상수 네이밍

모든 상수는 `UPPER_SNAKE_CASE`로 작성한다.

```tsx
// Bad
const stepDescriptions = { ... };
const defaultPageSize = 20;
const baseStepDescriptions: Record<string, string> = { ... };

// Good
const STEP_DESCRIPTIONS = { ... };
const DEFAULT_PAGE_SIZE = 20;
const BASE_STEP_DESCRIPTIONS: Record<string, string> = { ... };
```

## 7. 컴포넌트 분리 (1파일 1컴포넌트)

하나의 파일에는 하나의 컴포넌트만 존재해야 한다. 인라인 컴포넌트는 같은 디렉터리에 별도 파일로 분리한다.

```
// Bad - PipelineProgress.tsx 안에 ScoreBadge, StepIcon, StepItem 인라인 존재

// Good
src/components/
├── PipelineProgress.tsx  # PipelineProgress만 존재
├── ScoreBadge.tsx        # 분리된 인라인 컴포넌트
├── StepIcon.tsx          # 분리된 인라인 컴포넌트
└── StepItem.tsx          # 분리된 인라인 컴포넌트
```
