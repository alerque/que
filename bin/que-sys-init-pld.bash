#!/bin/bash

# Find out some basics about the system
tree=$(cat /etc/pld-release | cut -d\( -f2 | cut -c1-2 | tr [:upper:] [:lower:])

# Setup poldek repositories
#grep -q caleb /etc/poldek/source.conf ||
#	echo "\n[source]\nname    = caleb\ntype    = pndir\npath    = http://rpms.alerque.com/dists/${tree}/\nauto    = yes\nautoup  = yes" >> /etc/poldek/source.conf

#which ex > /dev/null || poldek -iv vim-static && ex -u NONE "+:%s!^_prefix.*!_prefix = http://pld.ouraynet.com/dists/${tree}!g" "+:x" /etc/poldek/pld-source.conf

# Freshen everything up
sudo poldek --noask -n ${tree} --upgrade-dist

# Make sure the basics every system is going to need are installed and updated
sudo poldek --noask -n ${tree} -iv ${BASEPACKAGES[@]} glibc-localedb-all iputils-ping man

# TODO: ssh-askpass-fullscreen slock awesome

# TODO: build vcsh, mr, git-annex -r standalone

# Set suid bit on ping so users can use it!
sudo chmod 755 /bin/ping
sudo chmod u+s /bin/ping

# Fix shell display code so that it work in zsh.
# FIXME: for Pete's sakes do this with a sed!
# FIXME: commented do to switch to bash for bootstrap env
#grep -n '==' /etc/rc.d/init.d/functions |
#	grep tput |
#	cut -d: -f1 |
#	read line && sudo ex -u NONE "+:${line}s/==/=/g" "+:x" /etc/rc.d/init.d/functions

#test -d ~/rpm || builder --init-rpm-dir
