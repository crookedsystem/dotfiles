---
name: context-loader
description: |
  작업 시작 시 필수 컨텍스트 파일을 자동 로드하는 가이드.
  사용 시점: (1) 코드 작성/수정/리팩토링 시 CODE_PRINCIPLES.md + FILE_WRITE_PRINCIPLES.md 필수 로드,
  (2) Backend 작업(API, DB, Server) 시 BACKEND.md 로드,
  (3) Frontend 작업(UI, Client) 시 FRONTEND.md 로드 (심화: TOSS_FE_GUIDLINES.md),
  (4) 문서/다이어그램 작성 시 MDX.md 로드,
  (5) 프레임워크별: FASTAPI→FASTAPI.md+BACKEND.md, FLUTTER→FLUTTER.md+FRONTEND.md, SPRING_BOOT→SPRING_BOOT.md+BACKEND.md
  트리거 키워드: create, implement, build, add, fix, refactor, update, modify, write, 만들어, 구현, 추가, 수정, 리팩토링,
  API, endpoint, route, controller, service, repository, database, DB, query, migration,
  component, page, UI, form, button, modal, layout, style, CSS,
  FastAPI, Pydantic, uvicorn, Flutter, Dart, Riverpod, Spring Boot, JPA, Gradle
---

# Context Loader

작업 유형과 기술 스택을 분석하여 필요한 컨텍스트 파일을 로드한다.

## 필수 로드 (코드 변경 시 항상)

파일 생성, 코드 수정, 리팩토링 작업 시:
- `@.claude/core/CODE_PRINCIPLES.md` - SOLID, KISS, 주석 규칙
- `@.claude/core/FILE_WRITE_PRINCIPLES.md` - UTF-8, heredoc 규칙

## 도메인별 로드

| 작업 유형 | 로드 파일 |
|----------|----------|
| Backend (API, DB, Server) | `@.claude/core/BACKEND.md` |
| Frontend (UI, Client) | `@.claude/core/FRONTEND.md` |
| Frontend 심화 | `@.claude/core/TOSS_FE_GUIDLINES.md` |
| Docs/Diagrams | `@.claude/core/MDX.md` |

## 프레임워크별 로드

| 스택 | 로드 파일 |
|-----|----------|
| Python/FastAPI | `@.claude/framework/FASTAPI.md` + BACKEND.md |
| Flutter/Dart | `@.claude/framework/FLUTTER.md` + FRONTEND.md |
| Java/Spring Boot | `@.claude/framework/SPRING_BOOT.md` + BACKEND.md |
