#!/bin/bash

set -x

# Error out of script if _anything_ goes wrong
set -e

# Make sure we have the tools (otherwise we should be running a system init routine instead)
which git > /dev/null
which mr > /dev/null
which vcsh && vcsh -v 2>&1 | head -n 1 | grep -q 1.3 || {
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
