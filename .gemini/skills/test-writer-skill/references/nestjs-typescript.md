# NestJS + TypeScript Testing Guide

## Test Configuration Detection

코드를 작성하기 전에 반드시 테스트 환경 설정을 확인한다.

### 1. package.json 확인

테스트 프레임워크와 설정을 확인한다:
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:e2e": "jest --config ./test/jest-e2e.json"
  },
  "devDependencies": {
    "@nestjs/testing": "^10.0.0",
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "supertest": "^6.3.0"
  }
}
```

### 2. Database Configuration 확인

**TypeORM + Test Database:**
```typescript
// test/database.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const testDatabaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  host: process.env.TEST_DB_HOST || 'localhost',
  port: parseInt(process.env.TEST_DB_PORT) || 5433,
  username: process.env.TEST_DB_USER || 'test',
  password: process.env.TEST_DB_PASSWORD || 'test',
  database: process.env.TEST_DB_NAME || 'test_db',
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: true,
};
```

**Docker Compose for Test DB:**
```yaml
# docker-compose.test.yml
services:
  test-db:
    image: postgres:14
    ports:
      - "5433:5432"
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: test_db
```

## Given-When-Then 패턴

모든 테스트는 Given-When-Then 구조를 따른다.

### Unit Test 예시 (Service)

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { OrderService } from './order.service';
import { OrderRepository } from './order.repository';
import { InventoryClient } from '../inventory/inventory.client';
import { InsufficientStockException } from '../exceptions/insufficient-stock.exception';

describe('OrderService', () => {
  let service: OrderService;
  let orderRepository: jest.Mocked<OrderRepository>;
  let inventoryClient: jest.Mocked<InventoryClient>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderService,
        {
          provide: OrderRepository,
          useValue: {
            save: jest.fn(),
            findById: jest.fn(),
            findAll: jest.fn(),
          },
        },
        {
          provide: InventoryClient,
          useValue: {
            getAvailableStock: jest.fn(),
            reserveStock: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<OrderService>(OrderService);
    orderRepository = module.get(OrderRepository);
    inventoryClient = module.get(InventoryClient);
  });

  describe('createOrder', () => {
    it('재고가 충분할 때 주문을 생성한다', async () => {
      // given
      const createOrderDto = {
        itemCode: 'ITEM-001',
        quantity: 5,
      };

      inventoryClient.getAvailableStock.mockResolvedValue(10);
      orderRepository.save.mockResolvedValue({
        id: 1,
        itemCode: 'ITEM-001',
        quantity: 5,
        status: 'PENDING',
      });

      // when
      const result = await service.createOrder(createOrderDto);

      // then
      expect(result.id).toBe(1);
      expect(result.itemCode).toBe('ITEM-001');
      expect(result.quantity).toBe(5);
      expect(result.status).toBe('PENDING');
      expect(inventoryClient.reserveStock).toHaveBeenCalledWith('ITEM-001', 5);
    });

    it('재고가 부족할 때 예외를 발생시킨다', async () => {
      // given
      const createOrderDto = {
        itemCode: 'ITEM-001',
        quantity: 15,
      };

      inventoryClient.getAvailableStock.mockResolvedValue(10);

      // when & then
      await expect(service.createOrder(createOrderDto)).rejects.toThrow(
        InsufficientStockException,
      );
      expect(orderRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('cancelOrder', () => {
    it('주문이 PENDING 상태일 때 취소한다', async () => {
      // given
      const orderId = 1;
      const existingOrder = {
        id: 1,
        itemCode: 'ITEM-001',
        quantity: 5,
        status: 'PENDING',
      };

      orderRepository.findById.mockResolvedValue(existingOrder);
      orderRepository.save.mockResolvedValue({
        ...existingOrder,
        status: 'CANCELLED',
      });

      // when
      const result = await service.cancelOrder(orderId);

      // then
      expect(result.status).toBe('CANCELLED');
      expect(inventoryClient.releaseStock).toHaveBeenCalledWith('ITEM-001', 5);
    });
  });
});
```

### Controller Test 예시

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { OrderController } from './order.controller';
import { OrderService } from './order.service';

