#!/usr/bin/env bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master}

function fail () {
    echo "$@" >&2
    exit 1
}

# Error out of script if _anything_ goes wrong
set -e

# This is meant to be a user space utility, bail if we are root
test $UID -eq 0 && fail "Don't be root!"
cd $HOME

# If we don't have these tools, we should be running que-sys-bootstrap.bash instead
which git mr curl ssh-agent > /dev/null ||
    fail "Necessary tools not available, run que-sys-bootstrap.bash instead"

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
test -d .ssh || mkdir .ssh ; chmod 750 .ssh
(umask 177
	test -f .ssh/id_rsa -a -f .ssh/github && grep -q github .ssh/config || (
		curl --user caleb \
			-o .ssh/id_rsa 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/id_rsa;hb=HEAD' \
			-o .ssh/id_rsa.pub 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/id_rsa.pub;hb=HEAD' \
			-o .ssh/github 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/github;hb=HEAD' \
			-o .ssh/known_hosts 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/known_hosts;hb=HEAD' \
			-o .ssh/config 'http://git.alerque.com/?p=caleb-private.git;a=blob_plain;f=.ssh/config;hb=HEAD'
	)
    grep -q github.com .ssh/config || fail "Invalid creds, got garbage files"
	test -f .ssh/authorized_keys || cp .ssh/{id_rsa.pub,authorized_keys}
)

# Now that we have keys, setup an agent so we don't keep getting prompted
eval $(ssh-agent)
ssh-add .ssh/id_rsa
ssh-add .ssh/github

# Make sure our vcsh has the hooks necessary for my anti-clobber hack,
# otherwise checkout and use a local one for this operation
which vcsh && grep -q 'hook pre-merge' $(which vcsh) || {
	mkdir -p ~/projects
	test -f ~/projects/vcsh/vcsh || git clone git@github.com:alerque/vcsh.git ~/projects/vcsh
	export PATH="~/projects/vcsh:$PATH"
}

test -d .config/vcsh/repo.d/que.git || vcsh clone git@github.com:alerque/que.git

# For the sake of un-updated que repos, get hooks we want to use on mr's initial clones
if test -d .config/vcsh; then
    mkdir -p .config/vcsh/hooks-enabled
    test -f .config/vcsh/hooks-enabled/pre-merge-unclobber ||
        curl -L -o .config/vcsh/hooks-enabled/pre-merge-unclobber $STRAP_URL/.config/vcsh/hooks-enabled/pre-merge-unclobber
    test -f .config/vcsh/hooks-enabled/post-merge-unclobber ||
        curl -L -o .config/vcsh/hooks-enabled/post-merge-unclobber $STRAP_URL/.config/vcsh/hooks-enabled/post-merge-unclobber
    chmod +x .config/vcsh/hooks-enabled/{pre,post}-merge-unclobber
fi

# Patch up SSH private key permissions
( echo ".ssh/config .ssh/authorized_keys"; grep 'PRIVATE KEY' -Rl .ssh ) | while read f; do chmod 600 $f; done

mr up
