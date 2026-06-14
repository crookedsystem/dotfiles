---
name: test-writer-skill
description: Comprehensive test code generation for Spring Boot/JUnit, NestJS/TypeScript, and Playwright E2E projects with Given-When-Then pattern. Use when the user requests test code creation, test coverage analysis, or asks to test specific code sections. Supports argument-based selective testing, staged changes analysis, framework-specific integration test setup guidance, and E2E testing with Playwright (headless mode, configurable batch size/workers for parallel execution).
---

# Test Writer Skill

자동화된 테스트 코드 작성 및 커버리지 분석을 지원하는 스킬이다.

## Workflow

### 1. 테스트 요청 분석

사용자의 테스트 요청을 분석하고 명확히 한다.

**모든 경우 공통:**
- Git diff를 확인하여 변경된 코드를 파악한다 (staged/unstaged 모두)
- 변경사항 중 테스트가 필요한 부분을 판단한다

**ARGUMENTS가 제공된 경우:**
- ARGUMENTS에 명시된 부분을 우선 테스트 대상으로 간주한다
- 예: "OrderService의 createOrder 메서드만 테스트해줘"
- Diff 분석 결과와 비교하여 ARGUMENTS 범위 외 추가로 테스트가 필요한 부분이 있는지 확인한다

**ARGUMENTS가 없는 경우:**
- Diff 분석 결과를 기반으로 테스트 대상을 제안한다
- 사용자에게 테스트 범위를 명확히 확인한다

### 2. Changes 분석 (공통 로직)

모든 테스트 요청에서 **staged와 unstaged 변경사항을 모두** 분석한다.

**Staged와 Unstaged 변경사항 확인:**

```bash
# Staged 변경사항
git diff --staged

# Unstaged 변경사항 (working directory)
git diff

# 또는 HEAD와 비교하여 모든 변경사항 확인
git diff HEAD
```

변경사항의 위치와 상태(staged/unstaged)를 파악한 후, 아래 기준에 따라 테스트 필요성을 판단한다.

**반드시 테스트해야 할 변경사항 판단 기준:**

다음 중 하나라도 해당하면 테스트가 필수다:

1. **비즈니스 로직 변경**
   - 계산 로직 (금액, 할인율, 수수료 등)
   - 상태 전환 로직 (주문 상태, 결제 상태 등)
   - 조건부 분기가 포함된 로직

2. **외부 시스템 연동 코드**
   - API 클라이언트 호출
   - 데이터베이스 쿼리 (복잡한 JOIN, 집계 등)
   - 메시지 큐 발행/구독

3. **보안 관련 변경**
   - 인증/인가 로직
   - 입력값 검증
   - 권한 체크

4. **데이터 일관성 관련**
   - 트랜잭션 처리
   - 동시성 제어
   - 데이터 검증 규칙

**테스트 불필요 판단 기준:**

다음은 테스트가 필수가 아니다:

- 단순 Getter/Setter 추가
- 상수 정의
- 로그 메시지 변경
- 주석 추가/수정
- 코드 포맷팅 변경

**사용자 피드백:**

변경사항 분석 후, 반드시 테스트가 필요한 항목과 선택적 테스트 항목을 구분하여 사용자에게 제시한다:

```
다음 변경사항을 발견했습니다:

[반드시 테스트 필요]
- OrderService.calculateTotalPrice(): 할인율 계산 로직 변경
- PaymentValidator.validateCard(): 카드 검증 규칙 추가

[선택적 테스트]
- OrderDto: 새로운 필드 추가 (deliveryNote)
- OrderRepository: 단순 조회 메서드 추가

반드시 테스트가 필요한 항목들을 테스트하시겠습니까?
추가로 선택적 항목도 테스트하시겠습니까?
```

### 3. 프레임워크 감지

프로젝트의 테스트 프레임워크를 감지한다.

**Spring Boot + JUnit 감지:**
- `pom.xml` 또는 `build.gradle`에서 `spring-boot-starter-test` 확인
- `src/test/java` 디렉토리 존재 확인
- `@SpringBootTest`, `@WebMvcTest` 등의 어노테이션 사용 확인

**Spring Boot 프로젝트로 감지되면:**
- [references/spring-boot-junit.md](references/spring-boot-junit.md)를 로드한다