describe('OrderController', () => {
  let app: INestApplication;
  let orderService: jest.Mocked<OrderService>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [OrderController],
      providers: [
        {
          provide: OrderService,
          useValue: {
            createOrder: jest.fn(),
            getOrder: jest.fn(),
            cancelOrder: jest.fn(),
          },
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    orderService = moduleFixture.get(OrderService);
  });

  afterEach(async () => {
    await app.close();
  });

  describe('POST /orders', () => {
    it('유효한 요청으로 주문을 생성한다', async () => {
      // given
      const createOrderDto = {
        itemCode: 'ITEM-001',
        quantity: 5,
      };

      const expectedResponse = {
        id: 1,
        itemCode: 'ITEM-001',
        quantity: 5,
        status: 'PENDING',
      };

      orderService.createOrder.mockResolvedValue(expectedResponse);

      // when & then
      return request(app.getHttpServer())
        .post('/orders')
        .send(createOrderDto)
        .expect(201)
        .expect((res) => {
          expect(res.body.id).toBe(1);
          expect(res.body.itemCode).toBe('ITEM-001');
          expect(res.body.quantity).toBe(5);
          expect(res.body.status).toBe('PENDING');
        });
    });

    it('수량이 음수일 때 400 에러를 반환한다', async () => {
      // given
      const invalidDto = {
        itemCode: 'ITEM-001',
        quantity: -1,
      };

      // when & then
      return request(app.getHttpServer())
        .post('/orders')
        .send(invalidDto)
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain('quantity must not be less than 1');
        });
    });
  });

  describe('GET /orders/:id', () => {
    it('주문 ID로 주문을 조회한다', async () => {
      // given
      const orderId = 1;
      const expectedOrder = {
        id: 1,
        itemCode: 'ITEM-001',
        quantity: 5,
        status: 'PENDING',
      };

      orderService.getOrder.mockResolvedValue(expectedOrder);

      // when & then
      return request(app.getHttpServer())
        .get(`/orders/${orderId}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.id).toBe(1);
          expect(res.body.itemCode).toBe('ITEM-001');
        });
    });
  });
});
```

### E2E Test 예시

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { testDatabaseConfig } from './database.config';

describe('Order E2E', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        AppModule,
        TypeOrmModule.forRoot(testDatabaseConfig),
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    // 각 테스트 전에 데이터 정리
    const orderRepository = app.get('OrderRepository');
    await orderRepository.clear();
  });

  describe('주문 생성 플로우', () => {
    it('주문을 생성하고 조회할 수 있다', async () => {
      // given
      const createOrderDto = {
        itemCode: 'ITEM-001',
        quantity: 5,
      };

      // when: 주문 생성
      const createResponse = await request(app.getHttpServer())
        .post('/orders')
        .send(createOrderDto)
        .expect(201);

      const orderId = createResponse.body.id;

      // then: 생성된 주문 조회
      return request(app.getHttpServer())
        .get(`/orders/${orderId}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.id).toBe(orderId);
          expect(res.body.itemCode).toBe('ITEM-001');
          expect(res.body.quantity).toBe(5);
          expect(res.body.status).toBe('PENDING');
        });
    });

    it('주문을 생성하고 취소할 수 있다', async () => {
      // given: 주문 생성
      const createResponse = await request(app.getHttpServer())
        .post('/orders')
        .send({ itemCode: 'ITEM-001', quantity: 5 })
        .expect(201);

      const orderId = createResponse.body.id;

      // when: 주문 취소
      await request(app.getHttpServer())
        .post(`/orders/${orderId}/cancel`)
        .expect(200);

      // then: 취소된 상태 확인
      return request(app.getHttpServer())
        .get(`/orders/${orderId}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.status).toBe('CANCELLED');
        });
    });
  });
});
```

## 테스트 범위 우선순위

### 반드시 테스트해야 할 코드 (High Priority)

1. **비즈니스 로직 핵심 규칙**
   - 계산 로직 (금액, 할인, 세금)
   - 상태 전환 로직
   - 권한 검증 로직

2. **외부 시스템 연동**
   - HTTP Client (axios, fetch)
   - 외부 API 호출
   - 메시지 큐 발행/구독

3. **데이터 일관성이 중요한 로직**
   - 트랜잭션 처리
   - 동시성 제어
   - 데이터 검증

4. **보안 관련 로직**
   - Guards (인증/인가)
   - Validators
   - Pipes (입력값 변환/검증)

### 선택적 테스트 (Medium Priority)

1. **단순 CRUD**
   - Repository 계층의 기본 조회/저장
   - 단순 DTO 변환

2. **설정 클래스**
   - Module 설정
   - Provider 등록

### 테스트 불필요 (Low Priority)

1. **Getter/Setter**
2. **상수 정의**
3. **단순 위임 메서드**

## Mock 사용 가이드

### External API Mock

```typescript
// given
jest.spyOn(httpService, 'get').mockReturnValue(
  of({
    data: { stock: 10 },
    status: 200,
    statusText: 'OK',
    headers: {},
    config: {},
  }),
);
```

### Repository Mock

```typescript
// given
mockRepository.findOne.mockResolvedValue({
  id: 1,
  itemCode: 'ITEM-001',
  quantity: 5,
});
```

### Event Emitter Mock

```typescript
// then
expect(eventEmitter.emit).toHaveBeenCalledWith(
  'order.created',
  expect.objectContaining({
    orderId: 1,
    itemCode: 'ITEM-001',
  }),
);
```
