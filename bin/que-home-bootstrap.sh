#!/bin/sh

set -x

# Error out of script if _anything_ goes wrong
set -e

# Make sure we have the tools (otherwise we should be running a system init routine instead)
which git > /dev/null
which mr > /dev/null
which vcsh || {
	mkdir -p ~/projects
	git clone git@github.com:alerque/vcsh.git ~/projects/vcsh
	sudo ln -sf ~/projects/vcsh/vcsh /usr/local/bin/
}

# Clone the very base bit in...
cd $HOME

# TODO: setup SSH auth credentials first
if [ ! -d .ssh/ ]; then
	mkdir -p .ssh
	echo -e "Host github.com\n\tIdentityFile ~/.ssh/github\n\tStrictHostKeyChecking no\n" >> .ssh/config
	cp /tmp/ghk .ssh/github
	chmod 600 .ssh/github
	eval $(ssh-agent)
	ssh-add .ssh/github
fi

if [ ! -d .config/vcsh/repo.d/que.git ]; then
	vcsh clone git@github.com:alerque/que.git
fi

mr up

exit

## old version....

TMPDIR=$(mktemp -d $TMPDIR/XXXXXX)

# This package is for $HOME
cd

# TODO: install pre-requisits
which git || exit

git clone https://github.com/alerque/que.git $TMPDIR
rsync -avb $TMPDIR/ $HOME/ 
rm -rf $TMPDIR

#curl -#L https://github.com/alerque/que/tarball/master |
#	tar -xzv --strip-components 1
