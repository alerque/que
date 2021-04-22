#!/bin/bash

echo -e 'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8\ntr_TR.UTF-8 UTF-8' > /etc/locale.gen
localectl list-locales | grep -vq -e US -e TR -e RU && locale-gen

# Enable sudo access to wheel group
echo -e '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/70-wheel

# Setup my prefered sudo user settings
echo -e 'Defaults:caleb timestamp_timeout=90,passwd_timeout=0,!tty_tickets,insults,!requiretty,passwd_tries=5,env_keep+="TMUX"' > /etc/sudoers.d/99-caleb

# Setup special priviledged user for compiling AUR packages
useradd -r -m -U -G wheel -k /dev/null que-bootstrap ||:
echo -e 'Defaults:que-bootstrap !authenticate' > /etc/sudoers.d/99-que-bootstrap

chmod 600 /etc/sudoers.d/*

# Cleanup old way of adding bootstrap priviledges
grep -q que-bootstrap /etc/sudoers && sed -i -e '/^que-bootstrap/d' /etc/sudoers ||:

# If run in debug mode prefix anything that changes the system with a debug function
is_opt $ISDEBUG && DEBUG='debug'
function debug () {
	echo DEBUG: "$@"
}

# Update mirror list reflector installed but never run
function update_mirrors () {
    command -v reflector && {
        grep -q reflector /etc/pacman.d/mirrorlist ||
        reflector --verbose --protocol https --score 50 --fastest 25 --latest 10 --save /etc/pacman.d/mirrorlist
    }
}

# Setup systemctl argument to start services if not in chroot
[[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]] || export NOW="--now"

# Make sure we're off on the right foot before we get to adding  keys
$DEBUG pacman --needed --noconfirm -S haveged
$DEBUG systemctl $NOW enable haveged

# If system has old GPG keys clear them before signing new ones...
# rm -rf /etc/pacman.d/gnupg
$DEBUG pacman-key --init
$DEBUG pacman-key --populate archlinux

$DEBUG update_mirrors ||:

# Add my own Arch package repository, after community
$DEBUG pacman-key --recv-keys 63CC496475267693
$DEBUG pacman-key --lsign-key 63CC496475267693
$DEBUG grep -q alerque /etc/pacman.conf ||
    sed -i -e '/^.community/{n;n;s!^!\n\[alerque\]\nServer = https://arch.alerque.com/$arch\n!}' /etc/pacman.conf

# Freshen everything up
$DEBUG pacman --needed --noconfirm -Syu

# Remove anything that needs cleaning up first
$DEBUG pacman --noconfirm -Rns ${REMOVEPACKAGES[@]} $(pacman -Qtdq) ||:

# Kill off archlinuxfr repository, formerly used to install yaourt
grep archlinuxfr /etc/pacman.conf && (
    $DEBUG sed -i -e '/\[archlinuxfr\]/,/^$/{d;//b' -e '/./d;}' /etc/pacman.conf
)

# Save time parsing AUR packages by only installing, not updating them. We
# already freshed all repositoy packages before starting, freshening AUR
# packages can be left as an excercise for the reader.
UNINSTALLEDPACKAGES=(base $(echo ${BASEPACKAGES[*]} | tr ' ' '\n' | grep -xvhE "($(echo -n $(pacman -Qqe) | tr ' ' '|'))"))

# Install everything not already installed that can come from repositories
pacman -Ssq |
    grep -xvf <(pacman -Qsq) |
    grep -xho -E "($(IFS='|' eval 'echo "${UNINSTALLEDPACKAGES[*]}"'))" |
    $DEBUG xargs pacman --needed --noconfirm -S ||:

# Compile and install things not coming out of the distro main tree
$DEBUG su que-bootstrap -c "yay --needed --noconfirm -S ${UNINSTALLEDPACKAGES[*]}" ||:

# TODO: Need to set root login and password auth options
$DEBUG systemctl $NOW enable sshd cronie systemd-timesyncd

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# $DEBUG pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	$DEBUG systemctl status gdm || systemctl enable lightdm
	$DEBUG systemctl $NOW enable org.cups.cupsd
	$DEBUG rm -f /etc/fonts/conf.d/75-{emojione,joypixels}.conf
fi

if is_opt $ISEC2; then
    $DEBUG remote_source que-sys-config-ec2.bash
    $DEBUG hostnamectl set-hostname $HOSTNAME.alerque.com
fi

if is_opt $ISVBOX; then
	$DEBUG pacman --needed --noconfirm -S virtualbox-guest-utils
	echo -e 'vboxguest\nvboxsf\nvboxvideo' > /etc/modules-load.d/virtualbox.conf
	$DEBUG systemctl $NOW enable vboxservice
	# $DEBUG pacman --needed --noconfirm -S xf86-video-vbox
fi

# Setup etckeeper
sed -i -e 's/^HIGHLEVEL_PACKAGE_MANAGER=.*$/HIGHLEVEL_PACKAGE_MANAGER=yay/g' /etc/etckeeper/etckeeper.conf

update_mirrors

# Force nameserver and domain
echo -e 'nameserver 1.1.1.1\nsearch alerque.com' > /etc/resolv.conf

localectl list-keymaps | grep -q dvp && localectl --no-convert set-keymap dvp ||:
