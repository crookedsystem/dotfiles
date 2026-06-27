# Coolify 서버 세팅 가이드

이 문서는 `dotfiles/configs/coolify`에 보관되는 Coolify 설정/운영 템플릿입니다.

Coolify를 Linux 서버에 설치하고, 로컬 포트 또는 별도 DNS/프록시를 통해 접속할 수 있게 만드는 최소 운영 가이드입니다.

이 문서는 특정 DNS 이름에 의존하지 않습니다. 실제 DNS, Tailscale MagicDNS, Cloudflare, Nginx, Caddy, Load Balancer 등은 배포할 서버 환경에 맞게 연결하세요.

## 구성 개요

기본 구조는 아래와 같습니다.

```text
사용자 브라우저
  -> 사용자가 정한 DNS/프록시
  -> 서버의 Coolify 포트, 기본 8000
  -> Coolify 컨테이너 내부 8080
```

서버의 주요 파일은 아래 하나의 환경 파일과 하나의 Compose 파일을 기준으로 둡니다.

```text
/data/coolify/source/.env                  # 시크릿 포함, 커밋 금지
/data/coolify/source/docker-compose.yml
```

이 디렉터리에는 시크릿이 없는 파일만 보관합니다.

```text
config/docker-compose.yml
.env.example
scripts/configure-tailscale-serve.sh
scripts/verify-coolify.sh
```

## 1. Coolify 설치

가장 권장하는 방식은 Coolify 공식 설치 스크립트를 사용하는 것입니다.

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
```

설치가 끝나면 보통 Coolify는 서버의 `8000` 포트에서 열립니다.

```bash
curl -fsS http://127.0.0.1:8000/api/health
```

정상이라면 아래처럼 출력됩니다.

```text
OK
```

## 2. 이 디렉터리의 파일 적용 방법

이 디렉터리는 설치 결과를 문서화하고 재사용하기 위한 안전한 설정 템플릿입니다. 실제 서버의 `.env`는 시크릿을 포함하므로 덮어쓰기 전에 반드시 백업하세요.

```bash
git clone https://github.com/crookedsystem/dotfiles.git
cd dotfiles/configs/coolify
```

Compose 파일을 서버의 Coolify 경로에 반영합니다.

```bash
sudo cp config/docker-compose.yml /data/coolify/source/docker-compose.yml
```

`.env`가 없는 새 환경에서 수동으로 시작해야 한다면 `.env.example`을 복사한 뒤, 아래 **3. `.env` 설정값 설명** 표를 보면서 각 값을 직접 채우세요.

```bash
sudo cp .env.example /data/coolify/source/.env
sudo nano /data/coolify/source/.env
```

주의: `APP_KEY`, `DB_PASSWORD`, `REDIS_PASSWORD`, `PUSHER_APP_SECRET`, `ROOT_USER_PASSWORD` 같은 값은 반드시 새로 생성한 안전한 값으로 바꿔야 합니다. 실서비스에서는 공식 설치 스크립트가 생성한 `.env`를 유지하는 편이 안전합니다.

## 3. `.env` 설정값 설명

`.env.example`에는 실제 값과 설명을 섞지 않고, 복사해서 채울 수 있는 키 목록만 둡니다. 각 값의 의미와 설정 방법은 이 README를 기준으로 확인하세요.

### 빠른 생성 명령

```bash
# 짧은 랜덤 ID/키
openssl rand -hex 16

# 긴 시크릿/비밀번호
openssl rand -hex 32

