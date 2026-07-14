# /bin/bash

# Brew Setting
brew update
brew install curl
brew install git
brew install hammerspoon --cask
brew install ffmpeg



#code server
#brew install git-lfs
## After Node -v 16.16 install 
#sudo npm install -g yarn
#sudo npm install -g nfpm
#brew install jq
#brew install gnupg
#brew install quilt bats
#sudo npm install -g bats

# git clone
git clone https://github.com/rookedsysc/Linux_MacOS_Setting

# ZSH Setting
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
~/.fzf/install
git clone https://github.com/rookedsysc/Linux_MacOS_Setting
cd ./Linux_MacOS_Setting
export PATH="$PATH:/usr/bin"
export PATH="$PATH:/bin"
cp zshrc.mac ~/.zshrc
source ~/.zshrc

# if dont install zsh-autosuggetions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
