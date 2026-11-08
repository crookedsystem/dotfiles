# /bin/bash
# Linux Setting for User ID

# 설치 중 대화형 입력이 뜨지 않도록 비대화 모드로 고정
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Updates
sudo apt-get -y update
sudo -E apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get -y install build-essential
sudo apt-get install -y net-tools
sudo apt-get -y install service
sudo apt-get install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo apt-get -y install python pip
sudo -E apt-get install -y xauth xclip

pip install --upgrade pip

# brew 설치
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >>~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install git wget curl zsh rg
brew install tmux raine/workmux/workmux

# TPM (Tmux Plugin Manager) Install
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 언어팩 설치
sudo -E apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Cargo / Rust Install
curl https://sh.rustup.rs -sSf | sh -s -- -y

# NVM Install
curl -o install_nvm.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh


# ssh setting

# ZSH Setting
sudo chsh -s /bin/zsh "$USER"
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
git clone https://github.com/crookedsystem/dotfiles
cd ./Linux_MacOS_Setting
cp .zshrc ~/.zshrc
source ~/.zshrc
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(which zsh)" "$USER"

# Utils
# LazyVim
brew install nvim
brew install jesseduffield/lazydocker/lazydocker
brew install font-hack-nerd-font
# LazyGit                                 #
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/lazygit
# HTOP
brew install htop
# Docker
if command -v apt-get >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get -y update
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
fi
sudo usermod -aG docker $USER

# Setting Check
echo ""
echo "[*][*][*][*][*][*][*][*]"
echo "[*][*]SettingCheck[*][*]"
echo "[*][*][*][*][*][*][*][*]"
echo ""
echo "[!] PATH"
echo $PATH
echo "[!] Zsh Setting"
echo $SHELL

# ZSH Theme
mkdir ~/.oh-my-zsh/themes/spaceship
git clone https://github.com/spaceship-prompt/spaceship-prompt ~/.oh-my-zsh/themes/spaceship
ln -s ~/.oh-my-zsh/themes/spaceship/spaceship.zsh-theme ~/.oh-my-zsh/themes/spaceship.zsh-theme

source ~/.zshrc
