# /bin/bash
# root

# apt-get install / need packages
apt-get upgrade
apt-get update
apt-get install python pip git
pip install --upgrade pip
apt-get install -y net-tools
apt-get -y install zsh 
apt-get install wget curl
apt-get -y install service
apt-get -y install git
apt-get -y install ruby
# apt-get install fcitx-hangul -y
# apt-get install fcitx-lib* -y
# apt-get install fonts-nanum* -y

# SSH Setting 
# apt-get install service -y
# apt-get install ssh -y
# service ssh restart
# service ssh status
# update-rc.d -f ssh enable 2 3 4 5

# ZSH Setting
chsh -s /bin/zsh
RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" 
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
~/.fzf/install
git clone https://github.com/rookedsysc/Linux_MacOS_Setting ~
cd ~/Linux_MacOS_Setting
export PATH="$PATH:/usr/bin"
export PATH="$PATH:/bin"
cp .zshrc ~/.zshrc

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
