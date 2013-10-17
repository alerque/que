#!/bin/bash

# Freshen everything up
sudo pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
sudo pacman -S --needed --noconfirm ${BASEPACKAGES[@]}

# Get AUR going
pacman -S --needed --noconfirm base-devel
bash <(curl aur.sh) -si aura --noconfirm --asroot
