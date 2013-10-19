#!/bin/bash

set -x

# Error out of script if _anything_ goes wrong
set -e

# Meant to be a user space utility with optional sudo
test $UID -eq 0 && exit
cd $HOME

# If we don't have these tools, we shoudl be running que-sys-bootstrap.bash instead
which git mr curl ssh-agent > /dev/null

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
test -d .ssh || mkdir .ssh
test -f .ssh/id_rsa -a -f .ssh/github && grep -q github .ssh/config || (
	umask 177
	curl --user caleb \
		-o .ssh/id_rsa 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/id_rsa;hb=HEAD' \
		-o .ssh/github 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/github;hb=HEAD' \
		-o .ssh/config 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/config;hb=HEAD'
)

# Now that we have keys, setup an agent so we don't keep getting prompted
eval $(ssh-agent)
ssh-add .ssh/id_rsa
ssh-add .ssh/github

# Make sure our vcsh has my anti-clobber hack, otherwise setup a local one for this operation
which vcsh && grep -q vcsh-unclobber $(which vcsh) || {
	mkdir -p ~/projects ;
	test -f ~/projects/vcsh/vcsh || git clone git@github.com:alerque/vcsh.git ~/projects/vcsh ;
	export PATH=~/projects/vcsh:$PATH ;
}

# If we don't have a config file for me, clone it manually so we have starting point
test -f .mrconfig || vcsh clone git@github.com:alerque/que.git

mr up
