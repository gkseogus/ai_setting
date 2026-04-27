# Frontend Global Conventions

모든 프론트엔드 프로젝트(React/Next.js 등)에 적용되는 글로벌 코딩 컨벤션.

---

## 1. 폴더 구조

```
src/
├── app/                  # Next.js App Router 페이지
├── components/           # 재사용 가능한 컴포넌트
│   ├── ui/               # 범용 UI (Button, Input, Modal, Card)
│   ├── layout/           # 레이아웃 (Header, Footer, Sidebar)
│   └── [feature]/        # 기능별 그룹 (post/, persona/, comment/)
├── api/                  # API 호출 함수 (관심사별 파일 분리)
├── hooks/                # 커스텀 훅 (React Query 훅 포함)
├── lib/                  # 유틸리티 함수, API 클라이언트
├── types/                # TypeScript 타입 정의
├── contents/             # 상수, 라벨 맵, 옵션 배열
├── stores/               # 전역 상태 관리 (Zustand 등)
├── styles/               # 글로벌 스타일
└── i18n/                 # 다국어 지원
```

- 컴포넌트 폴더는 **기능 단위**로 그룹핑한다.
- `contents/`와 `types/`는 컴포넌트와 분리하여 관리한다.

---

## 2. 상수 분리

컴포넌트 내 상수(라벨 맵, 옵션 배열, 색상, 설명 텍스트 등)는 `src/contents/` 폴더에 별도 파일로 관리한다.

```
src/contents/
├── dataPreview.ts      # DataPreview 관련 상수
├── pipelineProgress.ts # PipelineProgress 관련 상수
└── historyPage.ts      # HistoryPage 관련 상수/유틸
```

---

## 3. 화살표 함수

**컴포넌트, 유틸 함수, 핸들러**는 화살표 함수로 작성한다.
**Next.js 페이지 export**는 `function` 키워드를 허용한다.

```tsx
// 컴포넌트 - 화살표 함수
const MyComponent = () => { ... };
export default MyComponent;

// Next.js 페이지 - function 허용
export default function HomePage() { ... }

// 유틸/핸들러 - 화살표 함수
const handleClick = () => { ... };
const formatDate = (date: string) => { ... };
```

---

## 4. useEffect 위치

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

---

## 5. import 절대경로

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

---

## 6. 타입 네이밍

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

---

## 7. 상수 네이밍

모든 상수는 `UPPER_SNAKE_CASE`로 작성한다.

```tsx
// Bad
const stepDescriptions = { ... };
const defaultPageSize = 20;

// Good
const STEP_DESCRIPTIONS = { ... };
const DEFAULT_PAGE_SIZE = 20;
```

---

## 8. 컴포넌트 분리 (1파일 1컴포넌트)

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

---

## 9. 커스텀 훅 규칙

### 네이밍
- 반드시 `use` 접두사로 시작한다.
- 데이터 패칭 훅: `use` + 리소스명 (예: `usePosts`, `usePersona`)
- 유틸성 훅: `use` + 동작 (예: `useDebounce`, `useScrollProgress`)

### 구조
- 하나의 훅은 **단일 책임**을 가진다. 여러 관심사를 하나에 합치지 않는다.
- 반환 타입을 명시한다.
- `"use client"` 지시어를 파일 최상단에 선언한다.

```tsx
// Bad - 여러 책임이 섞인 훅
const usePostPage = () => {
  // 포스트 조회 + 댓글 조회 + 좋아요 + 북마크 전부 포함
};

// Good - 단일 책임
const usePosts = (params?: PostQueryParamsFace) => { ... };
const useComments = (postId: string) => { ... };
const useBookmarks = () => { ... };
```

### 파일 위치
- 범용 훅: `src/hooks/`
- 특정 컴포넌트 전용 훅: 해당 컴포넌트와 같은 폴더

---

## 10. API 호출 규칙

### 폴더 구조

API 호출 함수는 `src/api/` 폴더에 **관심사별로 파일을 분리**하여 관리한다.

```
src/api/
├── keys.ts             # 모든 React Query 키 (UPPER_SNAKE_CASE)
├── auth.ts             # 인증 관련 API
├── post.ts             # 포스트 관련 API
├── comment.ts          # 댓글 관련 API
├── user.ts             # 유저 관련 API
└── upload.ts           # 파일 업로드 API
```

### 쿼리 키 관리

모든 React Query 키는 `src/api/keys.ts`에 중앙 관리한다. 키는 `UPPER_SNAKE_CASE` 객체로 정의한다.

```tsx
// src/api/keys.ts
export const QUERY_KEYS = {
  posts: ["posts"] as const,
  postDetail: (slug: string) => ["posts", slug] as const,
  comments: (postId: string) => ["comments", postId] as const,
  user: ["user"] as const,
  personas: ["personas"] as const,
};
```

### API 함수 작성

API 함수는 `fetch` 또는 `axios`로 호출하며, 반환 타입을 명시한다.

```tsx
// src/api/post.ts
import type { PostFace, PostListResponseFace } from "@/types";

export const fetchPosts = async (page: number): Promise<PostListResponseFace> => {
  const res = await fetch(`/api/posts?page=${page}`);
  if (!res.ok) throw new Error("포스트 목록 조회 실패");
  return res.json();
};

export const fetchPostBySlug = async (slug: string): Promise<PostFace> => {
  const res = await fetch(`/api/posts/${slug}`);
  if (!res.ok) throw new Error("포스트 조회 실패");
  return res.json();
};
```

