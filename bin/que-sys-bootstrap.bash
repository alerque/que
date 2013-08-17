#!/bin/bash

# Setup stuff

BASEPACKAGES="zsh subversion vim git tmux sudo"

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Detect distro
test -f /etc/pld-release && DISTRO=pld
#test -f /etc/ubuntu-release && DISTRO=pld # use lsb_release?
#test -f /etc/arch-release && DISTRO=arch
#test -f /etc/fedora-release && DISTRO=fedora
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala

test -n "$DISTRO" || flunk "unrecognized distro"

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
