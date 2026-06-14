# Spring Boot + JUnit Testing Guide

## Test Configuration Detection

코드를 작성하기 전에 반드시 테스트 환경 설정을 확인한다.

### 1. application.yaml 확인

테스트 환경 설정 파일 위치를 확인한다:
- `src/test/resources/application.yaml`
- `src/test/resources/application.yml`
- `src/test/resources/application-test.yaml`

### 2. Test Container vs Dedicated Test DB 판단 기준

**Test Container 사용 징후:**
```yaml
spring:
  datasource:
    driver-class-name: org.testcontainers.jdbc.ContainerDatabaseDriver
    url: jdbc:tc:postgresql:14:///testdb
```

또는 별도 TestConfig 클래스에서:
```java
@TestConfiguration
@Testcontainers
public class TestDatabaseConfig {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:14");
}
```

**전용 Test DB 사용 징후:**
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5433/test_db
    username: test_user
    password: test_password
```

### 3. Integration Test 작성 가이드

**Test Container를 사용하는 경우:**
```java
@SpringBootTest
@Testcontainers
@AutoConfigureMockMvc
class OrderServiceIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:14")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void setProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private OrderService orderService;

    @Autowired
    private OrderRepository orderRepository;

    @Test
    void createOrder_shouldPersistToDatabase() {
        // given
        CreateOrderRequest request = new CreateOrderRequest("ITEM-001", 5);

        // when
        OrderResponse response = orderService.createOrder(request);

        // then
        assertThat(response.orderId()).isNotNull();

        Order savedOrder = orderRepository.findById(response.orderId()).orElseThrow();
        assertThat(savedOrder.getItemCode()).isEqualTo("ITEM-001");
        assertThat(savedOrder.getQuantity()).isEqualTo(5);
        assertThat(savedOrder.getStatus()).isEqualTo(OrderStatus.PENDING);
    }
}
```

**전용 Test DB를 사용하는 경우:**
```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class OrderServiceIntegrationTest {

    @Autowired
    private OrderService orderService;

    @Autowired
    private OrderRepository orderRepository;

    @BeforeEach
    void setUp() {
        orderRepository.deleteAll();
    }

    @Test
    void createOrder_shouldPersistToDatabase() {
        // given
        CreateOrderRequest request = new CreateOrderRequest("ITEM-001", 5);

        // when
        OrderResponse response = orderService.createOrder(request);

        // then
        assertThat(response.orderId()).isNotNull();

        Order savedOrder = orderRepository.findById(response.orderId()).orElseThrow();
        assertThat(savedOrder.getItemCode()).isEqualTo("ITEM-001");
        assertThat(savedOrder.getQuantity()).isEqualTo(5);
        assertThat(savedOrder.getStatus()).isEqualTo(OrderStatus.PENDING);
    }
}
```

## Given-When-Then 패턴

모든 테스트는 Given-When-Then 구조를 따른다.

### Unit Test 예시

```java
@ExtendWith(MockitoExtension.class)
class OrderValidatorTest {

    @InjectMocks
    private OrderValidator orderValidator;

    @Mock
    private InventoryClient inventoryClient;

    @Test
    void validateOrder_withSufficientStock_shouldPass() {
        // given
        Order order = Order.builder()
            .itemCode("ITEM-001")
            .quantity(5)
            .build();

        when(inventoryClient.getAvailableStock("ITEM-001"))
            .thenReturn(10);

        // when
        ValidationResult result = orderValidator.validateOrder(order);

        // then
        assertThat(result.isValid()).isTrue();
        assertThat(result.getErrors()).isEmpty();
    }

    @Test
    void validateOrder_withInsufficientStock_shouldFail() {
        // given
        Order order = Order.builder()
            .itemCode("ITEM-001")
            .quantity(15)
            .build();

        when(inventoryClient.getAvailableStock("ITEM-001"))
            .thenReturn(10);

        // when
        ValidationResult result = orderValidator.validateOrder(order);

        // then
        assertThat(result.isValid()).isFalse();
        assertThat(result.getErrors())
            .contains("재고 부족: 요청 15개, 가용 10개");
    }
}
```

### Controller Test 예시

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Test
    void createOrder_withValidRequest_shouldReturnCreated() throws Exception {
        // given
        CreateOrderRequest request = new CreateOrderRequest("ITEM-001", 5);
        OrderResponse expectedResponse = new OrderResponse(
            1L, "ITEM-001", 5, OrderStatus.PENDING
        );

        when(orderService.createOrder(any(CreateOrderRequest.class)))
            .thenReturn(expectedResponse);

        // when & then
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "itemCode": "ITEM-001",
                        "quantity": 5
                    }
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.orderId").value(1))
            .andExpect(jsonPath("$.itemCode").value("ITEM-001"))
            .andExpect(jsonPath("$.quantity").value(5))
            .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void createOrder_withInvalidQuantity_shouldReturnBadRequest() throws Exception {
        // given & when & then
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "itemCode": "ITEM-001",
                        "quantity": -1
                    }
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errors[0].field").value("quantity"))
            .andExpect(jsonPath("$.errors[0].message").value("수량은 1 이상이어야 합니다"));
    }
}
```

## 테스트 범위 우선순위

### 반드시 테스트해야 할 코드 (High Priority)

1. **비즈니스 로직 핵심 규칙**
   - 계산 로직 (금액, 할인, 세금)
   - 상태 전환 로직
   - 권한 검증 로직

2. **외부 시스템 연동**
   - Payment Gateway 호출
   - 외부 API 클라이언트
   - 메시지 큐 발행/구독

3. **데이터 일관성이 중요한 로직**
   - 트랜잭션 경계
   - 동시성 제어
   - 데이터 검증 로직

4. **보안 관련 로직**
   - 인증/인가
   - 입력값 검증
   - SQL Injection 방지

### 선택적 테스트 (Medium Priority)

1. **단순 CRUD**
   - Repository 계층의 기본 조회/저장
   - 단순 DTO 변환

2. **설정 클래스**
   - Configuration 클래스
   - Bean 정의

### 테스트 불필요 (Low Priority)

1. **Getter/Setter**
2. **상수 정의**
3. **단순 위임 메서드**
