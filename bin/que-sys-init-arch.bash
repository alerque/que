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
$DEBUG pacman -Rns --noconfirm ${REMOVEPACKAGES[@]} $(pacman -Qtdq) ||:

# Arch won't install gvim if vim is around, so to make the transition between
# package sets easier:
is_opt $ISDESKTOP && $DEBUG pacman -R --noconfirm vim ||:

# Get AUR going
$DEBUG pacman -S --needed --noconfirm base-devel

grep -q archlinuxfr /etc/pacman.conf || (
	sed -i 's#^\[extra\]$#[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch\n\n[extra]#g' /etc/pacman.conf
)
which yaourt || $DEBUG pacman -Sy --needed --noconfirm yaourt aurvote customizepkg

# Make sure the basics every system is going to need are installed and updated
$DEBUG yaourt -S --needed --noconfirm ${BASEPACKAGES[@]}
is_opt $ISDESKTOP && $DEBUG yaourt -S --needed --noconfirm ${DESKTOPPACKAGES[@]} ||:

# Detect VirtualBox guest and configure accordingly
lspci | grep -iq virtualbox && (
	$DEBUG yaourt -S --needed --noconfirm virtualbox-guest-utils
	echo -e "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
	systemctl enable vboxservice.service
	# $DEBUG yaourt -S --needed --noconfirm xf86-video-vbox
) ||:

# Arch folks disabled building packages as root in makepkg. As this is required
# for this script, patch it to work again. See Github issue for details:
#	https://github.com/archlinuxfr/yaourt/issues/67
grep -q asroot /usr/bin/makepkg || (cd / && patch -b -p0) <<"EndOfPatch"
--- /usr/bin/makepkg~
+++ /usr/bin/makepkg
@@ -3372,7 +3372,7 @@ OPT_LONG=('allsource' 'check' 'clean' 'cleanbuild' 'config:' 'force' 'geninteg'
           'help' 'holdver' 'ignorearch' 'install' 'key:' 'log' 'noarchive' 'nobuild'
           'nocolor' 'nocheck' 'nodeps' 'noextract' 'noprepare' 'nosign' 'pkg:' 'repackage'
           'rmdeps' 'sign' 'skipchecksums' 'skipinteg' 'skippgpcheck' 'source' 'syncdeps'
-          'verifysource' 'version')
+          'verifysource' 'version' 'asroot')
 
 # Pacman Options
 OPT_LONG+=('asdeps' 'noconfirm' 'needed' 'noprogressbar')
@@ -3580,11 +3580,7 @@ PACKAGER=${_PACKAGER:-$PACKAGER}
 CARCH=${_CARCH:-$CARCH}
 
 if (( ! INFAKEROOT )); then
-	if (( EUID == 0 )); then
-		error "$(gettext "Running %s as root is not allowed as it can cause permanent,\n\
-catastrophic damage to your system.")" "makepkg"
-		exit 1 # $E_USER_ABORT
-	fi
+	:
 else
 	if [[ -z $FAKEROOTKEY ]]; then
 		error "$(gettext "Do not use the %s option. This option is only for use by %s.")" "'-F'" "makepkg"
EndOfPatch

# Compile and install things not coming out of the distro main tree
for PKG in ${COMPILEBASEPACKAGES[@]} ; do
    $DEBUG yaourt --noconfirm -S --needed $PKG ||:
done
for PKG in ${COMPILEDESKTOPPACKAGES[@]} ; do
    is_opt $ISDESKTOP && $DEBUG yaourt --noconfirm -S --needed $PKG ||:
done

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
