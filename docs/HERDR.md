# Herdr 가이드 (tmux와 다른 점만)

> tmux를 이미 쓰는 사람이 herdr로 넘어갈 때 달라지는 것만 정리한 문서. tmux와 같은 단축키와 herdr에만 있는 단축키는 넣지 않았다.
> 기준 버전: herdr TUI v0.9.5 · 공식 문서: https://herdr.dev/tui/docs/ · tmux 쪽 기준: [TMUX.md](./TMUX.md)

herdr는 tmux처럼 백그라운드 서버가 터미널을 들고 있는 도구다. Prefix도 `C-b`로 같다. 다른 점은 pane에서 도는 코딩 에이전트(Claude Code, Codex 등)를 알아보고, 그 상태(blocked/working/done/idle)를 사이드바에 보여 준다는 것이다.

## 설치

```bash
brew install herdr
herdr        # tmux의 `tmux`처럼 default 세션을 띄우거나 붙는다
```

## 개념 대응

| tmux | herdr | 차이 |
|------|-------|------|
| session | workspace | 저장소·작업 하나당 하나씩 만드는 단위 |
| window | tab | |
| pane | pane | 같음 |
| 별도 서버 (`tmux -L <socket>`) | session | herdr의 session은 서버 네임스페이스 자체를 나눈다. 평소에는 workspace만 쓰면 된다 |

## 단축키: 같은 동작, 다른 키

| 동작 | tmux | herdr |
|------|------|--------|
| detach | `C-b d` | `prefix+q` |
| 세션(워크스페이스) 목록에서 선택 | `C-b s` | `prefix+w` |
| 세션(워크스페이스) 이름 변경 | `C-b $` | `prefix+shift+w` |
| 윈도우(탭) 이름 변경 | `C-b ,` | `prefix+shift+t` |
| 윈도우(탭) 종료 | `C-b &` | `prefix+shift+x` |
| 번호로 윈도우(탭) 이동 | `C-b 0-9` | `prefix+1-9` (0번 없음) |
| 수직 분할 (좌우) | `C-b %` | `prefix+v` |
| 수평 분할 (상하) | `C-b "` | `prefix+minus` |
| 다음 페인 | `C-b o` | `prefix+tab` (이전: `prefix+shift+tab`) |
| 방향으로 페인 이동 | `C-b 방향키` | `prefix+h/j/k/l` |
| 페인 위치 교환 | `C-b {` / `C-b }` | `prefix+shift+h/j/k/l` (방향 지정) |
| 페인 크기 조절 | `C-b C-방향키` / `C-b M-방향키` | `prefix+r`로 resize 모드 진입 |

## 단축키: 같은 키, 다른 동작 (손버릇 주의)

| 키 | tmux | herdr |
|----|------|-------|
| `C-b s` | 세션 목록 | 설정 열기 |
| `C-b w` | 윈도우 목록 | 워크스페이스 선택 화면 |
| `C-b l` | 마지막 윈도우로 전환 | 오른쪽 페인으로 이동 |
| `C-b r` | 화면 새로고침 | resize 모드 진입 |
| `C-b q` | 페인 번호 표시 | detach |
| `C-b o` | 다음 페인 | 알림이 뜬 대상으로 이동 |

## CLI 대응

herdr CLI는 이름이 아니라 **ID로 대상을 지정**한다. ID는 `list` 명령의 JSON 출력에서 확인한다.

| tmux | herdr |
|------|-------|
| `tmux ls` | `herdr workspace list` |
| `tmux new -s <name> -c <dir>` | `herdr workspace create --label <name> --cwd <dir>` |
| `tmux attach -t <name>` | `herdr` (default 세션에 붙은 뒤 워크스페이스 선택) |
| `tmux switch -t <name>` | `herdr workspace focus <workspace_id>` |
| `tmux kill-session -t <name>` | `herdr workspace close <workspace_id>` |
| `tmux lsw -t <session>` | `herdr tab list --workspace <workspace_id>` |
| `tmux neww -t <session> -n <name>` | `herdr tab create --workspace <workspace_id> --label <name>` |
| `tmux selectw -t <session>:<window>` | `herdr tab focus <tab_id>` |
| `tmux killw -t <session>:<index>` | `herdr tab close <tab_id>` |
| `tmux kill-server` | `herdr server stop` |
| `tmux source-file ~/.config/tmux/tmux.conf` | `herdr server reload-config` |

## 설정 파일

| | tmux | herdr |
|---|------|-------|
| 경로 | `~/.config/tmux/tmux.conf` | `~/.config/herdr/config.toml` |
| 형식 | tmux 명령어 | TOML |
| 기본값 확인 | `tmux list-keys` | `herdr --default-config` |

### 저장소 설정 적용

[config/herdr/config.toml](../config/herdr/config.toml)은 Herdr TUI의 내장 One Dark 테마를 사용하고, 왼쪽 사이드바를 완전히 숨긴 상태로 시작한다. 테마 자동 전환은 꺼져 있어 터미널의 밝은 모드에서도 One Dark를 유지한다. 별도 테마 파일은 필요 없다.

저장소 루트에서 설정 파일만 복사한다. 기존 설정이 있으면 먼저 백업한다.

```bash
mkdir -p ~/.config/herdr
if [ -f ~/.config/herdr/config.toml ]; then
  cp ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak-$(date +%Y%m%d-%H%M%S)
fi
cp config/herdr/config.toml ~/.config/herdr/config.toml
herdr config check
```

이 명령은 기존 `config.toml`을 저장소 설정으로 교체한다. 기존 단축키 등도 유지하려면 복사 대신 `[theme]`와 `[ui]`의 해당 항목을 기존 설정에 합친다. 로그나 `sessions/`는 복사하지 않는다.

실행 중인 Herdr에서 `Ctrl+b`를 누른 뒤 `Shift+r`을 누르면 설정을 다시 읽는다. 또는 현재 세션을 지정해 CLI로 다시 읽을 수 있다.

```bash
herdr server reload-config
# 이름 있는 세션에서 사용하는 경우
herdr --session <name> server reload-config
```

사이드바 기본 닫힘은 다음 클라이언트 실행부터 적용된다. `Ctrl+b` → `q`로 detach한 뒤 `herdr`로 다시 붙는다. 이름 있는 세션은 `herdr --session <name>`으로 다시 붙는다. 서버를 중지할 필요는 없다.

현재 화면에서 바로 사이드바를 열거나 닫으려면 `Ctrl+b` → `b`를 누른다. 위 키는 기본 prefix 기준이다.

공식 문서: [테마와 설정 다시 읽기](https://herdr.dev/tui/docs/configuration/#theme), [사이드바 시작 상태](https://herdr.dev/tui/docs/config-reference/#ui-and-sidebar).

### 단축키 변경

```toml
# 단축키는 [keys] 아래에 동작 이름 = 키 형태로 바꾼다
[keys]
prefix = "ctrl+b"
split_vertical = "prefix+v"
split_horizontal = "prefix+minus"
```

## Worktree 워크플로우 차이

[TMUX.md](./TMUX.md)의 `twn` alias처럼 `git worktree add`와 세션 생성을 직접 묶을 필요가 없다. herdr가 worktree를 만들고 부모 워크스페이스 아래에 묶어 보여 준다. 체크아웃 경로 기본값은 `~/.herdr/worktrees/<repo>/<branch-slug>`이다.

```bash
herdr worktree create --branch feature-login --focus
herdr worktree list
herdr worktree remove --workspace <workspace_id>   # 브랜치는 지우지 않음
```