### React Query 훅

모든 API 호출은 **React Query(`useQuery`, `useMutation`)로 감싸서** 사용한다. 직접 `fetch`를 컴포넌트에서 호출하지 않는다. 훅은 `src/hooks/`에 위치한다.

```tsx
// src/hooks/usePosts.ts
"use client";

import { useQuery } from "@tanstack/react-query";
import { QUERY_KEYS } from "@/api/keys";
import { fetchPosts } from "@/api/post";
import type { PostListResponseFace } from "@/types";

export const usePosts = (page: number) => {
  return useQuery<PostListResponseFace>({
    queryKey: [...QUERY_KEYS.posts, page],
    queryFn: () => fetchPosts(page),
  });
};
```

```tsx
// src/hooks/usePost.ts
"use client";

import { useQuery } from "@tanstack/react-query";
import { QUERY_KEYS } from "@/api/keys";
import { fetchPostBySlug } from "@/api/post";
import type { PostFace } from "@/types";

export const usePost = (slug: string) => {
  return useQuery<PostFace>({
    queryKey: QUERY_KEYS.postDetail(slug),
    queryFn: () => fetchPostBySlug(slug),
    enabled: !!slug,
  });
};
```

### Mutation 훅

```tsx
// src/hooks/useCreatePost.ts
"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { QUERY_KEYS } from "@/api/keys";
import { createPost } from "@/api/post";

export const useCreatePost = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createPost,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEYS.posts });
    },
  });
};
```

### 금지 사항

```tsx
// Bad - 컴포넌트에서 직접 fetch
const MyComponent = () => {
  useEffect(() => {
    fetch("/api/posts").then(res => res.json()).then(setData);
  }, []);
};

// Bad - 쿼리 키 인라인 사용
useQuery({ queryKey: ["posts"], ... });

// Good - 훅으로 분리 + 중앙 키 사용
const { data, isLoading } = usePosts(1);
```

---

## 11. 에러/로딩 패턴

### 로딩 상태
- 스켈레톤 UI를 기본으로 사용한다. 스피너보다 스켈레톤을 우선한다.
- 로딩 영역의 크기와 레이아웃은 실제 콘텐츠와 동일하게 맞춘다.

```tsx
// Bad
if (isLoading) return <Spinner />;

// Good
if (isLoading) {
  return (
    <div className="space-y-4 animate-pulse">
      <div className="h-10 bg-white/5 rounded-xl w-3/4" />
      <div className="h-4 bg-white/5 rounded w-1/4" />
    </div>
  );
}
```

### 에러 상태
- 사용자에게 보여주는 에러 메시지는 기술 용어를 사용하지 않는다.
- 재시도 가능한 경우 재시도 버튼을 제공한다.

```tsx
// Bad
if (error) return <p>{error.message}</p>;

// Good
if (error) {
  return (
    <div className="text-center py-12">
      <p className="text-gray-400">데이터를 불러오지 못했습니다.</p>
      <button onClick={() => refetch()}>다시 시도</button>
    </div>
  );
}
```

### 빈 상태
- 데이터가 없을 때 빈 상태 UI를 반드시 제공한다.

```tsx
if (posts.length === 0) {
  return (
    <div className="text-center py-24 text-gray-500">
      <p className="text-lg">아직 게시된 포스트가 없습니다.</p>
    </div>
  );
}
```

### API 에러 핸들링
- axios 인터셉터에서 공통 에러(401, 500)를 처리한다.
- TanStack Query의 `onError`는 개별 페이지 수준에서 처리한다.

---

## 12. 스타일링 규칙

### Tailwind 클래스 순서

레이아웃 → 크기 → 간격 → 배경/테두리 → 텍스트 → 효과 → 반응형 순으로 작성한다.

```tsx
// Bad - 순서 없이 나열
<div className="text-white p-4 flex bg-black rounded-xl w-full mb-4 hover:bg-gray-900">

// Good - 순서 지켜서 작성
<div className="flex w-full mb-4 p-4 bg-black rounded-xl text-white hover:bg-gray-900">
```

### cn() 유틸 사용
- 조건부 클래스는 `cn()` 유틸리티 함수를 사용한다.

```tsx
// Bad
<div className={`px-4 py-2 ${isActive ? "bg-white" : "bg-gray-800"}`}>

// Good
<div className={cn("px-4 py-2", isActive ? "bg-white" : "bg-gray-800")}>
```

### 인라인 스타일 제한
- 인라인 `style`은 **동적 값**(서버에서 받은 색상, 계산된 위치 등)에만 사용한다.
- 정적 스타일은 반드시 Tailwind 클래스를 사용한다.

```tsx
// Bad - 정적 값에 인라인 스타일
<div style={{ backgroundColor: "#000", padding: "16px" }}>

// Good - 동적 값에만 인라인 스타일
<div
  className="p-4 rounded-xl"
  style={{ background: `linear-gradient(135deg, ${persona.primary_color}, ${persona.secondary_color})` }}
>
```

### 반응형 디자인
- 모바일 퍼스트로 작성한다. `sm:`, `md:`, `lg:` 순서로 확장한다.

```tsx
// Good - 모바일 퍼스트
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
```
