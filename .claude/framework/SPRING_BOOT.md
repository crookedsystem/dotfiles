# Dependency

- Swagger :
  - implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:{version}' <- lastest version

# Test Guide

## Integration Test with TestContainers

- **Base Class**: 모든 Integration Test는 `BaseIntegrationTest`를 상속받아야 함
- **TestContainer 설정**: PostgreSQL 15-alpine 컨테이너 자동 설정
- **Database**: 테스트용 독립적인 DB 환경 (create-drop DDL)
- **Given - When - Then 패턴**: 모든 테스트는 이 패턴을 준수
- **분기 커버리지**: 모든 분기는 반드시 테스트되어야 함

### TestContainers 사용 예시

```java
@ExtendWith(MockitoExtension.class)
class ExampleControllerTest extends BaseIntegrationTest {

    @Test
    @DisplayName("사용자 로그인 성공 테스트")
    void loginSuccess() {
        // Given - 테스트 데이터 준비
        UserLoginRequest request = UserLoginRequest.builder()
            .email("test@example.com")
            .password("password123")
            .build();

        // When - 실제 동작 수행
        ResponseEntity<TokenResponse> response = restTemplate.postForEntity(
            "/open-api/auth/login", request, TokenResponse.class);

        // Then - 결과 검증
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getAccessToken()).isNotNull();
    }
}
```

### Test 작성 규칙

1. **클래스명**: `*Test`로 종료 (예: `AuthControllerTest`)
2. **메소드명**: 한글로 명확한 테스트 목적 기술
3. **@DisplayName**: 테스트 설명을 한글로 상세히 작성
4. **@Test**: 각 테스트 메소드에 필수
5. **Given-When-Then**: 주석으로 구분하여 테스트 로직을 명확히 분리
6. **AssertJ**: `assertThat()` 사용으로 가독성 높은 검증 작성
7. **예외 테스트**: 모든 예외 케이스도 반드시 테스트
8. **@Transactional**: 필요시 테스트 메소드에 추가하여 롤백 보장

