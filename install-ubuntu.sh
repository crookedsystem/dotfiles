#!/usr/bin/env bash
# Ubuntu 일반 사용자용 개발 환경 설치 스크립트 (sudo 권한 필요)
# 입력 프롬프트 없이 끝까지 진행되며, 다시 실행해도 이미 설치된 항목은 건너뛴다.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

DOTFILES_REPO="https://github.com/crookedsystem/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
NVIM_CONFIG_REPO="https://github.com/crookedsystem/nvim"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

FAILED_OPTIONAL_STEPS=()

apt_install() {
  sudo -E apt-get install -y "$@"
}

# GitHub 릴리스 다운로드가 일시적으로 실패해도 나머지 설치가 멈추지 않도록, 부가 도구는 실패만 기록한다.
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
  apt_install build-essential procps file curl wget git ca-certificates gnupg \
    net-tools openssh-server python3 python3-pip xauth xclip locales zsh
}

configure_locale_and_ssh() {
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
  sudo systemctl enable --now ssh
}

install_homebrew_and_tools() {
  if [ ! -x "$BREW_BIN" ]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # zshrc.linux가 같은 줄을 이미 로드하므로 bash 로그인 셸용으로만 한 번 추가한다.
  if ! grep -qF "$BREW_BIN shellenv" ~/.bashrc 2>/dev/null; then
    echo "eval \"\$($BREW_BIN shellenv)\"" >>~/.bashrc
  fi
  eval "$("$BREW_BIN" shellenv)"

  local formula
  for formula in ripgrep fzf tmux neovim htop lazygit lazydocker; do
    run_optional brew install --no-ask "$formula"
  done
  clone_if_missing https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_language_toolchains() {
  if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y
  fi
  # rc 파일 수정은 zshrc.linux가 담당하므로 PROFILE=/dev/null로 설치기의 수정을 막는다.
  if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | PROFILE=/dev/null bash
  fi
}

install_docker() {
  . /etc/os-release
  if [ "${ID:-}" != "ubuntu" ]; then
    echo "[!] Ubuntu가 아니라서 Docker 설치를 건너뜁니다 (ID=${ID:-unknown})"
    return
  fi
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo -E apt-get -y update
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # docker 그룹은 다음 로그인부터 적용된다. newgrp는 새 셸을 열어 스크립트를 멈추므로 쓰지 않는다.
  sudo usermod -aG docker "$(id -un)"
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

  # brew로 받은 fzf의 셸 연동(키 바인딩, 자동 완성, ~/.fzf.zsh 생성)을 설정한다.
  run_optional "$(brew --prefix)/opt/fzf/install" --all

  # fzf 설치기가 ~/.zshrc를 수정하므로 설정 파일 복사는 그 뒤에 한다.
  clone_if_missing "$DOTFILES_REPO" "$DOTFILES_DIR"
  run_optional copy_zshrc
}

install_neovim_environment() {
  mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
  if [ -e "$NVIM_CONFIG_DIR" ] && ! git -C "$NVIM_CONFIG_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[!] $NVIM_CONFIG_DIR 경로에 다른 설정이 있어 crookedsystem/nvim을 설치하지 못했습니다."
    return 1
  fi

  clone_if_missing "$NVIM_CONFIG_REPO" "$NVIM_CONFIG_DIR" || return 1

  local origin_url
  origin_url=$(git -C "$NVIM_CONFIG_DIR" remote get-url origin) || return 1
  case "$origin_url" in
    *github.com/crookedsystem/nvim | *github.com/crookedsystem/nvim.git | *github.com:crookedsystem/nvim.git) ;;
    *)
      echo "[!] $NVIM_CONFIG_DIR 경로가 crookedsystem/nvim 저장소가 아니라서 기존 설정을 유지합니다."
      return 1
      ;;
  esac

  make -C "$NVIM_CONFIG_DIR" install
}

change_login_shell() {
  sudo chsh -s /usr/bin/zsh "$(id -un)"
}

print_summary() {
  echo ""
  echo "[*] 설치가 끝났습니다."
  echo "[*] 기본 셸(zsh)과 docker 그룹은 다음 로그인부터 적용됩니다. 지금 zsh를 쓰려면 'exec zsh'를 실행하세요."
  if [ "${#FAILED_OPTIONAL_STEPS[@]}" -gt 0 ]; then
    echo "[!] 아래 부가 도구 설치는 실패했습니다. 스크립트를 다시 실행하면 이 항목만 재시도합니다."
    printf '    - %s\n' "${FAILED_OPTIONAL_STEPS[@]}"
    exit 1
  fi
}

sudo -n true
install_apt_packages
configure_locale_and_ssh
install_homebrew_and_tools
install_language_toolchains
install_docker
install_zsh_environment
run_optional install_neovim_environment
change_login_shell
print_summary
