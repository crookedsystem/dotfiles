#!/usr/bin/env bash
# Kali Linux 일반 사용자용 설치 스크립트 (sudo 권한 필요)
# 입력 프롬프트 없이 끝까지 진행되며, 다시 실행해도 이미 설치된 항목은 건너뛴다.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

DOTFILES_REPO="https://github.com/crookedsystem/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

FAILED_OPTIONAL_STEPS=()

apt_install() {
  sudo -E apt-get install -y "$@"
}

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

install_apt_packages() {
  sudo -E apt-get -y update
  sudo -E apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
  apt_install build-essential make ca-certificates curl wget git net-tools openssh-server \
    python3 python3-pip ruby zsh fzf
}

enable_ssh() {
  sudo systemctl enable --now ssh
}

# msfdb는 metasploit-framework가 설치된 Kali에만 있으므로 있을 때만 DB를 초기화한다.
setup_metasploit_database() {
  if ! command -v msfdb >/dev/null 2>&1; then
    echo "[!] msfdb가 없어 Metasploit DB 설정을 건너뜁니다 (metasploit-framework 미설치)"
    return
  fi
  run_optional sudo systemctl enable --now postgresql
  run_optional sudo msfdb init
}

copy_zshrc() {
  local zshrc_source="$DOTFILES_DIR/zshrc.linux"
  if [ ! -f "$zshrc_source" ]; then
    echo "[!] $zshrc_source 파일이 없어 ~/.zshrc를 복사하지 못했습니다."
    return 1
  fi
  cp "$zshrc_source" ~/.zshrc
}

install_zsh_environment() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_if_missing https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth 1
  ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

  clone_if_missing "$DOTFILES_REPO" "$DOTFILES_DIR"
  run_optional copy_zshrc
}

change_login_shell() {
  sudo chsh -s /usr/bin/zsh "$(id -un)"
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

sudo -v
install_apt_packages
enable_ssh
setup_metasploit_database
install_zsh_environment
change_login_shell
print_summary
