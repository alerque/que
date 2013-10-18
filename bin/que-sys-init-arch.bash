#!/bin/bash

# Freshen everything up
pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
pacman -S --needed --noconfirm ${BASEPACKAGES[@]}

# Network first net device on boot
#systemctl enable dhcpcd@$(ip link show | grep ^2: | awk -F: '{gsub(/[ \t]+/, "", $2); print $2}').service

# Desktop stuff?
# pacman -S --needed --noconfirm gnome xf86-video-nouveau nouveau-dri
# systemctl enable gdm

# Detect VirtualBox guest and configure accordingly
lspci | grep -iq virtualbox && (
	pacman -S --needed --noconfirm virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl enable vboxservice.service
	# pacman -S --needed --noconfirm xf86-video-vbox
)

# Get AUR going
pacman -S --needed --noconfirm base-devel
grep -q haskell-core /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[haskell-core]\nServer = http://xsounds.org/~haskell/core/$arch\n\n[extra]#g' /etc/pacman.conf
	pacman -Sy --noconfirm
	pacman-key --lsign-key 4209170B
)
bash <(curl aur.sh) -si aura --noconfirm --asroot
