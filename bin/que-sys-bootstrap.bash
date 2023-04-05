#!/bin/bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master}

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

while [[ $# -gt 0 ]]; do
	case $1 in
		devel)
			ISDEVEL=0
			;;
		remote)
			ISREMOTE=0
			;;
		caleb)
			ISCALEB=0
			;;
		desktop)
			ISDESKTOP=0
			;;
		debug)
			ISDEBUG=0
			;;
		echo)
			set -x
			;;
		*)
			flunk 'Unknown trailing arguments, try (devel|caleb|remote|desktop|debug|echo)'
			;;
	esac
	shift
done

set -e

# This environment variable will be wrong in chroots, fix it using manually set value
if [[ -f /etc/hostname ]]; then
	export HOSTNAME=$(cat /etc/hostname)
fi

# Setup stuff
BASEPACKAGES=(
		atuin
		base
		bat
		btop
		cron
		difftastic
		duf
		etckeeper
		exa
		exim
		fasd
		fd
		git
		git-crypt
		gnupg
		himalaya
		ifplugd
		iftop
		innernet
		keychain
		lsof
		man
		moreutils
		mosh
		myrepos
		ncdu
		neovim
		net-tools
		netctl
		nodejs
		openssh
		pcregrep
		programmers-dvorak
		programmers-turkish-f
		ripgrep
		rlwrap
		s-nail
		starship
		tldr
		tmux
		vcsh
		wireguard
		zsh
)

DEVELPACKAGES=(
		base-devel
		ctags
		cyrus-sasl
		entr
		fzf
		fzy
		git-delta
		git-extras
		git-filter-repo
		git-lfs
		git-revise
		github-cli
		glab
		gnu-netcat
		html-xml-utils
		lua-language-server
		markdown2ctags
		mlocate
		ntp
		rsync
		sd
		strace
		tig
		unrar
		unzip
		wget
		zip
)

DESKTOPPACKAGES=(
		cliphist
		dunst
		fuzzel
		grim
		hyprland
		hyprpaper
		otf-font-awesome
		qt6-wayland
		rofi-lbonn-wayland-git
		slurp
		swayidle
		waybar-hyprland-git
		waylock
		wayprompt-git
		wev
		wl-clipboard

		alacritty
		awesome
		bluez-tools
		brave
		chromium
		cups
		firefox
		flameshot
		geeqie
		gimp
		git-annex
		gittyup
		gnome
		gnome-packagekit
		gnome-shell
		google-chrome
		gpaste
		gvfs
		hub
		inkscape
		keepassxc
		lapce
		libreoffice
		lite-xl
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
		bashtop
		bpytop
		chromium-libpdf
		customizepkg
		diff-so-fancy
		dropbox
		emojione-color-font
		eww-wayland
		firefox-adblock-plus
		gnome-packagekit
		google-talkplugin
		gpmdp
		gtop
		gvim
		hyprsome-git
		keepass
		keepassx
		owncloud-client
		parcellite
		powerline-fonts
		python-powerline-git
		wireguard-dkms
		yaourt
		yay
		ytop
)

function add_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]} $@)
}

function remove_pkg () {
	REMOVEPACKAGES=(${REMOVEPACKAGES[@]} $1)
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/${*:2}})
	DEVELPACKAGES=(${DEVELPACKAGES[@]/%$1/${*:2}})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/${*:2}})
}

function skip_pkg () {
	if [[ "${BASEPACKAGES[@]}" =~ "$1" ]]; then
		BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
	fi
	if [[ "${DEVELPACKAGES[@]}" =~ "$1" ]]; then
		DEVELPACKAGES=(${DEVELPACKAGES[@]/%$1/})
	fi
	if [[ "${DESKTOPPACKAGES[@]}" =~ "$1" ]]; then
		DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
	fi
}

function remote_source () {
	if [ -f "$DIR/$1" ]; then
		source "$DIR/$1"
	else
		source <(curl -sfSL $STRAP_URL/bin/$1)
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
test -d /data/data/com.termux && DISTRO=termux

test -n "$DISTRO" || flunk "unrecognized distro"

# Detect virtual environments
if hash systemd-detect-virt 2> /dev/null; then
	case $(systemd-detect-virt) in
		none) ISMETAL=1 ;;
		systemd-nspawn) : ;;
		xen) ISEC2=$(uname -r | grep -iq ec2; echo $?) ;;
		kvm) ISDO=$(hash digitalocean-synchronize 2> /dev/null; echo $?) ;;
		*) flunk "Unknown virtual environment" ;;
	esac
