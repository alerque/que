#!/bin/bash

# Freshen everything up
sudo pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
sudo pacman -S --needed --noconfirm ${BASEPACKAGES[@]}

# Network first net device on boot
systemctl enable dhcpcd@$(ip link show | grep ^2: | awk -F: '{gsub(/[ \t]+/, "", $2); print $2}').service

# Get AUR going
sudo pacman -S --needed --noconfirm base-devel
grep -q haskell-core /etc/pacman.conf || (
	sudo sed -i 's#^\[extra\]$#[haskell-core]\nServer = http://xsounds.org/~haskell/core/$arch\n\n[extra]#g' /etc/pacman.conf
	sudo pacman-key --lsign-key 4209170B
	sudo pacman -Syu
)
sudo bash <(curl aur.sh) -si aura --noconfirm --asroot
