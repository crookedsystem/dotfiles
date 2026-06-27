# Coolify 설정 메모

## 1. 꼭 설정해야 하는 값

수동으로 `.env.example`을 복사해 `/data/coolify/source/.env`를 만들 때는 아래 placeholder만 새 값으로 바꿉니다. 실제 운영 `.env`는 커밋하지 않습니다.

| 변수 | 어떻게 설정하나 |
| --- | --- |
| `APP_ID` | `openssl rand -hex 16`으로 만든 랜덤 값을 넣습니다. 의미 있는 이름을 정할 필요는 없습니다. |
| `APP_KEY` | `printf 'base64:%s\n' "$(openssl rand -base64 32)"`로 한 번 만들고 유지합니다. 운영 중 임의로 바꾸면 기존 세션/토큰이 무효화될 수 있습니다. |
| `DB_PASSWORD` | `openssl rand -hex 32`로 만든 긴 랜덤 값을 넣습니다. |
| `REDIS_PASSWORD` | `openssl rand -hex 32`로 만든 긴 랜덤 값을 넣습니다. |
| `PUSHER_APP_ID` / `PUSHER_APP_KEY` | 각각 `openssl rand -hex 16`으로 만든 랜덤 값을 넣습니다. Coolify 내부 실시간 통신용이라 의미 있는 값일 필요는 없습니다. |
| `PUSHER_APP_SECRET` | `openssl rand -hex 32`로 만든 긴 랜덤 값을 넣습니다. |

## 2. 포트 변경

기본 접속 포트는 `8000`입니다. 서버에서 이미 `8000` 포트를 쓰고 있을 때만 `APP_PORT`를 바꿉니다.

```env
APP_PORT=8000
```

예를 들어 `8088`로 바꾸면 접속 주소도 같이 바뀝니다.

```env
APP_PORT=8088
```

```text
http://<서버-IP>:8088
```

## 3. DNS 설정

DNS는 이 레포에서 고정하지 않습니다. 서버 환경에 맞게 아래 중 하나만 선택합니다.

### A. 포트 직접 접속

```text
http://<서버-IP>:<APP_PORT>
```

### B. 리버스 프록시

```text
외부 도메인 -> http://127.0.0.1:<APP_PORT>
```

### C. Tailscale Serve

```text
http://<tailnet-hostname> -> http://127.0.0.1:<APP_PORT>
```
