#!/bin/bash

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# Make sure we're off on the right foot before we get to adding  keys
pacman -Syu --needed --noconfirm haveged
haveged -w 1024
pacman-key --init
pacman-key --populate archlinux
pkill haveged

# Freshen everything up
pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
pacman -S --needed --noconfirm ${BASEPACKAGES[@]}
test "$ISDESKTOP" == '1' && pacman -S --needed --noconfirm ${DESKTOPPACKAGES[@]}

# Network first net device on boot
#systemctl enable dhcpcd@$(ip link show | grep ^2: | awk -F: '{gsub(/[ \t]+/, "", $2); print $2}').service
e
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
# TODO: remove aura (ergo these haskell deps) in favor of yaourt?
grep -q haskell-core /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[haskell-core]\nServer = http://xsounds.org/~haskell/core/$arch\n\n[extra]#g' /etc/pacman.conf
	pacman-key --recv-keys 4209170B
	pacman-key --lsign-key 4209170B
	pacman -Sy --noconfirm
)
which aura || bash <(curl aur.sh) -si aura --noconfirm --asroot

grep -q archlinuxfr /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n[extra]#g' /etc/pacman.conf
)
which yaourt || pacman -Sy --needed --noconfirm yaourt

# Compile and install things not coming out of the distro main tree
aura -Ax --needed --noconfirm ${COMPILEBASEPACKAGES[@]}
test "$ISDESKTOP" == '1' && aura -Ax --needed --noconfirm ${COMPILEDESKTOPPACKAGES[@]}

# TODO: Need to set root login and password auth options
systemctl enable sshd
systemctl enable ntpd

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if [ "$ISDESKTOP" == '1' ]; then
	systemctl enable gdm
	systemctl enable cups
	systemctl enable NetworkManager
fi
