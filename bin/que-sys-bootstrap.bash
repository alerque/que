#!/bin/bash

# Setup stuff

BASEPACKAGES=(zsh subversion git ctags pcre-tools vim tmux sudo mosh etckeeper)

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/$2})
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Detect distro
test -f /etc/pld-release && DISTRO=pld
#test -f /etc/ubuntu-release && DISTRO=pld # use lsb_release?
#test -f /etc/arch-release && DISTRO=arch
#test -f /etc/fedora-release && DISTRO=fedora
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala

test -n "$DISTRO" || flunk "unrecognized distro"

case $DISTRO in
	ala)
		;;
	pld)
		distro_pkg zsh zsh-completions
		distro_pkg git git-core
		distro_pkg pcre-tools pcregrep
		;;
	ubuntu)
		#distro_pkg ctags ""
		#distro_pkg etckeeper ""
		;;
	*)
		flunk "Distro $DISTRO not yet supported"
		;;
esac

# Make sure we have privs
sudo -n true || flunk "no sudo privs"

# Make sure we have dependencies the init scripts will need

# Check for network access

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
if [ -f "$DIR/$INITSCRIPT" ]; then
	source "$DIR/$INITSCRIPT"
else
	source <(curl -s -L https://raw.github.com/alerque/que/master/bin/$INITSCRIPT)
fi

# If we're on a system with etckeeper, make sure it's setup
if which etckeeper; then
	(
	cd /etc 
	sudo etckeeper vcs status || sudo etckeeper init
	sudo etckeeper commit "End of que-sys-bootstrap.bash run"
	)
fi
