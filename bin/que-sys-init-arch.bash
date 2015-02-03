#!/bin/bash

# Enable sudo access to wheel group
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# If run in debug mode prefix anything that changes the system with a debug function
is_opt $ISDEBUG && DEBUG='debug'
function debug () {
	echo DEBUG: "$@"
}

# Make sure we're off on the right foot before we get to adding  keys
$DEBUG pacman -Syu --needed --noconfirm haveged
systemctl start haveged
systemctl enable haveged
# If system has old GPG keys clear them before signing new ones...
# rm -rf /etc/pacman.d/gnupg
$DEBUG pacman-key --init
$DEBUG pacman-key --populate archlinux

# Freshen everything up
$DEBUG pacman -Syu --needed --noconfirm

# Remove anything that needs cleaning up first
$DEBUG pacman -Rns --noconfirm ${REMOVEPACKAGES[@]} $(pacman -Qtdq)

# Arch won't install gvim if vim is around, so to make the transition between
# package sets easier:
is_opt $ISDESKTOP && $DEBUG pacman -R --noconfirm vim

# Make sure the basics every system is going to need are installed and updated
$DEBUG pacman -S --needed --noconfirm ${BASEPACKAGES[@]}
is_opt $ISDESKTOP && $DEBUG pacman -S --needed --noconfirm ${DESKTOPPACKAGES[@]}

# Detect VirtualBox guest and configure accordingly
lspci | grep -iq virtualbox && (
	$DEBUG pacman -S --needed --noconfirm virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl enable vboxservice.service
	# $DEBUG pacman -S --needed --noconfirm xf86-video-vbox
)

# Get AUR going
$DEBUG pacman -S --needed --noconfirm base-devel

grep -q archlinuxfr /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n[extra]#g' /etc/pacman.conf
)
which yaourt || $DEBUG pacman -Sy --needed --noconfirm yaourt aurvote customizepkg

# Compile and install things not coming out of the distro main tree
$DEBUG yaourt --noconfirm -S --needed ${COMPILEBASEPACKAGES[@]}
is_opt $ISDESKTOP && $DEBUG yaourt --noconfirm -S --needed ${COMPILEDESKTOPPACKAGES[@]}

# TODO: Need to set root login and password auth options
systemctl enable sshd
systemctl enable ntpd
systemctl enable cronie

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# $DEBUG pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	systemctl enable gdm
	systemctl enable cups
	systemctl enable NetworkManager
fi

if is_opt $ISEC2; then
	remote_source que-sys-config-ec2.bash

	hostnamectl set-hostname $HOSTNAME.alerque.com
fi
