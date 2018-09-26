#!/bin/bash

# Enable sudo access to wheel group
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

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
    $DEBUG git clone https://aur.archlinux.org/yay.git
    $DEBUG cd yay
    $DEBUG makepkg -si
)

# Compile and install things not coming out of the distro main tree
$DEBUG yay --needed --noconfirm -S ${BASEPACKAGES[@]} ||:

# TODO: Need to set root login and password auth options
systemctl --now enable sshd ntpd cronie

echo 'kernel.sysrq = 1' > /etc/sysctl.d/99-sysctl.conf

if is_opt $ISDESKTOP; then
	# $DEBUG pacman -S --needed --noconfirm xf86-video-nouveau nouveau-dri
	systemctl enable lightdm org.cups.cupsd NetworkManager
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
