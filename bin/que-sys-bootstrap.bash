#!/bin/bash

while [[ $# -gt 0 ]]; do
    case $1 in
        desktop)
            ISDESKTOP=0
            ;;
        debug)
            ISDEBUG=0
            ;;
    esac
    shift
done

# Setup stuff
BASEPACKAGES=(zsh subversion git ctags pcre-tools vim tmux sudo mosh etckeeper ruby zip unzip myrepos vcsh wget unrar syslog-ng lsof htop gdisk strace ntp keychain programmers-dvorak rsync)
DESKTOPPACKAGES=(awesome dropbox parcellite chromium flashplugin google-talkplugin owncloud-client gnome rdesktop libreoffice smplayer gimp xiphos transmission-gtk rhythmbox cups gnome-packagekit networkmanager gvfs keepassx ttf-fonts ssh-askpass-fullscreen powerline gvim urxvt pulseaudio slock xautolock compton)
REMOVEPACKAGES=(powerline-fonts-git chromium-pepper-flash-stable aura)
COMPILEBASEPACKAGES=()
COMPILEDESKTOPPACKAGES=()

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

function add_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]} $@)
}

function remove_pkg () {
    REMOVEPACKAGES=(${REMOVEPACKAGES[@]} $1)
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/${*:2}})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/${*:2}})
}

function compile_pkg () {
	if [[ "${BASEPACKAGES[@]}" =~ "$1" ]]; then
		BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
		COMPILEBASEPACKAGES=(${COMPILEBASEPACKAGES[@]} $1)
	fi
}

