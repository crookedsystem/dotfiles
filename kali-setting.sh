# /bin/bash 
# root
# for kali linux

# kali msf setting
msfdb init
service postgresql start
update-rc.d postgresql enable 

# Updates
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install zsh
sudo apt-get -y install python pip git
pip install --upgrade pip
sudo apt-get install -y net-tools
sudo apt-get -y install wget curl
sudo apt-get -y install service
sudo apt-get install -y git
sudo apt install build-essential -y
sudo apt-get install -y ruby
sudo apt-get install -y make

# ssh setting
sudo apt install openssh-server
sudo systemctl enable ssh

# zsh plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

