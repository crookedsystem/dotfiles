## 문서화 규칙

- 공통 코드(ErrorResponse DTO, HTTPClient Config, AuthStatus 등)은 이후 참조할 수 있도록 코드 위치, 사용법, 동작, 반환값, 파라미터 등을 README.md에 명시
- CustomStatus 등 에러 코드는 중복되지 않게 README.md에 추가될 때마다 기록

## 네이밍 규칙

### 원칙
- 이름만 보고 비즈니스 역할과 동작을 파악할 수 있어야 함
- 축약어보다 명확한 전체 단어 사용 (단, 널리 통용되는 약어는 허용: `id`, `url`, `dto`)
- 일관된 동사 사용: 조회(`get/fetch`), 생성(`create`), 수정(`update`), 삭제(`delete`), 검증(`validate`)

### 좋은 예시 vs 나쁜 예시

| 나쁜 예시 | 좋은 예시 | 이유 |
|----------|----------|------|
| `userData` | `userProfile` / `userCredentials` | 구체적 용도 명시 |
| `getInfo()` | `getOrderStatus()` | 어떤 정보인지 명확 |
| `handleData()` | `processPaymentRefund()` | 비즈니스 동작 표현 |
| `temp`, `val`, `result` | `filteredOrders`, `totalPrice` | 의미 있는 이름 |
| `flag`, `status` | `isVerified`, `paymentStatus` | 상태의 대상 명시 |
| `list`, `items` | `pendingOrders`, `cartItems` | 컬렉션의 내용물 표현 |
| `Manager`, `Helper` | `OrderValidator`, `PriceCalculator` | 단일 책임 명확화 |

### 금지 접미사/접두사 (맥락별 구분)

**항상 금지** (구체적 도메인과 결합 필수):
- `Info`, `Data`, `Object`, `Item` → 예: ~~`UserInfo`~~ → `UserProfile`
- `Manager`, `Handler`, `Helper` → 구체적 책임 명시 필요
- `Util`, `Common`, `General` → 실제 기능으로 대체
- `tmp`, `temp`, `val`, `res` → 의미 있는 이름으로 대체

**기술적 상속 구조에서만 허용**:
- `Base`, `Abstract` → `BaseEntity`, `AbstractRepository` ✅
  - 단, 비즈니스 서비스에서는 금지: ~~`BaseService`~~ → `OrderService`
- `Entity` → JPA/ORM 엔티티 클래스에서만 허용

**예외 판단 기준**:
- 프레임워크/라이브러리 컨벤션을 따르는 경우 → 허용
- 상속 계층의 루트 클래스를 명시하는 경우 → 허용
- 단순히 "뭔가 기본적인 것"을 표현하려는 경우 → 금지

### Boolean 네이밍
- `is`, `has`, `can`, `should` 접두사 사용
- 예: `isActive`, `hasPermission`, `canEdit`, `shouldNotify`

## 주석 규칙

- 주석/답변은 한국어
- 주석 작성 시 번호나 단계를 매기지 말고, 자연스러운 줄글(서술형)로 기능을 설명
- 사용 언어의 표준 주석 스타일(예: JSDoc, JavaDoc)을 준수
- 매개변수(@param)와 반환값(@returns)의 비즈니스적 역할을 명확히 명시

### KISS (Keep It Simple, Stupid)

단순하고 명확한 코드를 작성하라. 불필요한 복잡성은 기술 부채다.

준수 사항:

- 함수는 한 가지 일만 하도록 작성 (Single Responsibility)
- 함수 길이는 가급적 50줄 이하로 유지
- 중첩 깊이는 3단계를 넘지 않도록
- 복잡한 로직은 명확한 이름의 작은 함수로 분리
- 자기 설명적 코드 작성 (변수/함수명으로 의도를 표현)
- 과도한 디자인 패턴이나 추상화 지양

금지 사항:

- 한 번에 이해하기 어려운 복잡한 원라이너
- 불필요한 레이어나 간접 참조
- "clever" 코드보다는 "clear" 코드

### YAGNI (You Aren't Gonna Need It)

현재 필요한 것만 구현하라. 미래를 위한 코드는 현재의 부담이다.

준수 사항:

- 명시적으로 요구된 기능만 구현
- 실제로 3번 반복될 때 추상화 고려 (Rule of Three)
- 작게 시작하고 필요할 때 확장
- 확실한 요구사항이 있을 때만 확장 포인트 추가

금지 사항:

- "나중에 필요할 것 같아서" 추가하는 파라미터/옵션
- 현재 사용하지 않는 인터페이스나 추상 클래스
- "미래 대비" 설정이나 플래그
- 사용되지 않는 제네릭 프레임워크