# Coolify/Laravel APP_KEY 형식
printf 'base64:%s\n' "$(openssl rand -base64 32)"
```

### 필수 앱 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `APP_ID` | Coolify 인스턴스를 식별하는 앱 ID입니다. | 처음 배포할 때 `openssl rand -hex 16`으로 만들고 이후에는 유지합니다. |
| `APP_NAME` | Coolify 화면과 내부 서비스에서 보이는 앱 이름입니다. | 특별히 이름을 바꾸려는 게 아니면 `Coolify` 그대로 둡니다. |
| `APP_KEY` | 세션/토큰 등 암호화에 쓰이는 Coolify/Laravel 앱 키입니다. | `printf 'base64:%s\n' "$(openssl rand -base64 32)"`로 한 번 만들고 유지합니다. 운영 중 임의로 바꾸면 기존 세션/토큰이 무효화될 수 있습니다. |
| `APP_ENV` | Coolify 실행 환경입니다. | 서버 운영 환경에서는 `production`을 사용합니다. |
| `APP_PORT` | 호스트에서 Coolify로 접속할 포트입니다. 컨테이너 내부는 8080을 사용합니다. | 기본값은 `8000`입니다. 서버에서 이미 8000 포트를 쓰고 있을 때만 다른 값으로 바꿉니다. |

### 데이터베이스/Redis 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `DB_DATABASE` | 포함된 PostgreSQL 서비스가 사용할 데이터베이스 이름입니다. | 특별한 이유가 없으면 `coolify` 그대로 둡니다. |
| `DB_USERNAME` | Coolify 앱과 PostgreSQL 서비스가 함께 사용할 DB 사용자명입니다. | 특별한 이유가 없으면 `coolify` 그대로 둡니다. |
| `DB_PASSWORD` | PostgreSQL 비밀번호입니다. | `openssl rand -hex 32`로 새 값을 만들고 다른 서비스와 재사용하지 않습니다. |
| `REDIS_PASSWORD` | Redis 비밀번호입니다. | `openssl rand -hex 32`로 새 값을 만들고 다른 서비스와 재사용하지 않습니다. |

### 실시간 통신/Soketi 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `PUSHER_APP_ID` | Coolify 내부 실시간 통신용 Soketi 앱 ID입니다. | `openssl rand -hex 16`으로 만들고 유지합니다. |
| `PUSHER_APP_KEY` | Coolify 내부 실시간 통신용 Soketi 앱 키입니다. | `openssl rand -hex 16`으로 만들고 유지합니다. |
| `PUSHER_APP_SECRET` | Coolify 내부 실시간 통신용 Soketi 시크릿입니다. | `openssl rand -hex 32`로 긴 랜덤 값을 만듭니다. |
| `SOKETI_PORT` | 호스트에서 Soketi로 연결할 포트입니다. | 기본값은 `6001`입니다. 포트 충돌이 있을 때만 바꿉니다. |
| `SOKETI_DEBUG` | Soketi 디버그 로그를 켤지 정합니다. | 평소에는 `false`로 둡니다. 실시간 통신 문제를 볼 때만 임시로 `true`를 사용합니다. |
| `SOKETI_HOST` | Soketi 컨테이너 내부 바인드 주소입니다. | Docker 환경에서는 `0.0.0.0` 그대로 둡니다. |

### 초기 관리자 계정 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `ROOT_USERNAME` | 첫 관리자 계정을 미리 만들 때 사용할 사용자명입니다. | 보통 비워두고 첫 접속 화면에서 관리자 계정을 만듭니다. 미리 생성할 때만 입력합니다. |
| `ROOT_USER_EMAIL` | 첫 관리자 계정을 미리 만들 때 사용할 이메일입니다. | `ROOT_USERNAME`을 쓰는 경우에만 실제 이메일을 입력합니다. 아니면 비워둡니다. |
| `ROOT_USER_PASSWORD` | 첫 관리자 계정을 미리 만들 때 사용할 비밀번호입니다. | 가능하면 비워두고 UI에서 생성합니다. 미리 넣어야 한다면 비밀번호 관리자나 `openssl rand -hex 32`로 만든 고유한 값을 사용합니다. |

### 이미지/런타임 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `REGISTRY_URL` | Coolify 컨테이너 이미지를 받을 레지스트리 주소입니다. | 공식 이미지는 `ghcr.io`를 사용합니다. 사내 미러/프라이빗 레지스트리를 쓸 때만 바꿉니다. |
| `LATEST_IMAGE` | 사용할 Coolify 이미지 태그입니다. | 일반 설치는 `latest`를 사용합니다. 업그레이드/롤백을 통제해야 하면 특정 태그로 고정합니다. |
| `PHP_MEMORY_LIMIT` | Coolify 컨테이너의 PHP 메모리 제한입니다. | 기본값은 `256M`입니다. 로그에서 메모리 부족이 확인될 때만 늘립니다. |
| `PHP_FPM_PM_CONTROL` | PHP-FPM 프로세스 매니저 방식입니다. | 기본값은 `dynamic`입니다. 워크로드 특성을 알고 있을 때만 `static`/`ondemand` 등으로 바꿉니다. |
| `PHP_FPM_PM_START_SERVERS` | `dynamic` 방식에서 시작할 PHP-FPM 워커 수입니다. | 기본값은 `1`입니다. 작은 서버에서는 그대로 둡니다. |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | 유지할 최소 유휴 PHP-FPM 워커 수입니다. | 기본값은 `1`입니다. |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | 유지할 최대 유휴 PHP-FPM 워커 수입니다. | 기본값은 `10`입니다. 서버 자원이 작으면 낮출 수 있습니다. |

### Docker 네트워크 설정

| 변수 | 무엇인지 | 어떻게 설정하나 |
| --- | --- | --- |
| `DOCKER_ADDRESS_POOL_BASE` | Coolify가 관리하는 Docker 네트워크가 사용할 주소 대역입니다. | 기본값은 `10.0.0.0/8`입니다. 서버의 LAN/VPN/Tailscale 경로와 겹치면 충돌하지 않는 사설 대역으로 바꿉니다. |
| `DOCKER_ADDRESS_POOL_SIZE` | `DOCKER_ADDRESS_POOL_BASE`에서 잘라낼 각 Docker 네트워크의 prefix 크기입니다. | 기본값 `24`는 각 네트워크를 `/24`로 만든다는 뜻입니다. 특별한 네트워크 설계가 없으면 그대로 둡니다. |

## 4. 실행 방법

Coolify를 실행합니다.

```bash
cd /data/coolify/source
sudo docker compose --env-file .env -f docker-compose.yml up -d
```

상태 확인:

```bash
sudo docker ps --filter 'name=coolify' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
curl -fsS http://127.0.0.1:8000/api/health
```

브라우저 접속 주소는 서버에서 연결한 DNS/프록시 설정에 따라 달라집니다.

예시:

```text
http://<서버-IP>:8000
http://<사용자-도메인>
https://<사용자-도메인>
```

처음 접속하면 관리자 계정 생성 화면으로 이동합니다. 이미 계정을 만들었다면 로그인 화면으로 이동합니다.

## 5. DNS 또는 프록시 연결

DNS는 이 레포에서 고정하지 않습니다. 서버 환경에 맞게 아래 중 하나를 선택하세요.

### A. 포트 직접 접속

방화벽에서 `8000` 포트를 열고 아래 형태로 접속합니다.

```text
http://<서버-IP>:8000
```

### B. 리버스 프록시 사용

Nginx, Caddy, Cloudflare Tunnel, 로드밸런서 등을 사용해 외부 도메인을 내부 Coolify 포트로 연결합니다.

```text
외부 도메인 -> http://127.0.0.1:8000
```

### C. Tailscale Serve 사용

Tailnet 내부에서 포트 없이 접속하고 싶다면 아래 스크립트를 사용합니다.

```bash
./scripts/configure-tailscale-serve.sh
```

직접 실행하면:

```bash
sudo tailscale serve --bg --http=80 http://127.0.0.1:8000
sudo tailscale serve status
```

Tailscale Serve를 끄려면:

```bash
sudo tailscale serve --http=80 off
```

## 6. 검증 방법

Compose 설정 파일을 정적으로 검증:

```bash
docker compose --env-file .env.example -f config/docker-compose.yml config --no-interpolate
```

이 검증 명령은 실제 서버 파일인 `/data/coolify/source/.env`가 아직 없는 체크아웃/CI 환경에서도 `.env.example` 값만으로 Compose 템플릿 구문을 확인할 수 있습니다. 실제 실행은 위 실행 방법처럼 `/data/coolify/source/.env`를 만든 뒤 `--env-file .env`로 진행하세요.

로컬 포트만 검증:

```bash
./scripts/verify-coolify.sh
```

외부 DNS/프록시까지 같이 검증하려면 `BASE_URL`을 넘깁니다.

```bash
BASE_URL="https://<사용자-도메인>" ./scripts/verify-coolify.sh
```

스크립트가 확인하는 내용:

- Coolify 관련 컨테이너 상태
- 로컬 `/api/health`
- `BASE_URL`을 지정한 경우 외부 `/api/health`
- Tailscale Serve 상태, 설치된 경우

## 7. 중지/내리기

컨테이너를 중지하고 제거합니다. 데이터 볼륨은 삭제하지 않습니다.

```bash
cd /data/coolify/source
sudo docker compose --env-file .env -f docker-compose.yml down
```

Tailscale Serve를 사용 중이었다면 같이 끕니다.

```bash
sudo tailscale serve --http=80 off
```

상태 확인:

```bash
sudo docker ps --filter 'name=coolify'
ss -ltnp | grep ':8000' || true
```

## 8. 시크릿 취급 주의

실제 서버의 `.env`는 앱 키, DB 비밀번호, Redis 비밀번호, 초기 root 계정 정보, 세션/토큰성 값 등을 포함할 수 있으므로 커밋하지 않습니다.

`.env.example`은 구조 참고용입니다. 실제 비밀번호나 운영 키를 넣지 마세요.