function compile_desktop_pkg () {
	if [[ "${DESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
		COMPILEDESKTOPPACKAGES=(${COMPILEDESKTOPPACKAGES[@]} $1)
	fi
}

function remote_source () {
	if [ -f "$DIR/$1" ]; then
		source "$DIR/$1"
	else
		source <(curl -s -L https://raw.github.com/alerque/que/master/bin/$1)
	fi
}

is_opt () {
	(( ! ${1:-1} ))
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Detect distro
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala
test -f /etc/arch-release && DISTRO=arch
test -f /etc/fedora-release && DISTRO=fedora
test -f /etc/pld-release && DISTRO=pld
grep -q -s "Ubuntu" /etc/lsb-release && DISTRO=ubuntu
uname -s | grep -q Darwin && DISTRO=osx

test -n "$DISTRO" || flunk "unrecognized distro"

# Detect virtual environments
ISVBOX=$(command -v lspci && lspci | grep -iq virtualbox; echo $?)
ISEC2=$(uname -r | grep -iq ec2; echo $?)
if is_opt $ISEC2; then
	add_pkg ec2-api-tools ec2-metadata
fi

WHEEL=wheel

case $DISTRO in
	ala)
		:
		;;
	arch)
        # If we have ever installed desktop stuff, assume it again
        pacman -Q gvim 2>&- >&- && ISDESKTOP=0

		add_pkg pkgstats
		add_pkg pkgbuild-introspection

		distro_pkg pcre-tools pcre
		distro_pkg flashplugin chromium-pepper-flash
		distro_pkg chromium chromium chromium-libpdf
		distro_pkg gnome gnome gnome-{extra,tweak-tool,shell-extension-maximus,defaults-list} batti notification-daemon 
		distro_pkg pulseaudio pulseaudio-gnome pa{systray,man,vucontrol,prefs,mixer,-applet}
		distro_pkg libreoffice libreoffice-{gnome,en-US,writer,calc,impress,math,draw} unoconv
		distro_pkg cups cups cups-filters system-config-printer cups-pk-helper gsfonts gutenprint foomatic-{filters,db{,-engine,-nonfree}} hplip splix cups-pdf
		distro_pkg networkmanager networkmanager network-manager-applet
		distro_pkg keepassx keepassx2
		distro_pkg gvfs gvfs-{mtp,smb,goa,afp}
		distro_pkg xiphos ""
		distro_pkg ttf-fonts ttf-{cheapskate,droid,freefont,gentium,liberation,linux-libertine}
        distro_pkg powerline python-powerline-git powerline-fonts python2-powerline-fontpatcher-git
        distro_pkg vcsh vcsh-git
        distro_pkg awesome awesome awesome-gnome eminent-git awesome-revelation-git lua-oocairo vicious
        distro_pkg urxvt rxvt-unicode{,-terminfo}
		distro_pkg zsh zsh zsh-completions

        # gvim and vim conflict, so if we are going to get the former don't try to install the latter
        is_opt $ISDESKTOP && distro_pkg gvim "" && distro_pkg vim gvim

		compile_pkg etckeeper
		compile_pkg vcsh-git
		compile_pkg myrepos
		compile_pkg ec2-api-tools
		compile_pkg ec2-metadata
		compile_pkg programmers-dvorak

		compile_desktop_pkg chromium-pepper-flash
		compile_desktop_pkg compton
		compile_desktop_pkg owncloud-client
		compile_desktop_pkg keepassx2
		compile_desktop_pkg xiphos
		compile_desktop_pkg google-talkplugin
		compile_desktop_pkg dropbox
		compile_desktop_pkg google-chrome
		compile_desktop_pkg gnome-shell-extension-maximus
		compile_desktop_pkg gnome-defaults-list
        compile_desktop_pkg python-powerline-git
        compile_desktop_pkg python2-powerline-fontpatcher-git
        compile_desktop_pkg powerline-fonts

        distro_pkg syslog-ng ''

        remove_pkg mr
		;;
	fedora)
		:
	;;
	pld)
		distro_pkg zsh zsh-completions
		distro_pkg git git-core
		distro_pkg pcre-tools pcregrep
		distro_pkg ruby ruby-modules
		distro_pkg gnome metapackages-gnome
		;;
	ubuntu)
		WHEEL=adm
		distro_pkg pcre-tools pcregrep
		;;
	osx)
		add_pkg rename
		distro_pkg myrepos mr
        distro_pkg pcre-tools pcre
        distro_pkg sudo ''
        distro_pkg etckeeper ''
        distro_pkg unzip ''
        distro_pkg unrar ''
        distro_pkg zip ''
        distro_pkg syslog-ng ''
        distro_pkg gdisk ''
        distro_pkg strace ''
        distro_pkg ntp ''

        distro_pkg awesome ''
        distro_pkg dropbox ''
        distro_pkg parcellite ''
        distro_pkg chromium ''
        distro_pkg flashplugin ''
        distro_pkg google-talkplugin ''
        distro_pkg owncloud-client ''
        distro_pkg gnome-packagekit ''
        distro_pkg gnome ''
        distro_pkg rdesktop ''
        distro_pkg libreoffice ''
        distro_pkg smplayer ''
        distro_pkg gimp ''
        distro_pkg xiphos ''
        distro_pkg transmission-gtk ''
        distro_pkg rhythmbox ''
        distro_pkg cups ''
        distro_pkg networkmanager ''
        distro_pkg gvfs ''
        distro_pkg keepassx ''
        distro_pkg ttf-fonts ''
        distro_pkg x11-ssh-askpass ''
        distro_pkg powerline-fonts ''

        distro_pkg gvim macvim
		;;
	*)
		flunk "Unknown system"
		;;
esac

# Make sure we are root on linux
case $(uname -s) in
    Linux)
        test $UID -eq 0 || flunk "Must be root for system bootstrap"
        ;;
esac

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
if [ -f "$DIR/$INITSCRIPT" ]; then
	source "$DIR/$INITSCRIPT"
else
	source <(curl -s -L https://raw.github.com/alerque/que/master/bin/$INITSCRIPT)
fi

# Setup my user
useradd -s $(which zsh) -m -k /dev/null -c "Caleb Maclennan" caleb
usermod -aG $WHEEL caleb

# TODO make sure wheel has sudo permissions

# If we're on a system with etckeeper, make sure it's setup
if command -v etckeeper; then
	(
	cd /etc 
	etckeeper vcs status || etckeeper init
	etckeeper commit "End of que-sys-bootstrap.bash run"
	)
fi

# For convenience show how to setup my home directory
echo -e "Perhaps you want home stuff too?\n    passwd caleb\n    su - caleb\n    bash <(curl -s -L https://raw.github.com/alerque/que/master/bin/que-home-bootstrap.bash)"

if is_opt $ISDESKTOP; then
	echo "Need to manually install appropriate video driver"
fi
