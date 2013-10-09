#!/bin/bash

IS_VBOX=$(lspci | grep -iq virtualbox)
if [[ $IS_VBOX && ! $(lsmod | grep -iq vbox) ]]; then
	flunk "Please install virtualbox-additions"
fi

# Fix system laguage
sudo sed -i 's/^LANG=.*$/LANG=en_US.utf8/' /etc/default/locale

sudo apt-get -y update || flunk "Couldn't get apt-get repos"
sudo apt-get -y upgrade || flunk "Couldn't upgrade system packages"
sudo apt-get -y autoremove

#read -p "Reboot? (y/n): " reboot
#[[ $reboot  == y ]] && sudo reboot

sudo apt-get -y install ${BASEPACKAGES[@]}

# Fix etckeeper defaults
sudo sed -i 's/^VCS=".*"$/VCS="git"/' /etc/etckeeper/etckeeper.conf
