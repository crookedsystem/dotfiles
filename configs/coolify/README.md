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
config/env.example
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

`.env`가 없는 새 환경에서 수동으로 시작해야 한다면 예시 파일을 참고해 직접 값을 채우세요.

```bash
sudo cp config/env.example /data/coolify/source/.env
sudo nano /data/coolify/source/.env
```

주의: `APP_KEY`, `DB_PASSWORD`, `REDIS_PASSWORD`, `PUSHER_APP_SECRET`, `ROOT_USER_PASSWORD` 같은 값은 반드시 새로 생성한 안전한 값으로 바꿔야 합니다. 실서비스에서는 공식 설치 스크립트가 생성한 `.env`를 유지하는 편이 안전합니다.

## 3. 실행 방법

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

## 4. DNS 또는 프록시 연결

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

## 5. 검증 방법

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

## 6. 중지/내리기

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

## 7. 시크릿 취급 주의

실제 서버의 `.env`는 앱 키, DB 비밀번호, Redis 비밀번호, 초기 root 계정 정보, 세션/토큰성 값 등을 포함할 수 있으므로 커밋하지 않습니다.

`config/env.example`은 구조 참고용입니다. 실제 비밀번호나 운영 키를 넣지 마세요.