**NestJS + TypeScript 감지:**
- `package.json`에서 `@nestjs/testing`, `jest` 확인
- `test/` 디렉토리 또는 `.spec.ts` 파일 확인
- `describe`, `it` 패턴 사용 확인

**NestJS 프로젝트로 감지되면:**
- [references/nestjs-typescript.md](references/nestjs-typescript.md)를 로드한다

**Playwright E2E 테스트 감지:**
- `package.json`에서 `@playwright/test` 확인
- `playwright.config.ts` 파일 존재 확인
- `tests/` 또는 `e2e/` 디렉토리에 `.spec.ts` 파일 확인

**Playwright 프로젝트로 감지되면:**
- [references/playwright-e2e.md](references/playwright-e2e.md)를 로드한다

### 4. 테스트 환경 설정 확인

**Spring Boot 프로젝트의 경우:**
1. `src/test/resources/application.yaml` 읽기
2. Test Container vs 전용 Test DB 판단
3. Integration Test 가이드는 이미 로드한 spring-boot-junit.md를 참조

**NestJS 프로젝트의 경우:**
1. `package.json`의 test scripts 확인
2. `test/database.config.ts` 또는 환경 변수 확인
3. E2E Test 설정은 이미 로드한 nestjs-typescript.md를 참조

**Playwright E2E 프로젝트의 경우:**
1. `playwright.config.ts`에서 baseURL, headless 모드, workers 설정 확인
2. 테스트 데이터 초기화 스크립트 확인 (setup/teardown)
3. E2E Test 가이드는 이미 로드한 playwright-e2e.md를 참조

### 5. 테스트 코드 작성

**필수 준수 사항:**

1. **Given-When-Then 패턴 사용**
   - 모든 테스트는 Given-When-Then 구조를 따른다
   - 주석으로 각 섹션을 명확히 구분한다

2. **한국어 테스트 메서드명 또는 한국어 설명**
   - JUnit: `@DisplayName("재고가 충분할 때 주문을 생성한다")`
   - Jest/NestJS: `it('재고가 충분할 때 주문을 생성한다', async () => { ... })`

3. **프레임워크별 패턴 준수**
   - Spring Boot: 이미 로드한 spring-boot-junit.md 참조
   - NestJS: 이미 로드한 nestjs-typescript.md 참조
   - Playwright: 이미 로드한 playwright-e2e.md 참조

**테스트 작성 순서:**

1. **ARGUMENTS로 명시된 부분 테스트**
   - 사용자가 요청한 정확한 범위만 구현한다

2. **추가 테스트 제안**
   - 작성한 테스트 외에 추가로 필요한 테스트가 있는지 분석한다
   - 누락된 엣지 케이스, 예외 케이스를 사용자에게 제안한다
   - 예: "InvalidQuantityException 케이스도 테스트하시겠습니까?"

3. **사용자 확인 후 추가 구현**
   - 사용자가 동의한 추가 테스트만 구현한다

### 6. 테스트 실행 가이드

작성한 테스트 코드와 함께 실행 명령어를 제공한다.

**Spring Boot:**
```bash
# 전체 테스트 실행
./gradlew test

# 특정 테스트 클래스 실행
./gradlew test --tests OrderServiceTest

# 커버리지 리포트 생성
./gradlew test jacocoTestReport
```

**NestJS:**
```bash
# 전체 테스트 실행
npm test

# 특정 파일 테스트
npm test order.service.spec.ts

# 커버리지 리포트 생성
npm run test:cov

# E2E 테스트
npm run test:e2e
```

**Playwright:**
```bash
# 전체 E2E 테스트 실행 (headless)
npx playwright test

# 특정 테스트 파일 실행
npx playwright test login.spec.ts

# Headed 모드로 실행 (브라우저 UI 보임)
npx playwright test --headed

# 병렬 실행 워커 수 지정
npx playwright test --workers=4

# 디버그 모드 (단계별 실행)
npx playwright test --debug

# HTML 리포트 생성 및 열기
npx playwright show-report
```

## 사용자 인터랙션 패턴

### 패턴 1: 명확한 요청

**사용자:** "OrderService의 createOrder 메서드를 테스트해줘"

**응답:**
1. 프레임워크 감지 (예: Spring Boot + JUnit)
2. 테스트 환경 확인 (application.yaml 읽기)
3. createOrder 메서드의 테스트 케이스 작성
4. 추가 테스트 제안: "InvalidQuantityException 케이스와 InsufficientStockException 케이스도 테스트하시겠습니까?"

