#!/bin/bash

# Freshen everything up
sudo pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
sudo pacman -S --needed --noconfirm ${BASEPACKAGES[@]}

# Get AUR going
pacman -S --needed --noconfirm base-devel

grep -q haskell-core /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[haskell-core]\nServer = http://xsounds.org/~haskell/core/$arch\n\n[extra]#g' /etc/pacman.conf
	pacman-key --lsign-key 4209170B
	pacman -Syu
)

bash <(curl aur.sh) -si aura --noconfirm --asroot
