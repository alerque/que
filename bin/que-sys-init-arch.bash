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

# Arch won't install gvim if vim is around, so to make the transition between package sets eaiser:
is_opt $ISDESKTOP && pacman -R --noconfirm vim

# Make sure the basics every system is going to need are installed and updated
pacman -S --needed --noconfirm ${BASEPACKAGES[@]}
is_opt $ISDESKTOP && pacman -S --needed --noconfirm ${DESKTOPPACKAGES[@]}

# Detect VirtualBox guest and configure accordingly
lspci | grep -iq virtualbox && (
	pacman -S --needed --noconfirm virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl enable vboxservice.service
	# pacman -S --needed --noconfirm xf86-video-vbox
)

# Get AUR going
pacman -S --needed --noconfirm base-devel

grep -q archlinuxfr /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n[extra]#g' /etc/pacman.conf
)
which yaourt || pacman -Sy --needed --noconfirm yaourt aurvote customizepkg

# Compile and install things not coming out of the distro main tree
yaourt --noconfirm -S --needed ${COMPILEBASEPACKAGES[@]}
is_opt $ISDESKTOP && yaourt --noconfirm -S --needed ${COMPILEDESKTOPPACKAGES[@]}

# TODO: Need to set root login and password auth options
systemctl enable sshd
systemctl enable ntpd
systemctl enable cronie

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	systemctl enable gdm
	systemctl enable cups
	systemctl enable NetworkManager
fi

if is_opt $ISEC2; then
	remote_source que-sys-config-ec2.bash

	hostnamectl set-hostname $HOSTNAME.alerque.com
fi
