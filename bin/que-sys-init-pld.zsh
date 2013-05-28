#!/bin/zsh

# Make sure this is sane
[ -f "/etc/pld-release" ] || exit

# Find out some basics about the system
cat /etc/pld-release | cut -d\( -f2 | cut -c1-2 | read tree

# Setup poldek repositories
#grep -q caleb /etc/poldek/source.conf ||
#	echo "\n[source]\nname    = caleb\ntype    = pndir\npath    = http://rpms.alerque.com/dists/${tree:l}/\nauto    = yes\nautoup  = yes" >> /etc/poldek/source.conf

#which ex > /dev/null || poldek -iv vim-static && ex -u NONE "+:%s!^_prefix.*!_prefix = http://pld.ouraynet.com/dists/${tree:l}!g" "+:x" /etc/poldek/pld-source.conf

# Make sure the basics every system is going to need are installed and updated
poldek -n ${tree:l} -iv vim vim-static sudo screen zsh-completions subversion pcregrep glibc-localedb-all ctags iputils-ping

# TODO: build vcsh, mr, git-annex -r standalone

# Set suid bit on ping so users can use it!
sudo chmod 755 /bin/ping
sudo chmod u+s /bin/ping

# Fix shell display code so that it work in zsh.
grep -n '==' /etc/rc.d/init.d/functions |
	grep tput |
	cut -d: -f1 |
	read line && sudo ex -u NONE "+:${line}s/==/=/g" "+:x" /etc/rc.d/init.d/functions

test -d ~/rpm || builder --init-rpm-dir
