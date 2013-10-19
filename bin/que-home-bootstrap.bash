#!/bin/bash

set -x

# Error out of script if _anything_ goes wrong
set -e

# Meant to be a user space utility with optional sudo
test $UID -eq 0 && exit

# Make sure we have the tools
# (otherwise we should be running a system init routine instead)
which git > /dev/null
which mr > /dev/null
grep -q vcsh-unclobber $(which vcsh) || exit;
false && {
	mkdir -p ~/projects
	test -d ~/projects/vcsh || git clone git@github.com:alerque/vcsh.git ~/projects/vcsh
	#sudo ln -sf ~/projects/vcsh/vcsh /usr/local/bin/
	#sudo cp ~/projects/vcsh/vcsh $(which vcsh)
}

# Clone the very base bit in...
cd $HOME

# Fetch private authentivation keys and such

# TODO: setup SSH auth credentials first
test -d .ssh || mkdir .ssh
test -f .ssh/id_rsa || ( umask 177 && curl --user caleb -o .ssh/id_rsa 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/id_rsa;hb=HEAD')
test -f .ssh/github || ( umask 177 && curl --user caleb -o .ssh/github 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/github;hb=HEAD')

grep -q github .ssh/config || echo -e "Host github.com\n\tIdentityFile ~/.ssh/github\n\tStrictHostKeyChecking no\n" >> .ssh/config

eval $(ssh-agent)
ssh-add .ssh/id_rsa
ssh-add .ssh/github

if [ ! -d .config/vcsh/repo.d/que.git ]; then
	vcsh clone git@github.com:alerque/que.git
fi

mr up