### 패턴 2: 범위가 불명확한 요청

**사용자:** "테스트 코드 작성해줘"

**응답:**
1. Staged/Unstaged 변경사항 확인 (`git diff HEAD` 또는 `git diff --staged` + `git diff`)
2. 반드시 테스트 필요 항목과 선택적 항목 구분하여 제시
3. 사용자에게 테스트 범위 확인
4. 확인된 범위만 테스트 작성

### 패턴 3: Changes 기반 요청

**사용자:** "변경사항 중에 테스트 필요한 부분 찾아서 테스트 작성해줘"

**응답:**
1. `git diff HEAD` 실행 (또는 `git diff --staged`와 `git diff` 모두)
2. 변경사항을 "반드시 테스트 필요", "선택적 테스트", "테스트 불필요"로 분류
3. "반드시 테스트 필요" 항목 자동 선택
4. "선택적 테스트" 항목은 사용자에게 확인
5. 선택된 항목만 테스트 작성

## 금지 사항

1. **사용자가 요청하지 않은 범위를 임의로 테스트하지 않는다**
   - ARGUMENTS가 "createOrder 메서드만"이라면, updateOrder는 테스트하지 않는다

2. **Given-When-Then 패턴을 생략하지 않는다**
   - 모든 테스트는 반드시 세 섹션으로 나눈다

3. **테스트 환경 설정을 확인하지 않고 코드를 작성하지 않는다**
   - application.yaml이나 package.json을 먼저 확인한다

4. **프레임워크별 레퍼런스를 무시하지 않는다**
   - Spring Boot 프로젝트: 프레임워크 감지 시 로드한 spring-boot-junit.md를 반드시 참조한다
   - NestJS 프로젝트: 프레임워크 감지 시 로드한 nestjs-typescript.md를 반드시 참조한다
   - Playwright 프로젝트: 프레임워크 감지 시 로드한 playwright-e2e.md를 반드시 참조한다

## 예시

### 예시 1: Spring Boot Integration Test

**사용자 요청:**
"OrderService의 createOrder 메서드를 Integration Test로 작성해줘. Test Container 사용 중이야."

**처리 과정:**
1. Spring Boot 프로젝트 감지 및 spring-boot-junit.md 로드
2. `src/test/resources/application.yaml` 확인
3. Test Container 설정 확인
4. 로드한 spring-boot-junit.md의 Test Container 섹션 참조
5. Given-When-Then 패턴으로 테스트 작성
6. 추가 테스트 제안: "재고 부족 케이스도 테스트하시겠습니까?"

### 예시 2: NestJS Unit Test

**사용자 요청:**
"변경사항 중에서 테스트 필요한 부분 찾아서 테스트 작성해줘"

**처리 과정:**
1. `git diff HEAD` 실행 (또는 staged/unstaged 모두 확인)
2. 변경사항 분석:
   - order.service.ts의 calculateDiscount() 메서드 변경 → 반드시 테스트 필요
   - order.dto.ts에 새 필드 추가 → 선택적 테스트
3. 사용자에게 제시:
   ```
   [반드시 테스트 필요]
   - OrderService.calculateDiscount(): 할인율 계산 로직 변경

   [선택적 테스트]
   - CreateOrderDto: customerNote 필드 추가

   calculateDiscount 메서드를 테스트하시겠습니까?
   customerNote 검증 로직도 테스트하시겠습니까?
   ```
4. 사용자 응답에 따라 테스트 작성

### 예시 3: Playwright E2E Test

**사용자 요청:**
"로그인 플로우 E2E 테스트 작성해줘. QA 항목별로 비즈니스 설명을 포함하고, 로컬에서 headless로 실행되게 해줘. 병렬 실행은 2개씩 해."

**처리 과정:**
1. Playwright 프로젝트 감지 및 playwright-e2e.md 로드
2. `playwright.config.ts` 확인하여 현재 설정 파악
3. 로그인 플로우의 비즈니스 시나리오 분석:
   - 정상 로그인
   - 잘못된 비밀번호
   - 존재하지 않는 계정
   - 빈 입력값 검증
4. 각 QA 항목에 비즈니스 의미를 담은 테스트 작성
5. playwright.config.ts에 headless: true, workers: 2 설정 확인/추가
6. 테스트 실행 명령어 제공:
   ```bash
   npx playwright test login.spec.ts --workers=2
   ```
