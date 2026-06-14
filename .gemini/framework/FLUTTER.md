# FLUTTER 개발 가이드라인

## 프로젝트 구조 (Feature-First)

```
lib/src/
  features/
    {feature_name}/
      presentation/
        screens/        # 화면 위젯
        widgets/        # feature별 UI 컴포넌트
        controllers/    # AsyncNotifier 컨트롤러
      application/      # (선택) 다중 repository 조정 서비스
      domain/
        models/         # 불변 엔티티
      data/
        repositories/   # 추상 인터페이스 + 구현체
        dtos/           # DTO 클래스
  common/               # 공통 코드 루트
    presentation/
      widgets/          # 재사용 디자인 컴포넌트 (버튼, 카드 등)
    config/             # 앱 설정, 환경 설정
    constants/          # 디자인 토큰
      app_theme.dart    # ThemeData
      app_colors.dart   # 색상 팔레트
      app_sizes.dart    # 간격, 크기
    routing/
      app_router.dart   # go_router 설정
    utils/              # 유틸리티 함수
```

## Feature 정의

- Feature는 UI 화면이 아닌 **도메인 개념**
- 예: auth(인증), products(상품), cart(장바구니), orders(주문)
- 사용자가 수행하는 기능 단위로 분리

## 레이어별 책임

### Presentation Layer

**책임**: Widget State 관리, UI 렌더링, 사용자 입력 처리

**구현**:
- Widget: `ConsumerWidget` 또는 `ConsumerStatefulWidget`
- Controller: `AsyncNotifier<T>` 상속, `AsyncValue<T>` 상태 관리
- 비즈니스 로직은 Controller/Service에 위임

**금지**:
- Widget에서 직접 Repository 접근
- Widget 내부에 비즈니스 로직 작성

### Application Layer (선택)

**생성 조건**: 2개 이상 Repository 조정 필요 OR 여러 Widget에서 공유

**책임**: 
- 다중 데이터 소스 조정
- 복잡한 비즈니스 로직 캡슐화

**구현**:
```dart
class CartService {
  CartService(this.ref);
  final Ref ref;
  
  // 여러 repository 사용
}
```

**금지**: Widget State 관리, DTO 변환

### Domain Layer

**책임**: 핵심 비즈니스 모델 정의

**구현**:
- 불변 클래스 (`@immutable`, `freezed` 권장)
- 외부 의존성 없음 (패키지 import 최소화)

**예시**:
```dart
@freezed
class Product with _$Product {
  factory Product({
    required String id,
    required String name,
    required double price,
  }) = _Product;
}
```

### Data Layer

**책임**: 
- 데이터 소스 추상화
- DTO → Entity 변환
- API 통신, 로컬 저장소 접근

**구현**:
```dart
// 추상 인터페이스
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

// 구현체
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this.client);
  final http.Client client;
  
  @override
  Future<List<Product>> fetchProducts() async {
    final response = await client.get(...);
    final dto = ProductDTO.fromJson(json.decode(response.body));
    return dto.toEntity(); // DTO → Entity
  }
}
```

**추상화 시점**:
- 테스트 필요시
- 2개 이상 구현체 예상시 (API/Mock/Local)
- 단일 구현만 있으면 구체 클래스 직접 사용 (YAGNI)

## Riverpod 패턴

### Provider 정의

```dart
@riverpod
class ProductsController extends _$ProductsController {
  @override
  FutureOr<List<Product>> build() async {
    // 초기 상태 로드
    return ref.watch(productRepositoryProvider).fetchProducts();
  }
  
  Future<void> addProduct(Product product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).add(product);
      return ref.read(productRepositoryProvider).fetchProducts();
    });
  }
}
```

### Widget에서 사용

