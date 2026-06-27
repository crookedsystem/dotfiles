# Coolify Tailscale Serve 설정 가이드

이 문서는 Coolify를 Linux 서버에 설치한 뒤, Tailnet 내부에서 포트 없이 접속하도록 Tailscale Serve를 붙이는 운영 메모입니다.

기본 전제는 아래와 같습니다.

```text
사용자 브라우저
  -> http://<tailnet-host>
  -> Tailscale Serve :80
  -> http://127.0.0.1:8000
  -> Coolify 컨테이너 내부 8080
```

이 디렉터리에는 시크릿이 없는 파일만 보관합니다.

```text
config/docker-compose.yml
.env.example                         # APP_PORT 예시만
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

이 디렉터리는 설치 결과를 문서화하고 재사용하기 위한 안전한 설정 템플릿입니다.

```bash
git clone https://github.com/crookedsystem/dotfiles.git
cd dotfiles/configs/coolify
```

Compose 파일을 서버의 Coolify 경로에 반영합니다.

```bash
sudo cp config/docker-compose.yml /data/coolify/source/docker-compose.yml
```

Coolify 공식 설치 스크립트가 만든 `/data/coolify/source/.env`는 그대로 둡니다. 이 레포의 `.env.example`은 전체 환경 변수 템플릿이 아니라 `APP_PORT` 예시만 담습니다.

## 3. 포트 변경

기본 포트 `8000`을 그대로 쓰면 아무것도 바꾸지 않아도 됩니다.

포트를 바꿔야 할 때만 실제 서버의 `/data/coolify/source/.env`에서 `APP_PORT` 하나만 설정합니다.

```dotenv
APP_PORT=8080
```

다른 `.env` 값은 직접 만들거나 수정하지 않습니다. Coolify 공식 설치 스크립트가 생성한 값을 그대로 둡니다.

포트를 바꿨다면 Tailscale Serve가 바라보는 내부 포트도 같은 값으로 맞춥니다.

## 4. Tailscale Serve 사용

Tailnet 내부에서 포트 없이 접속하고 싶다면 아래 스크립트를 사용합니다.

```bash
./scripts/configure-tailscale-serve.sh
```

기본 포트가 아닌 값을 쓴다면 `APP_PORT`만 넘깁니다.

```bash
APP_PORT=8080 ./scripts/configure-tailscale-serve.sh
```

직접 실행하면:

```bash
sudo tailscale serve --bg --http=80 http://127.0.0.1:8000
sudo tailscale serve status
```

`APP_PORT=8080`으로 바꿨다면:

```bash
sudo tailscale serve --bg --http=80 http://127.0.0.1:8080
sudo tailscale serve status
```

Tailscale Serve를 끄려면:

```bash
sudo tailscale serve --http=80 off
```

## 5. 실행 방법

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

포트를 바꿨다면 health check 주소도 같은 포트로 확인합니다.

```bash
curl -fsS http://127.0.0.1:8080/api/health
```

## 6. 검증 방법

Compose 설정 파일을 정적으로 검증:

```bash
docker compose --env-file .env.example -f config/docker-compose.yml config --no-interpolate
```

로컬 포트와 Tailscale Serve 상태를 검증:

```bash
./scripts/verify-coolify.sh
```

포트를 바꿨다면:

```bash
APP_PORT=8080 ./scripts/verify-coolify.sh
```

Tailnet URL까지 같이 검증하려면 `BASE_URL`을 넘깁니다.

```bash
BASE_URL="http://<tailnet-host>" ./scripts/verify-coolify.sh
```

스크립트가 확인하는 내용:

- Coolify 관련 컨테이너 상태
- 로컬 `/api/health`
- `BASE_URL`을 지정한 경우 Tailnet `/api/health`
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
