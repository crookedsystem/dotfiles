#!/usr/bin/env bash
# Ubuntu root 계정용 설치 스크립트 (일반 사용자는 install-ubuntu.sh를 사용한다)
# 입력 프롬프트 없이 끝까지 진행되며, 다시 실행해도 이미 설치된 항목은 건너뛴다.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

ROOT_HOME="$(getent passwd root | cut -d: -f6)"
ROOT_ZSH_DIR="$ROOT_HOME/.oh-my-zsh"
ROOT_ZSH_CUSTOM="$ROOT_ZSH_DIR/custom"
DOTFILES_REPO="https://github.com/crookedsystem/dotfiles"
DOTFILES_DIR="$ROOT_HOME/dotfiles"

FAILED_OPTIONAL_STEPS=()

# 부가 단계가 일시적으로 실패해도 나머지 설치가 멈추지 않도록 실패만 기록한다.
run_optional() {
  "$@" || FAILED_OPTIONAL_STEPS+=("$*")
}

clone_if_missing() {
  local repository_url="$1"
  local target_dir="$2"
  shift 2
  if [ -d "$target_dir" ]; then
    return
  fi
  git clone "$@" "$repository_url" "$target_dir"
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[!] root 계정으로 실행해야 합니다. 일반 사용자는 install-ubuntu.sh를 사용하세요."
    exit 1
  fi
}

install_apt_packages() {
  apt-get -y update
  apt-get install -y ca-certificates curl git zsh fzf neovim
}

copy_zshrc() {
  local zshrc_source="$DOTFILES_DIR/zshrc.linux"
  if [ ! -f "$zshrc_source" ]; then
    echo "[!] $zshrc_source 파일이 없어 $ROOT_HOME/.zshrc를 복사하지 못했습니다."
    return 1
  fi
  cp "$zshrc_source" "$ROOT_HOME/.zshrc"
}

install_zsh_environment() {
  if [ ! -d "$ROOT_ZSH_DIR" ]; then
    HOME="$ROOT_HOME" ZSH="$ROOT_ZSH_DIR" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ROOT_ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ROOT_ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_if_missing https://github.com/spaceship-prompt/spaceship-prompt.git "$ROOT_ZSH_CUSTOM/themes/spaceship-prompt" --depth 1
  ln -sf "$ROOT_ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ROOT_ZSH_CUSTOM/themes/spaceship.zsh-theme"

  clone_if_missing "$DOTFILES_REPO" "$DOTFILES_DIR"
  run_optional copy_zshrc
}

change_login_shell() {
  chsh -s /usr/bin/zsh root
}

print_summary() {
  echo ""
  echo "[*] 설치가 끝났습니다."
  echo "[*] 기본 셸(zsh)은 다음 로그인부터 적용됩니다. 지금 zsh를 쓰려면 'exec zsh'를 실행하세요."
  if [ "${#FAILED_OPTIONAL_STEPS[@]}" -gt 0 ]; then
    echo "[!] 아래 부가 단계는 실패했습니다. 스크립트를 다시 실행하면 이 항목만 재시도합니다."
    printf '    - %s\n' "${FAILED_OPTIONAL_STEPS[@]}"
    exit 1
  fi
}

require_root
install_apt_packages
install_zsh_environment
change_login_shell
print_summary