```dart
class ProductsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsControllerProvider);
    
    // ref.listen으로 사이드 이펙트 처리
    ref.listen(productsControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, stack) => showErrorSnackbar(context, err),
      );
    });
    
    return productsAsync.when(
      data: (products) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### Ref 사용법

- `ref.watch(provider)`: 상태 변경 시 리빌드
- `ref.read(provider.notifier)`: 메서드 호출 (리빌드 없음)
- `ref.listen(provider, callback)`: 사이드 이펙트 (스낵바, 네비게이션)

## 상태 관리 패턴

### AsyncValue 상태 전환

1. **Loading**: `state = const AsyncValue.loading()`
2. **Guard**: `state = await AsyncValue.guard(() => ...)`
   - 성공 시 AsyncValue.data()
   - 실패 시 AsyncValue.error() 자동 생성

### 에러 처리

- `AsyncValue.guard()` 사용 → try-catch 불필요
- UI 알림: `ref.listen`으로 error 상태 감지

## 파일 네이밍

- `snake_case` 사용
- 명확한 접미사:
  - `_controller.dart`: AsyncNotifier
  - `_service.dart`: Application 서비스
  - `_repository.dart`: Repository
  - `_dto.dart`: DTO
  - `_screen.dart`: 전체 화면
  - `_widget.dart`: 재사용 위젯

## 금지 사항

1. **Widget에서 직접 Repository 접근**
   - Controller를 통해 간접 접근

2. **Controller에 앱 상태 저장**
   - Controller는 Widget State만 관리
   - 앱 전역 상태는 별도 Provider

3. **불필요한 추상화**
   - 구현체 1개뿐이면 추상 인터페이스 생략
   - 테스트/다중 구현 필요시만 추상화

4. **비즈니스 로직을 Widget에 작성**
   - Controller 또는 Service로 분리

5. **Domain 모델에 외부 의존성**
   - 순수 Dart 클래스, 외부 패키지 import 최소화

6. **Feature 경계 무시**
   - 다른 Feature의 내부 파일 직접 import 금지
   - Domain 모델, 공통 위젯만 공유

## 테스트 구조

```
test/
  src/
    features/
      {feature_name}/
        presentation/
        domain/
        data/
```

- `lib/` 구조와 동일하게 미러링
- Repository는 Mock으로 대체하여 Controller 테스트

## Common 폴더 구조

### common/presentation/widgets/

재사용 가능한 UI 컴포넌트:
- `primary_button.dart`
- `app_text_field.dart`
- `loading_indicator.dart`
- `error_message_widget.dart`
- `animated_bottom_nav_bar.dart`
- `buttons/animated_button.dart`
- `buttons/animated_icon_button.dart`

### common/config/

앱 전역 설정:
- 환경 설정 (development, staging, production)
- API 엔드포인트 설정
- Feature 플래그
- 앱 초기화 설정

### common/constants/

디자인 토큰 및 상수:
- `app_colors.dart`: Color 상수
- `app_theme.dart`: ThemeData
- `app_sizes.dart`: 간격, 패딩, 아이콘 크기

### common/routing/

라우팅 설정:
- `app_router.dart`: go_router 설정
- 라우트 정의 및 네비게이션 로직

### common/utils/

유틸리티 함수:
- 날짜/시간 포맷팅
- 문자열 처리
- 검증 함수
- 헬퍼 함수

### Feature별 위젯

Feature 특화 UI는 `features/{feature}/presentation/widgets/`에 위치

## 국제화 (i18n)

- UI 문자열은 l10n 파일에 정의, 하드코딩 금지
- 날짜/숫자/통화는 로케일 기반 포맷 사용

## 디자인 시스템

- `lib/src/common/constants/` 디렉토리의 디자인 토큰 사용
- Color, TextStyle, EdgeInsets 등 직접 하드코딩 금지

## 핵심 원칙

1. **YAGNI**: 현재 필요한 것만 구현
2. **레이어 분리**: 각 레이어는 명확한 단일 책임
3. **의존성 방향**: Data ← Domain ← Application ← Presentation
4. **Feature 독립성**: Feature 간 직접 참조 최소화
5. **공통 코드 외부화**: 재사용 컴포넌트는 common/presentation/widgets/