fi
ISVBOX=$(hash lspci 2> /dev/null && lspci | grep -iq virtualbox; echo $?)
if is_opt $ISEC2; then
    add_pkg ec2-api-tools ec2-metadata
fi
if is_opt $ISDO; then
    add_pkg digitalocean-synchronize
fi

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
		# If we have ever installed devel or desktop stuff, assume them again
		pacman -Q ctags 2>&- >&- && ISDEVEL=0
		pacman -Q awesome 2>&- >&- && ISDESKTOP=0

		if grep -q ARM /etc/os-release; then
			skip_pkg git-annex
			skip_pkg starship
		else
			add_pkg mkinitcpio-{utils,netconf,dropbear}
			add_pkg reflector
		fi

		add_pkg pkgstats pacman-contrib
		add_pkg paru

		# Distro specific package names
		distro_pkg awesome awesome{,-revelation-git,-themes-git} lain-git vicious
		distro_pkg brave brave-bin
		distro_pkg cron cronie
		distro_pkg cups cups cups-filters system-config-printer cups-pk-helper gsfonts gutenprint foomatic-db{,-engine,-nonfree,{,-nonfree,-gutenprint}-ppds} hplip splix cups-pdf
		distro_pkg etckeeper etckeeper{,-packages}
		distro_pkg firefox firefox{,-i18n-{tr,ru}}
		distro_pkg geeqie geeqie-git
		distro_pkg glab glab-git
		distro_pkg gnome gnome gnome-{extra,tweak-tool,defaults-list} lightdm cbatticon notification-daemon
		distro_pkg gnome-shell gnome-shell chrome-gnome-shell gnome-shell-extension-no-title-bar
		#  gnome-shell-extension-topicons-redux
		distro_pkg gvfs gvfs-{mtp,smb,goa}
		distro_pkg libreoffice libreoffice-fresh{,-tr,-ru} unoconv
		distro_pkg lightdm lightdm{,-slick-greeter}
        distro_pkg man{,-db,-pages}
		distro_pkg neomutt neomutt goobook-git
		distro_pkg neovim neovim nodejs-neovim python-pynvim
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
	
	termux)
		;;

	*)
		flunk "Unknown system"
		;;
esac

# Make sure we are root on linux
case $(uname -o) in
	Android)
		;;
	GNU/Linux)
		test $UID -eq 0 || flunk "Must be root for system bootstrap"
		;;
esac

# Merge developer package list into base set if this is a dev box
if is_opt $ISDEVEL; then
    BASEPACKAGES=(${BASEPACKAGES[@]} ${DEVELPACKAGES[@]})
fi

# Merge desktop package list into base set if this is a desktop
if is_opt $ISDESKTOP; then
    BASEPACKAGES=(${BASEPACKAGES[@]} ${DESKTOPPACKAGES[@]})
fi

# Drop a few things from remote-only hosts
if is_opt $ISREMOTE; then
	BASEPACKAGES=(${BASEPACKAGES[@]/programmers-dvorak})
	BASEPACKAGES=(${BASEPACKAGES[@]/programmers-turkish-f})
fi

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
remote_source $INITSCRIPT

if [[ ! $DISTRO == Termux ]]; then
	# Setup root git user
	git config --global user.email root@$HOSTNAME.alerque.com
	git config --global user.name $HOSTNAME

	# Setup root SSH
	test -f /root/.ssh/id_rsa || (
		ssh-keygen -f /root/.ssh/id_rsa -N ''
		cat /root/.ssh/id_rsa.pub | mailx -s "New root SSH key for $HOSTNAME" caleb@alerque.com
	)

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
		etckeeper commit 'End of que-sys-bootstrap.bash run' || echo "Backup of system config failed, skipping..."
		)
	fi
fi

# Setup my user
if is_opt $ISCALEB; then
	useradd -m -k /dev/null caleb ||:
	usermod -s $(which zsh) caleb ||:
	usermod -c 'Caleb Maclennan' caleb ||:
	usermod -aG $WHEEL caleb ||:
fi

# For convenience show how to setup my home directory
echo -e "Perhaps you want home stuff too?\n    passwd caleb\n    su - caleb\n    zsh <(curl -sfSL $STRAP_URL/bin/que-home-bootstrap.zsh)"

if is_opt $ISDESKTOP; then
	ln -sf /usr/lib/openssh/ssh-askpass-fullscreen ~caleb/bin/ssh-askpass
	echo 'Reminder: if this is a manually configured system you need to manually install an appropriate video driver'
fi
