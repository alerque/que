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
systemctl --now enable haveged
# If system has old GPG keys clear them before signing new ones...
# rm -rf /etc/pacman.d/gnupg
$DEBUG pacman-key --init
$DEBUG pacman-key --populate archlinux

# Freshen everything up
$DEBUG pacman -Syu --needed --noconfirm

# Remove anything that needs cleaning up first
$DEBUG pacman -Rns --noconfirm ${REMOVEPACKAGES[@]} $(pacman -Qtdq) ||:

# Get AUR going
$DEBUG pacman -S --needed --noconfirm base-devel pacman-contrib

# Kill off archlinuxfr formerly used to install yaourt
grep archlinuxfr /etc/pacman.conf && (
    $DEBUG sed -i -e '/\[archlinuxfr\]/,/^$/{d;//b' -e '/./d;}' /etc/pacman.conf
)

# Install everything that comes from the official repositories
cut -d' ' -f1 \
    <(paclist core) <(paclist extra) <(paclist community) <(pacman -Sg) |
    grep -xho -E "($(IFS='|' eval 'echo "${BASEPACKAGES[*]}"'))" |
    $DEBUG xargs pacman -S --needed --noconfirm

# Detect VirtualBox guest and configure accordingly
lspci | grep -iq virtualbox && (
	$DEBUG pacman -S --needed --noconfirm virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl --now enable vboxservice.service
	# $DEBUG pacman -S --needed --noconfirm xf86-video-vbox
) ||:

# Arch folks disabled building packages as root in makepkg. As this is required
# for this script, patch it to work again. See Github issue for details:
#	https://github.com/archlinuxfr/yaourt/issues/67
grep -q asroot /usr/bin/makepkg || (cd / && $DEBUG patch -b -p0) <<"EndOfPatch"
--- /usr/bin/makepkg~
+++ /usr/bin/makepkg
@@ -1239,7 +1239,7 @@ OPT_LONG=('allsource' 'check' 'clean' 'cleanbuild' 'config:' 'force' 'geninteg'
           'help' 'holdver' 'ignorearch' 'install' 'key:' 'log' 'noarchive' 'nobuild'
           'nocolor' 'nocheck' 'nodeps' 'noextract' 'noprepare' 'nosign' 'packagelist'
           'printsrcinfo' 'repackage' 'rmdeps' 'sign' 'skipchecksums' 'skipinteg'
-          'skippgpcheck' 'source' 'syncdeps' 'verifysource' 'version')
+          'skippgpcheck' 'source' 'syncdeps' 'verifysource' 'version' 'asroot')
 
 # Pacman Options
 OPT_LONG+=('asdeps' 'noconfirm' 'needed' 'noprogressbar')
@@ -1410,11 +1410,7 @@ if (( LOGGING )) && ! ensure_writable_dir "LOGDEST" "$LOGDEST"; then
 fi
 
 if (( ! INFAKEROOT )); then
-	if (( EUID == 0 )); then
-		error "$(gettext "Running %s as root is not allowed as it can cause permanent,\n\
-catastrophic damage to your system.")" "makepkg"
-		exit $E_ROOT
-	fi
+	:
 else
 	if [[ -z $FAKEROOTKEY ]]; then
 		error "$(gettext "Do not use the %s option. This option is only for internal use by %s.")" "'-F'" "makepkg"
EndOfPatch

# Install yay
which yay || (
    $DEBUG cd /root
    which git || $DEBUG pacman -S git
    $DEBUG git clone https://aur.archlinux.org/yay.git
    $DEBUG cd yay
    $DEBUG makepkg -si
)

# Compile and install things not coming out of the distro main tree
for PKG in ${COMPILEBASEPACKAGES[@]} ; do
    $DEBUG yay --noconfirm -S --needed $PKG ||:
done

# TODO: Need to set root login and password auth options
systemctl --now enable sshd
systemctl --now enable ntpd
systemctl --now enable cronie

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# $DEBUG pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	systemctl enable lightdm
	systemctl enable org.cups.cupsd
	systemctl enable NetworkManager
fi

if is_opt $ISEC2; then
	remote_source que-sys-config-ec2.bash
	hostnamectl set-hostname $HOSTNAME.alerque.com
fi

if is_opt $ISVBOX; then
    systemctl enable vboxservice
fi
