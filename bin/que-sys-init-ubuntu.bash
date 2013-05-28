#!/bin/bash

function flunk() {
	echo "$*"
	exit
}

IS_VBOX=$(lspci | grep -iq virtualbox)
if [[ $IS_VBOX && ! $(lsmod | grep -iq vbox) ]]; then
	flunk "Please install virtualbox-additions"
fi

sudo apt-get update || flunk "Couldn't get apt-get repos"
sudo apt-get upgrade || flunk "Couldn't upgrade system packages"

read -p "Reboot? (y/n): " reboot
[[ $reboot  == y ]] && sudo reboot

sudo apt-get install zsh subversion vim vim-gnome

if ! svn info ~ ; then
    svn co -N http://svn.alerque.com/svn/caleb ~
    svn up ~/bin
fi
