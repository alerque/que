#!/bin/bash

echo -e 'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8\ntr_TR.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

# Enable sudo access to wheel group
sed -i -e 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

# Setup special priviledged user for compiling AUR packages
useradd -r -m -U -G wheel -k /dev/null que-bootstrap ||:
grep -q que-bootstrap /etc/suders ||
	sed -i -e '/^%wheel ALL=(ALL) ALL$/a que-bootstrap ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

# If run in debug mode prefix anything that changes the system with a debug function
is_opt $ISDEBUG && DEBUG='debug'
function debug () {
	echo DEBUG: "$@"
}

# Make sure we're off on the right foot before we get to adding  keys
$DEBUG pacman --needed --noconfirm -S haveged
systemctl --now enable haveged
# If system has old GPG keys clear them before signing new ones...
# rm -rf /etc/pacman.d/gnupg
$DEBUG pacman-key --init
$DEBUG pacman-key --populate archlinux

# Freshen everything up
$DEBUG pacman --needed --noconfirm -Syu

# Remove anything that needs cleaning up first
$DEBUG pacman -Rns --noconfirm ${REMOVEPACKAGES[@]} $(pacman -Qtdq) ||:

# Kill off archlinuxfr formerly used to install yaourt
grep archlinuxfr /etc/pacman.conf && (
    $DEBUG sed -i -e '/\[archlinuxfr\]/,/^$/{d;//b' -e '/./d;}' /etc/pacman.conf
)

# Install everything that comes from the official repositories
cut -d' ' -f1 \
    <(paclist core) <(paclist extra) <(paclist community) <(pacman -Sg) |
    grep -xho -E "($(IFS='|' eval 'echo "${BASEPACKAGES[*]}"'))" |
    $DEBUG xargs pacman --needed --noconfirm -S

# Install yay
which yay || (
    $DEBUG su -l que-bootstrap -c "git clone https://aur.archlinux.org/yay.git"
    $DEBUG su -l que-bootstrap -c "cd yay && makepkg --noconfirm --needed -si"
)

# Compile and install things not coming out of the distro main tree
$DEBUG su que-bootstrap -c "yay --needed --noconfirm -S ${BASEPACKAGES[*]}" ||:

# TODO: Need to set root login and password auth options
systemctl --now enable sshd ntpd cronie

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# $DEBUG pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	systemctl status gdm || systemctl --now enable lightdm
	systemctl --now enable org.cups.cupsd NetworkManager
	# Upstream doesn't include this by default to not conflict with other fonts
	ln -sf ../conf.avail/75-emojione.conf /etc/fonts/conf.d/75-emojione.conf
fi

if is_opt $ISEC2; then
	remote_source que-sys-config-ec2.bash
	hostnamectl set-hostname $HOSTNAME.alerque.com
fi

if is_opt $ISVBOX; then
	$DEBUG pacman --needed --noconfirm -S virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl --now enable vboxservice
	# $DEBUG pacman --needed --noconfirm -S xf86-video-vbox
fi
