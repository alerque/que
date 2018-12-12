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
which git mr curl ssh-agent vcsh > /dev/null ||
    fail "Necessary tools not available, run que-sys-bootstrap.bash as root instead.\n\nbash <(curl -s -L $STRAP_URL/bin/que-sys-bootstrap.bash)"

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
test -d .ssh || mkdir .ssh ; chmod 750 .ssh
(umask 177
	test -f .ssh/id_rsa -a -f .ssh/github && grep -q github .ssh/config || (
        curl --request GET --header "Private-Token: $(read -s -p 'Gitlab Private-Token: ' && echo $REPLY)" \
            -o .ssh/id_rsa      'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fid_rsa' \
            -o .ssh/id_rsa.pub  'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fid_rsa.pub' \
            -o .ssh/github      'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fgithub' \
            -o .ssh/known_hosts 'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fknown_hosts' \
            -o .ssh/config      'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fconfig'
	)
    grep -q github.com .ssh/config || fail "Invalid creds, got garbage files"
	test -f .ssh/authorized_keys || cp .ssh/{id_rsa.pub,authorized_keys}
)

# Now that we have keys, setup an agent so we don't keep getting prompted
eval $(ssh-agent)
ssh-add .ssh/id_rsa
ssh-add .ssh/github

grep -q 'hook pre-merge' $(which vcsh) ||
    fail "VCSH version too old, does not have required pre-merge hook system"

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
chmod 600 .ssh/{config,authorized_keys} $(grep 'PRIVATE KEY' -Rl .ssh)

mr up
