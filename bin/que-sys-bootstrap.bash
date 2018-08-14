#!/bin/bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master/bin}

while [[ $# -gt 0 ]]; do
	case $1 in
		desktop)
			ISDESKTOP=0
			;;
		debug)
			ISDEBUG=0
			;;
		echo)
			set -x
			;;
	esac
	shift
done

set -e

# Setup stuff
BASEPACKAGES=(base base-devel linux-headers zsh git ctags pcre-tools tmux mosh etckeeper ruby zip unzip myrepos vcsh wget unrar lsof htop gdisk strace ntp programmers-dvorak rsync cyrus-sasl neomutt fzf fasd cron neovim git-crypt git-annex gnupg entr markdown2ctags html-xml-utils lab-git)
DESKTOPPACKAGES=(awesome gpaste chromium google-talkplugin owncloud-client gnome rdesktop libreoffice smplayer gimp scribus inkscape xiphos transmission-gtk cups gnome-packagekit networkmanager gvfs keepass ttf-fonts ttf-symbola emojione-color-font termite pulseaudio slock xautolock compton firefox zathura)
REMOVEPACKAGES=(parcellite python-powerline-git powerline-fonts aura dropbox chromium-libpdf firefox-adblock-plus)
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

function skip_pkg () {
	if [[ "${BASEPACKAGES[@]}" =~ "$1" ]]; then
		BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
	fi
	if [[ "${COMPILEBASEPACKAGES[@]}" =~ "$1" ]]; then
		COMPILEBASEPACKAGES=(${COMPILEBASEPACKAGES[@]/%$1/})
	fi
	if [[ "${DESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
	fi
	if [[ "${COMPILEDESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		COMPILEDESKTOPPACKAGES=(${COMPILEDESKTOPPACKAGES[@]/%$1/})
	fi
}

function compile_pkg () {
	if [[ "${BASEPACKAGES[@]}" =~ "$1" ]]; then
		BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
		COMPILEBASEPACKAGES=(${COMPILEBASEPACKAGES[@]} $1)
	fi
	if [[ "${DESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
		COMPILEDESKTOPPACKAGES=(${COMPILEDESKTOPPACKAGES[@]} $1)
	fi
}

function remote_source () {
	if [ -f "$DIR/$1" ]; then
		source "$DIR/$1"
	else
		source <(curl -s -L $STRAP_URL/$1)
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
ISDO=$(dmesg | grep -q KVM; echo $?)
if is_opt $ISEC2; then
	add_pkg ec2-api-tools ec2-metadata
fi
if is_opt $ISDO; then
    compile_pkg digitalocean-synchronize
fi

WHEEL=wheel

case $DISTRO in
	ala)
		:
		;;
	arch)
		# If we have ever installed desktop stuff, assume it again
		pacman -Q awesome 2>&- >&- && ISDESKTOP=0

		add_pkg pkgstats
		add_pkg pkgbuild-introspection
		add_pkg termite-terminfo

		# Distro specific package names
		distro_pkg cron cronie
		distro_pkg pcre-tools pcre
		distro_pkg gnome lightdm gnome gnome-{extra,tweak-tool,defaults-list} cbatticon notification-daemon
		distro_pkg lightdm lightdm{,-greeter-gtk{,-settings}}
		distro_pkg pulseaudio pa{systray,man,vucontrol,prefs,mixer,-applet-git}
		distro_pkg libreoffice libreoffice-fresh{,-tr} unoconv
		distro_pkg cups cups cups-filters system-config-printer cups-pk-helper gsfonts gutenprint foomatic-{filters,db{,-engine,-nonfree}} hplip splix cups-pdf
		distro_pkg networkmanager networkmanager network-manager-applet
		distro_pkg keepass keepassxc
		distro_pkg gvfs gvfs-{mtp,smb,goa}
		distro_pkg ttf-fonts ttf-{cheapskate,freefont,gentium-{basic,plus},liberation,hack,amiri,montserrat,sil-{ezra,abyssinica,lateef}} otf-{libertinus,bravura,crimson-text}
		distro_pkg vcsh vcsh-git
		distro_pkg awesome awesome awesome-revelation-git vicious
		distro_pkg urxvt rxvt-unicode{,-terminfo}
		distro_pkg zsh zsh zsh-completions
		distro_pkg firefox firefox{,-firebug,-i18n-tr}
		distro_pkg mutt mutt-sidebar goobook-git
		distro_pkg tmux tmux teamocil
		distro_pkg zathura zathura{,-pdf-mupdf,-epub-git}

		# gvim and vim conflict, so if we are going to get the former don't try to install the latter
		distro_pkg vim {,python{,2}-}neovim

        for pkg in $(pacman -Si ${BASEPACKAGES[@]} ${DESKTOPPACKAGES[@]} 2>&1 |
            sed 's/^.*error: /error: /' |
            grep -x 'error: package .* was not found' |
            awk -F\' '{print $2}'|
            grep -vx '\(base\|base-devel\|gnome\|gnome-extra\)'); do
                compile_pkg $pkg
            done

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
		distro_pkg gpaste ''
		distro_pkg chromium ''
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

		distro_pkg vim neovim
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
	source <(curl -s -L $STRAP_URL/$INITSCRIPT)
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
echo -e "Perhaps you want home stuff too?\n    passwd caleb\n    su - caleb\n    bash <(curl -s -L $STRAP_URL/que-home-bootstrap.bash)"

if is_opt $ISDESKTOP; then
	echo "Need to manually install appropriate video driver"
fi
