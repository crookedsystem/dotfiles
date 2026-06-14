# Playwright E2E 테스트 가이드

Playwright 기반 E2E 테스트 작성을 위한 참조 가이드다.

## 기본 원칙

### 1. 테스트 구조

모든 Playwright 테스트는 Given-When-Then 패턴을 따른다:

```typescript
import { test, expect } from '@playwright/test';

test('사용자가 올바른 자격증명으로 로그인할 수 있다', async ({ page }) => {
  // Given: 로그인 페이지에 접근하고 유효한 사용자 정보를 준비한다
  await page.goto('https://example.com/login');
  const validEmail = 'user@example.com';
  const validPassword = 'password123';

  // When: 로그인 폼에 정보를 입력하고 제출한다
  await page.fill('[data-testid="email-input"]', validEmail);
  await page.fill('[data-testid="password-input"]', validPassword);
  await page.click('[data-testid="login-button"]');

  // Then: 대시보드로 리다이렉트되고 사용자 이름이 표시된다
  await expect(page).toHaveURL(/.*dashboard/);
  await expect(page.locator('[data-testid="user-name"]')).toBeVisible();
});
```

### 2. 비즈니스 의미가 담긴 테스트 설명

각 테스트는 QA 항목이 검증하는 비즈니스 시나리오를 명확히 설명해야 한다:

```typescript
test.describe('주문 생성 플로우', () => {
  test('장바구니에 상품을 추가하고 결제를 완료할 수 있다', async ({ page }) => {
    // 정상적인 구매 플로우를 검증한다
  });

  test('재고가 부족한 상품은 장바구니에 추가할 수 없다', async ({ page }) => {
    // 재고 부족 시 사용자에게 명확한 에러 메시지를 표시한다
  });

  test('결제 정보가 유효하지 않으면 결제가 실패한다', async ({ page }) => {
    // 잘못된 카드 정보 입력 시 적절한 검증 메시지를 표시한다
  });
});
```

## Playwright 설정

### playwright.config.ts 기본 구성

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // 테스트 파일 위치
  testDir: './tests',

  // 병렬 실행 워커 수 (배치 크기)
  workers: process.env.CI ? 1 : 2,

  // 로컬 개발 시 headless 모드 설정
  use: {
    headless: true, // 로컬에서도 headless로 실행
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },

  // 프로젝트별 브라우저 설정
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  // 로컬 개발 서버 자동 시작
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },

  // 타임아웃 설정
  timeout: 30000,
  expect: {
    timeout: 5000,
  },

  // 리포트 설정
  reporter: [
    ['html'],
    ['list'],
  ],
});
```

### 배치 크기(Batch Size) 조정

테스트 병렬 실행 수를 조정하여 성능을 최적화한다:

```typescript
// playwright.config.ts
export default defineConfig({
  // 로컬: 2개 병렬 실행, CI: 순차 실행
  workers: process.env.CI ? 1 : 2,

  // 또는 명령줄에서 동적으로 지정
  // npx playwright test --workers=4
});
```

## 테스트 작성 패턴

### 1. Page Object Model (POM)

재사용 가능한 페이지 객체를 사용하여 테스트 유지보수성을 높인다:

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('[data-testid="email-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.loginButton = page.locator('[data-testid="login-button"]');
    this.errorMessage = page.locator('[data-testid="error-message"]');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }
}
```

```typescript
// tests/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

test('잘못된 비밀번호로 로그인 시 에러 메시지가 표시된다', async ({ page }) => {
  // Given: 로그인 페이지에 접근한다
  const loginPage = new LoginPage(page);
  await loginPage.goto();

  // When: 잘못된 비밀번호를 입력하고 로그인을 시도한다
  await loginPage.login('user@example.com', 'wrong-password');

  // Then: 명확한 에러 메시지가 표시된다
  const errorMessage = await loginPage.getErrorMessage();
  expect(errorMessage).toContain('비밀번호가 올바르지 않습니다');
});
```

### 2. Fixtures를 사용한 테스트 데이터 관리

```typescript
// fixtures/testData.ts
import { test as base } from '@playwright/test';

type TestFixtures = {
  validUser: { email: string; password: string };
  invalidUser: { email: string; password: string };
};

export const test = base.extend<TestFixtures>({
  validUser: async ({}, use) => {
    await use({
      email: 'valid@example.com',
      password: 'ValidPassword123!',
    });
  },

  invalidUser: async ({}, use) => {
    await use({
      email: 'invalid@example.com',
      password: 'WrongPassword',
    });
  },
});

export { expect } from '@playwright/test';
```

