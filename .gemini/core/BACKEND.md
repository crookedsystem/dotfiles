# API Guide

- DTO :
  - Request : 맨 마지막에 ~ Request로 끝남 (ex: UserLoginRequest)
  - Response : 맨 마지막에 ~ Response로 끝남 (ex: UserLoginReponse)
  - 모든 변환은 Mapper 함수를 통해서 이루어짐 (ex: Entity -> DTO : UserMapper.toResponse(userEntity))
  - Request, Response는 필수값 여부, Validation 등을 명확히 기재
  - Description 필수

- API 규칙 :
  - API Description은 한국어로 작성
  - Restful API 규칙을 준수
  - Swagger 명세에는 API를 사용할 때 발생할 수 있는 모든 Exception Case를 명시

# Database

- Entity
  - Entity의 UUID는 uuid.v7() 사용
- Datetime
  - 항상 UTC로 지정
- Enum
  - Enum은 절대로 Inner Class로 사용하지 않고 각각 파일로 분리
  - Database에는 Varchar로 저장하지만 Enum Class로 변환해서 사용

# 🚀 **Ultimate Coding Guidelines**

These guidelines are designed to ensure clarity, maintainability, and extensibility in your code. Follow them consistently when writing or reviewing code.

---

## ✅ **1. SOLID Principles**

Adhere strictly to the SOLID principles:

| Principle             | Guideline                                                                                                            | Purpose                           |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| Single Responsibility | Every class/function should have **one responsibility**. Immediately split if responsibilities expand.               | Minimize impact of changes        |
| Open/Closed           | Code should be open for **extension** but closed to **modification**. Use interfaces, abstractions, and composition. | Maintain code stability           |
| Liskov Substitution   | Derived classes must be **fully substitutable** for base classes/interfaces without side effects or exceptions.      | Reliable inheritance hierarchy    |
| Interface Segregation | Prefer **small, specific interfaces** over large generic ones. Avoid forcing clients into unnecessary dependencies.  | Reduce coupling                   |
| Dependency Inversion  | Depend on **abstractions**, not on concrete implementations.                                                         | Improve flexibility & testability |

⚠️ **Important:**

- If the code complexity grows or responsibilities blur, consider it a SOLID violation and **refactor immediately**.

---

## 🎯 **2. Design Patterns**

Apply design patterns when they meaningfully improve readability, extensibility, or separation of concerns. Do not introduce patterns unnecessarily.

| Situation                      | Applicable Patterns              | Conditions / Purpose                                 |
| ------------------------------ | -------------------------------- | ---------------------------------------------------- |
| Object Creation & Management   | Factory Method, Abstract Factory | Encapsulate object creation logic                    |
| Complex Object Configuration   | Builder                          | Complex objects requiring step-by-step creation      |
| Global Shared Instances        | Singleton (**use sparingly**)    | Only for necessary global state management           |
| Algorithm/Logic Variations     | Strategy                         | Swappable algorithms (payments, auth methods)        |
| Behavior Dependent on State    | State                            | Objects frequently changing internal behavior        |
| Encapsulate Operations         | Command                          | Undo, redo, logging, task queuing                    |
| Inter-Object Communication     | Observer, Mediator               | Reduce coupling, implement pub/sub                   |
| Structure & Concern Separation | MVC, MVVM, Component-based       | Clearly separate responsibilities in complex systems |

⚠️ **Important:**

- **Composition** is always preferred over inheritance, unless clearly justified.
- Avoid adding complexity through unnecessary abstraction or patterns.

---

## 🧹 **3. Refactoring Checklist**

Always check these points during refactoring and mention improvements explicitly:

- [ ] Adheres to SOLID principles?
- [ ] Single clear responsibility?
- [ ] Improved naming or unclear logic?
- [ ] Design patterns used effectively?
- [ ] Abstraction clear and dependencies explicit?

---

## 🚨 **4. Anti-Patterns (Forbidden Practices)**

Avoid the following and refactor immediately upon identification:

- ❌ **God classes/functions** (multiple responsibilities)
- ❌ Empty methods to avoid forced interface implementation
- ❌ Deep and unnecessary inheritance chains
- ❌ Excessive global variables or Singleton abuse
- ❌ Over-complexity due to excessive pattern usage

---

## 🌟 **5. Additional Recommended Practices**

- **YAGNI (You Aren’t Gonna Need It)**: Avoid implementing unnecessary features prematurely; provide extensible structures instead.
- **DRY (Don't Repeat Yourself)**: Immediately abstract repeated code into separate modules or methods.
- Provide clear, SOLID-based feedback during code reviews to continually improve quality.

---

## 📌 **Commenting Guidelines**

주석은 **실용적인 사용법**과 **꼭 알아야 할 정보**만 작성합니다.

**포함할 내용:**
- 함수/클래스 사용법 (파라미터, 반환값)
- 중요한 전제조건이나 제약사항
- 예외 케이스나 엣지 케이스
- 외부 의존성이나 부작용

**제외할 내용:**
- SOLID 원칙이나 디자인 패턴 적용 내역
- 설계 의도나 아키텍처 결정 사항
- 리팩토링 히스토리

**예시:**

```java
/**
 * 사용자 인증 토큰을 검증합니다.
 *
 * @param token JWT 토큰 문자열
 * @return 검증 성공 시 userId, 실패 시 예외 발생
 * @throws InvalidTokenException 토큰이 만료되었거나 형식이 잘못된 경우
 */
public String validateToken(String token) { ... }

/**
 * 주의: 이 메서드는 DB 트랜잭션을 시작합니다.
 * 호출 후 반드시 commit 또는 rollback 필요
 */
public void beginTransaction() { ... }
```

---

## 🎖️ **Ultimate Goal**

The ultimate goal of these guidelines is:

> **“Code that everyone can easily understand, maintain, and confidently modify.”**

Consistently revisit and refine these guidelines to continually enhance code quality.

