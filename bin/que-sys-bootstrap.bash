#!/bin/bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master/}

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

# This environment variable will be wrong in chroots, fix it using manually set value
export HOSTNAME=$(cat /etc/hostname)

# Setup stuff
BASEPACKAGES=(
		anything-sync-daemon
		base
		base-devel
		bat
		cron
		ctags
		cyrus-sasl
		diff-so-fancy
		entr
		etckeeper
		exa
		exim
		fasd
		fd
		fzf
		git
		git-annex
		git-crypt
		git-extras
		git-filter-repo
		git-revise
		gnu-netcat
		gnupg
		html-xml-utils
		htop
		ifplugd
		iftop
		keychain
		lab
		linux-headers
		lsof
		man-db
		markdown2ctags
		mlocate
		moreutils
		mosh
		myrepos
		ncdu
		neomutt
		neovim
		net-tools
		netctl
		nodejs
		ntp
		openssh
		pcregrep
		programmers-dvorak
		ripgrep
		rlwrap
		rsync
		ruby
		s-nail
		strace
		termite-terminfo
		tig
		tldr
		tmux
		unrar
		unzip
		vcsh
		weechat
		wget
		wireguard
		ytop
		zip
		zsh
)

DESKTOPPACKAGES=(
		alacritty
		atom
		awesome
		bluez-tools
		chromium
		cups
		firefox
		flameshot
		geeqie
		gimp
		github-cli
		gnome
		gnome-packagekit
		gnome-shell
		google-talkplugin
		gpaste
		gvfs
		hub
		inkscape
		keepassxc
		libreoffice
		mplayer
		neovim-gtk
		nextcloud-client
		picom
		profile-sync-daemon
		pulseaudio
		scribus
		slock
		smplayer
		ssh-askpass-fullscreen
		termite
		transmission
		tridactyl
		ttf-fonts
		uim
		xautolock
		xdotool
		xiphos
		xorg-apps
		xsel
		xss-lock
		zathura
)

REMOVEPACKAGES=(
		aura
		chromium-libpdf
		customizepkg
		dropbox
		emojione-color-font
		firefox-adblock-plus
		gnome-packagekit
		gvim
		keepass
		keepassx
		owncloud-client
		parcellite
		powerline-fonts
		python-powerline-git
		yaourt
)

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
	if [[ "${DESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
	fi
}

function remote_source () {
	if [ -f "$DIR/$1" ]; then
		source "$DIR/$1"
	else
		source <(curl -s -L $STRAP_URL/bin/$1)
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
ISVBOX=$(command -v lspci > /dev/null && lspci | grep -iq virtualbox; echo $?)
ISDO=$(dmesg 2> /dev/null | grep -q KVM; echo $?)
if is_opt $ISEC2; then
	add_pkg ec2-api-tools ec2-metadata
fi
if is_opt $ISDO; then
    add_pkg digitalocean-synchronize
fi
case $(systemd-detect-virt) in
    none) ISMETAL=1 ;;
    systemd-nspawn) : ;;
    xen) ISEC2=$(uname -r | grep -iq ec2; echo $?) ;;
    *) flunk "Unknown virtual environment" ;;
esac

if is_opt $ISMETAL; then
    add_pkg gdisk
fi

# Detect system tools
mount | grep -q btrfs && add_pkg btrfs-du ||:

WHEEL=wheel

