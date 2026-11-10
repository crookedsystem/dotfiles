#!/usr/bin/env bash
# macOS 개발 환경 설치 스크립트 (Homebrew가 먼저 설치되어 있어야 한다)
# 입력 프롬프트 없이 끝까지 진행되며, 다시 실행해도 이미 설치된 항목은 건너뛴다.
set -euo pipefail

DOTFILES_REPO="https://github.com/crookedsystem/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

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

require_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "[!] Homebrew가 설치되어 있지 않습니다. https://brew.sh 안내에 따라 먼저 설치하세요."
    exit 1
  fi
}

install_homebrew_tools() {
  run_optional brew update

  local formula
  for formula in curl git ripgrep fzf tmux neovim htop lazygit lazydocker ffmpeg; do
    run_optional brew install "$formula"
  done
  run_optional brew install --cask hammerspoon
  clone_if_missing https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_nvm() {
  # rc 파일 수정은 zshrc.macos가 담당하므로 PROFILE=/dev/null로 설치기의 수정을 막는다.
  if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | PROFILE=/dev/null bash
  fi
}

copy_zshrc() {
  local zshrc_source="$DOTFILES_DIR/zshrc.macos"
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
  clone_if_missing https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" --depth 1

  # brew로 받은 fzf의 셸 연동(키 바인딩, 자동 완성, ~/.fzf.zsh 생성)을 설정한다.
  run_optional "$(brew --prefix)/opt/fzf/install" --all

  # fzf 설치기가 ~/.zshrc를 수정하므로 설정 파일 복사는 그 뒤에 한다.
  clone_if_missing "$DOTFILES_REPO" "$DOTFILES_DIR"
  run_optional copy_zshrc
}

# macOS의 기본 셸은 이미 zsh이므로 다른 셸일 때만 바꾼다.
change_login_shell() {
  if [ "${SHELL:-}" != "/bin/zsh" ]; then
    sudo chsh -s /bin/zsh "$(id -un)"
  fi
}

print_summary() {
  echo ""
  echo "[*] 설치가 끝났습니다. 지금 zsh를 쓰려면 'exec zsh'를 실행하세요."
  if [ "${#FAILED_OPTIONAL_STEPS[@]}" -gt 0 ]; then
    echo "[!] 아래 부가 단계는 실패했습니다. 스크립트를 다시 실행하면 이 항목만 재시도합니다."
    printf '    - %s\n' "${FAILED_OPTIONAL_STEPS[@]}"
    exit 1
  fi
}

require_homebrew
install_homebrew_tools
install_nvm
install_zsh_environment
change_login_shell
print_summary