```typescript
// tests/auth.spec.ts
import { test, expect } from '../fixtures/testData';
import { LoginPage } from '../pages/LoginPage';

test('유효한 사용자 자격증명으로 로그인할 수 있다', async ({ page, validUser }) => {
  // Given: 로그인 페이지에 접근한다
  const loginPage = new LoginPage(page);
  await loginPage.goto();

  // When: 유효한 자격증명으로 로그인한다
  await loginPage.login(validUser.email, validUser.password);

  // Then: 대시보드로 리다이렉트된다
  await expect(page).toHaveURL(/.*dashboard/);
});
```

### 3. API Mocking을 활용한 테스트 격리

```typescript
test('서버 에러 발생 시 사용자에게 적절한 에러 메시지를 표시한다', async ({ page }) => {
  // Given: API 호출을 모킹하여 서버 에러를 시뮬레이션한다
  await page.route('**/api/login', route => {
    route.fulfill({
      status: 500,
      body: JSON.stringify({ error: '서버 내부 오류가 발생했습니다' }),
    });
  });

  const loginPage = new LoginPage(page);
  await loginPage.goto();

  // When: 로그인을 시도한다
  await loginPage.login('user@example.com', 'password123');

  // Then: 서버 에러 메시지가 표시된다
  const errorMessage = await loginPage.getErrorMessage();
  expect(errorMessage).toContain('서버 내부 오류');
});
```

### 4. 인증 상태 재사용

로그인이 필요한 테스트를 효율적으로 실행하기 위해 인증 상태를 재사용한다:

```typescript
// tests/auth.setup.ts
import { test as setup } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('인증 상태 저장', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[data-testid="email-input"]', 'user@example.com');
  await page.fill('[data-testid="password-input"]', 'password123');
  await page.click('[data-testid="login-button"]');

  await page.waitForURL('**/dashboard');
  await page.context().storageState({ path: authFile });
});
```

```typescript
// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
```

```typescript
// tests/dashboard.spec.ts (자동으로 인증된 상태로 시작)
test('대시보드에서 최근 주문 목록을 확인할 수 있다', async ({ page }) => {
  // Given: 이미 로그인된 상태에서 대시보드에 접근한다
  await page.goto('/dashboard');

  // When: 최근 주문 섹션을 확인한다
  const recentOrders = page.locator('[data-testid="recent-orders"]');

  // Then: 주문 목록이 표시된다
  await expect(recentOrders).toBeVisible();
  await expect(page.locator('[data-testid="order-item"]').first()).toBeVisible();
});
```

## 비즈니스 시나리오별 테스트 예시

### 1. 사용자 인증 플로우

```typescript
test.describe('사용자 인증 플로우', () => {
  test('유효한 자격증명으로 로그인 후 대시보드에 접근할 수 있다', async ({ page }) => {
    // Given: 로그인 페이지에 접근한다
    await page.goto('/login');

    // When: 유효한 이메일과 비밀번호를 입력하고 로그인한다
    await page.fill('[data-testid="email-input"]', 'user@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');
    await page.click('[data-testid="login-button"]');

    // Then: 대시보드로 리다이렉트되고 사용자 정보가 표시된다
    await expect(page).toHaveURL(/.*dashboard/);
    await expect(page.locator('[data-testid="user-name"]')).toContainText('사용자');
  });

  test('잘못된 비밀번호 입력 시 에러 메시지가 표시된다', async ({ page }) => {
    // Given: 로그인 페이지에 접근한다
    await page.goto('/login');

    // When: 잘못된 비밀번호를 입력한다
    await page.fill('[data-testid="email-input"]', 'user@example.com');
    await page.fill('[data-testid="password-input"]', 'wrong-password');
    await page.click('[data-testid="login-button"]');

    // Then: 비밀번호 오류 메시지가 표시된다
    await expect(page.locator('[data-testid="error-message"]'))
      .toContainText('비밀번호가 올바르지 않습니다');
  });

  test('존재하지 않는 계정으로 로그인 시도 시 에러가 표시된다', async ({ page }) => {
    // Given: 로그인 페이지에 접근한다
    await page.goto('/login');

    // When: 등록되지 않은 이메일로 로그인을 시도한다
    await page.fill('[data-testid="email-input"]', 'nonexistent@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');
    await page.click('[data-testid="login-button"]');

    // Then: 계정 미존재 에러 메시지가 표시된다
    await expect(page.locator('[data-testid="error-message"]'))
      .toContainText('계정을 찾을 수 없습니다');
  });

  test('빈 입력값으로 로그인 시도 시 검증 메시지가 표시된다', async ({ page }) => {
    // Given: 로그인 페이지에 접근한다
    await page.goto('/login');

    // When: 입력값 없이 로그인 버튼을 클릭한다
    await page.click('[data-testid="login-button"]');

    // Then: 필수 입력 항목 검증 메시지가 표시된다
    await expect(page.locator('[data-testid="email-error"]'))
      .toContainText('이메일을 입력해주세요');
    await expect(page.locator('[data-testid="password-error"]'))
      .toContainText('비밀번호를 입력해주세요');
  });
});
```