case $DISTRO in
	ala)
		:
		;;
	arch)
		# If we have ever installed desktop stuff, assume it again
		pacman -Q awesome 2>&- >&- && ISDESKTOP=0

		add_pkg pkgstats pacman-contrib
		add_pkg mkinitcpio-{utils,netconf,dropbear}
		add_pkg reflector
		add_pkg yay

		# Distro specific package names
		distro_pkg awesome awesome{,-revelation-git,-themes-git} lain-git vicious
		distro_pkg cron cronie
		distro_pkg cups cups cups-filters system-config-printer cups-pk-helper gsfonts gutenprint foomatic-db{,-engine,-nonfree,{,-nonfree,-gutenprint}-ppds} hplip splix cups-pdf
		distro_pkg etckeeper etckeeper{,-packages}
		distro_pkg firefox firefox{,-i18n-{tr,ru}}
		distro_pkg geeqie geeqie-git
		distro_pkg gnome gnome gnome-{extra,tweak-tool,defaults-list} lightdm cbatticon notification-daemon
		distro_pkg gnome-shell gnome-shell chrome-gnome-shell gnome-shell-extension-{topicons-redux,no-title-bar}
		distro_pkg gvfs gvfs-{mtp,smb,goa}
		distro_pkg libreoffice libreoffice-fresh{,-tr,-ru} unoconv
		distro_pkg lightdm lightdm{,-gtk-greeter{,-settings}}
		distro_pkg neomutt neomutt goobook-git
		distro_pkg neovim neovim nodejs-neovim python-pynvim
		distro_pkg nodejs{,-lts-erbium}
		distro_pkg nextcloud-client nextcloud-client python-nautilus
		distro_pkg pcregrep pcre
		distro_pkg pulseaudio pa{systray,vucontrol,prefs,mixer,-applet-git}
		distro_pkg tmux tmux teamocil
		distro_pkg transmission{,-gtk,-cli}
		distro_pkg tridactyl firefox-tridactyl{,-native}
		distro_pkg ttf-fonts gentium-plus-font ttf-{cheapskate,freefont,liberation,hack,amiri,sil-fonts,crimson-pro{,-variable},symbola,joypixels} otf-{libertinus,bravura,crimson-text} montserrat-font-ttf awesome-terminal-fonts nerd-fonts-hack
		distro_pkg wireguard wireguard-tools
		distro_pkg zathura zathura{,-pdf-mupdf}
		distro_pkg zsh zsh zsh-completions

		# Temporarily broken packages
		# skip_pkg ...

		# Arch Linux upstream deprecations
		remove_pkg libdmx
		remove_pkg libxxf86dga
		remove_pkg libxxf86misc
		remove_pkg transmission-sequential-{gtk,cli}

		# Renamed packages that didn't properly conflict with their replacements
		remove_pkg ttf-gentium-plus
        ;;
	fedora)
		:
	;;
	pld)
		distro_pkg git git-core
		distro_pkg gnome metapackages-gnome
		distro_pkg ruby ruby-modules
		distro_pkg zsh zsh-completions
		;;
	ubuntu)
		WHEEL=adm
		;;
	osx)
		add_pkg rename
		distro_pkg awesome ''
		distro_pkg chromium ''
		distro_pkg cups ''
		distro_pkg etckeeper ''
		distro_pkg gdisk ''
		distro_pkg gimp ''
		distro_pkg gnome ''
		distro_pkg gnome-packagekit ''
		distro_pkg google-talkplugin ''
		distro_pkg gpaste ''
		distro_pkg gvfs ''
		distro_pkg keepassx ''
		distro_pkg libreoffice ''
		distro_pkg myrepos mr
		distro_pkg ntp ''
		distro_pkg owncloud-client ''
		distro_pkg rhythmbox ''
		distro_pkg smplayer ''
		distro_pkg strace ''
		distro_pkg sudo ''
		distro_pkg syslog-ng ''
		distro_pkg transmission-gtk ''
		distro_pkg ttf-fonts ''
		distro_pkg unrar ''
		distro_pkg unzip ''
		distro_pkg xiphos ''
		distro_pkg zip ''
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

# Merge desktop package list into base set if this is a desktop
if is_opt $ISDESKTOP; then
    BASEPACKAGES=(${BASEPACKAGES[@]} ${DESKTOPPACKAGES[@]})
fi

# Setup root git user
git config --global user.email root@$HOSTNAME.alerque.com
git config --global user.name $HOSTNAME

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
remote_source $INITSCRIPT

# Setup root SSH
test -f /root/.ssh/id_rsa || (
	ssh-keygen -f /root/.ssh/id_rsa -N ''
	cat /root/.ssh/id_rsa.pub | mailx -s "New root SSH key for $HOSTNAME" caleb@alerque.com
)

# Setup my user
useradd -s $(which zsh) -m -k /dev/null -c 'Caleb Maclennan' caleb ||:
usermod -aG $WHEEL caleb ||:

# If we're on a system with etckeeper, make sure it's setup
if command -v etckeeper; then
	(
	cd /etc
	etckeeper vcs status || etckeeper init
	# TODO: setup ssh plus ssh keys and make sure remote pushes have right branch
	hostsfile=~/.ssh/known_hosts
	gitlab=gitlab.alerque.com
	[[ -s $hostsfile ]] || install -Dm644 /dev/null $hostsfile
	cat $hostsfile <(ssh-keyscan $gitlab) | sort -u | sponge $hostsfile
	etckeeper vcs remote add origin gitlab@$gitlab:hosts/$HOSTNAME.git -m master ||
		etckeeper vcs remote set-url origin gitlab@$gitlab:hosts/$HOSTNAME.git
	sed -i -e 's/^PUSH_REMOTE=""/PUSH_REMOTE="origin"/g' /etc/etckeeper/etckeeper.conf
	etckeeper vcs config --local branch.master.remote origin
	etckeeper vcs config --local branch.master.merge refs/heads/master
	etckeeper vcs config --local branch.master.rebase true
	grep -Fx .updated .gitignore || echo .updated > .gitignore
	etckeeper commit 'End of que-sys-bootstrap.bash run' ||:
	)
fi

# For convenience show how to setup my home directory
echo -e "Perhaps you want home stuff too?\n    passwd caleb\n    su - caleb\n    bash <(curl -s -L $STRAP_URL/bin/que-home-bootstrap.bash)"

if is_opt $ISDESKTOP; then
	ln -sf /usr/lib/openssh/ssh-askpass-fullscreen ~/bin/ssh-askpass
	echo 'Need to manually install appropriate video driver'
fi
