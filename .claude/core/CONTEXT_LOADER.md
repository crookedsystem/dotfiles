사용자의 요청을 분석하여 작업 유형(Backend, Frontend, Docs 등)과 기술 스택(FASTAPI, FLUTTER 등)을 식별합니다.
식별된 키워드에 맞춰 아래 매핑된 파일들을 serena or `read_file` 도구 or cat를 사용하여 '가장 먼저' 로드합니다.
파일 생성이나 코드 수정이 필요한 경우, 항상 `CODE_PRINCIPLES.md`와 `FILE_WRITE_PRINCIPLES.md`를 기본적으로 로드하십시오.

### 1. 🛡️ Core Principles (Always Required for Changes)
모든 코드 작성, 리팩토링, 파일 생성 작업 시 필수 참조:
- `./.claude/core/CODE_PRINCIPLES.md` : SOLID, KISS, 디자인 패턴, 주석 규칙, 리팩토링 체크리스트
- `./.claude/core/FILE_WRITE_PRINCIPLES.md` : 파일 인코딩(UTF-8), 한글/이모지 처리, Bash heredoc 사용 규칙

### 2. 🏗️ Domain Specific Contexts (Load based on Task Type)
작업의 영역(Domain)이 감지되면 해당 파일을 로드:
- **Backend Task** (API, DB, Server logic):
  - `./.claude/core/BACKEND.md` : API 설계(DTO, REST), DB(UUID, UTC), 백엔드 공통 규칙
- **Frontend Task** (UI, Client logic):
  - `./.claude/core/FRONTEND.md` : 반응형, 디렉토리 구조 등 기본 가이드
  - `./.claude/core/TOSS_FE_GUIDLINES.md` : (심화) 가독성, 응집도, React/TS 패턴, 복잡한 로직 구현 시

### 3. 📚 Documentation & Diagrams
- **Docs/Diagrams**:
  - `./.claude/core/MDX.md` : MDX 작성, Mermaid 다이어그램 문법, 문서화 규칙

### 4. 🛠️ Framework Specifics (Load based on Tech Stack)
특정 프레임워크 키워드가 감지되거나 해당 프로젝트 파일이 있을 때 로드:
- **Python / FASTAPI**:
  - `./.claude/framework/FASTAPI.md` : Pydantic, ruff, uv, 프로젝트 구조
  - *(권장)* Backend Task 파일들도 함께 로드
- **FLUTTER / Dart**:
  - `./.claude/framework/FLUTTER.md` : Riverpod, Feature-first 구조, 위젯 테스트
- **Java / Spring Boot**:
  - `./.claude/framework/SPRING_BOOT.md` : TestContainers, 의존성 관리
  - *(권장)* Backend Task 파일들도 함께 로드