### 2. 주문 생성 플로우

```typescript
test.describe('주문 생성 플로우', () => {
  test.use({ storageState: 'playwright/.auth/user.json' });

  test('상품을 장바구니에 추가하고 결제를 완료할 수 있다', async ({ page }) => {
    // Given: 상품 목록 페이지에 접근한다
    await page.goto('/products');

    // When: 상품을 선택하고 장바구니에 추가한다
    await page.click('[data-testid="product-item"]:first-child');
    await page.click('[data-testid="add-to-cart-button"]');
    await page.click('[data-testid="cart-icon"]');

    // When: 장바구니에서 결제를 진행한다
    await page.click('[data-testid="checkout-button"]');
    await page.fill('[data-testid="card-number"]', '4111111111111111');
    await page.fill('[data-testid="card-expiry"]', '12/25');
    await page.fill('[data-testid="card-cvc"]', '123');
    await page.click('[data-testid="pay-button"]');

    // Then: 주문 완료 페이지가 표시되고 주문 번호가 생성된다
    await expect(page).toHaveURL(/.*order\/success/);
    await expect(page.locator('[data-testid="order-number"]')).toBeVisible();
  });

  test('재고가 부족한 상품은 장바구니에 추가할 수 없다', async ({ page }) => {
    // Given: 재고가 없는 상품 페이지에 접근한다
    await page.route('**/api/products/*', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: 1,
          name: '상품명',
          stock: 0,
        }),
      });
    });

    await page.goto('/products/1');

    // When: 장바구니 추가 버튼을 확인한다
    const addToCartButton = page.locator('[data-testid="add-to-cart-button"]');

    // Then: 버튼이 비활성화되어 있고 재고 부족 메시지가 표시된다
    await expect(addToCartButton).toBeDisabled();
    await expect(page.locator('[data-testid="stock-status"]'))
      .toContainText('품절');
  });
});
```

## 실행 및 디버깅

### 테스트 실행 명령어

```bash
# 전체 테스트 실행 (headless)
npx playwright test

# 특정 파일 실행
npx playwright test login.spec.ts

# 특정 브라우저에서만 실행
npx playwright test --project=chromium

# Headed 모드로 실행 (브라우저 UI 보임)
npx playwright test --headed

# 병렬 실행 워커 수 지정
npx playwright test --workers=4

# 디버그 모드 (단계별 실행)
npx playwright test --debug

# 특정 테스트만 실행 (테스트 이름으로 필터링)
npx playwright test -g "로그인"

# UI 모드 (인터랙티브)
npx playwright test --ui

# HTML 리포트 생성
npx playwright show-report
```

### VS Code 디버깅 설정

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Playwright Debug",
      "program": "${workspaceFolder}/node_modules/.bin/playwright",
      "args": [
        "test",
        "--headed",
        "--workers=1",
        "${file}"
      ],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

## 헤드리스(Headless) 모드 설정

로컬 환경에서도 headless 모드로 실행하여 CI/CD 환경과 동일한 조건에서 테스트한다:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    // 로컬 개발 환경에서도 headless 모드 사용
    headless: true,

    // 실패 시에만 스크린샷과 비디오 저장
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // 첫 재시도 시 trace 저장
    trace: 'on-first-retry',
  },
});
```

명령줄에서 동적으로 변경 가능:

```bash
# Headless 모드로 실행 (기본값)
npx playwright test

# Headed 모드로 실행 (브라우저 UI 보기)
npx playwright test --headed
```

## 배치 크기(Batch Size) 설정

동시에 실행할 테스트 워커 수를 조정하여 성능을 최적화한다:

```typescript
// playwright.config.ts
export default defineConfig({
  // 환경에 따라 워커 수 조정
  workers: process.env.CI ? 1 : 2,

  // 또는 고정값 사용
  // workers: 2, // 2개의 테스트를 병렬로 실행
});
```

명령줄에서 동적으로 지정:

```bash
# 워커 2개로 병렬 실행
npx playwright test --workers=2

# 워커 4개로 병렬 실행
npx playwright test --workers=4

# 순차 실행 (워커 1개)
npx playwright test --workers=1
```

워커 수 선택 가이드:

- CPU 코어 수보다 많은 워커는 성능 향상에 도움이 되지 않는다
- 로컬 개발: 2-4개 권장
- CI 환경: 리소스가 제한적이면 1-2개 권장
- 테스트가 리소스를 많이 사용하면 워커 수를 줄인다

## 모범 사례

### 1. 테스트 격리 (Test Isolation)

각 테스트는 독립적으로 실행되어야 한다:

```typescript
// 나쁜 예: 전역 상태를 공유
let sharedData: any;

test('첫 번째 테스트', async ({ page }) => {
  sharedData = await page.locator('[data-testid="data"]').textContent();
});

test('두 번째 테스트', async ({ page }) => {
  // sharedData에 의존하면 테스트 순서에 따라 실패할 수 있다
  expect(sharedData).toBe('expected');
});

// 좋은 예: 각 테스트가 자체 데이터를 준비
test('첫 번째 테스트', async ({ page }) => {
  const data = await page.locator('[data-testid="data"]').textContent();
  expect(data).toBe('expected');
});

test('두 번째 테스트', async ({ page }) => {
  const data = await page.locator('[data-testid="data"]').textContent();
  expect(data).toBe('expected');
});
```

### 2. 명확한 대기 조건

암시적 대기 대신 명시적 대기를 사용한다:

```typescript
// 나쁜 예: 임의의 시간 대기
await page.click('[data-testid="submit-button"]');
await page.waitForTimeout(3000); // 불안정한 테스트의 원인

// 좋은 예: 특정 조건을 대기
await page.click('[data-testid="submit-button"]');
await page.waitForURL('**/success');
await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
```

### 3. 의미 있는 셀렉터 사용

CSS 클래스나 태그보다 data-testid를 사용한다:

```typescript
// 나쁜 예: 불안정한 셀렉터
await page.click('button.btn-primary.submit');
await page.fill('input[type="email"]', 'user@example.com');

// 좋은 예: 안정적인 셀렉터
await page.click('[data-testid="submit-button"]');
await page.fill('[data-testid="email-input"]', 'user@example.com');
```

### 4. 에러 메시지 검증

에러 시나리오에서는 사용자에게 표시되는 메시지를 명확히 검증한다:

```typescript
test('결제 실패 시 명확한 에러 메시지를 표시한다', async ({ page }) => {
  // Given: 결제 페이지에 접근하고 잘못된 카드 정보를 준비한다
  await page.goto('/checkout');

  // When: 유효하지 않은 카드 번호를 입력하고 결제를 시도한다
  await page.fill('[data-testid="card-number"]', '1234567890123456');
  await page.click('[data-testid="pay-button"]');

  // Then: 사용자 친화적인 에러 메시지가 표시된다
  const errorMessage = page.locator('[data-testid="payment-error"]');
  await expect(errorMessage).toBeVisible();
  await expect(errorMessage).toContainText('카드 번호가 유효하지 않습니다');
});
```

## 금지 사항

1. **테스트에 하드코딩된 대기 시간을 사용하지 않는다**
   - `page.waitForTimeout(3000)` 대신 `page.waitForSelector()` 사용

2. **테스트 간 의존성을 만들지 않는다**
   - 각 테스트는 독립적으로 실행 가능해야 한다

3. **프로덕션 환경에서 테스트를 실행하지 않는다**
   - 테스트 전용 환경 또는 모킹을 사용한다

4. **UI 변경에 취약한 셀렉터를 사용하지 않는다**
   - CSS 클래스 대신 `data-testid` 속성을 사용한다

5. **테스트 설명을 기술적 구현으로 작성하지 않는다**
   - 나쁜 예: "POST /api/login 요청을 보낸다"
   - 좋은 예: "유효한 자격증명으로 로그인할 수 있다"
