#!/usr/bin/env bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master}

function fail () {
    echo "$@" >&2
    exit 1
}

function fail_deps () {
    fail "$1\n\nRun que-sys-bootstrap.bash as root instead.\n\nbash <(curl -s -L $STRAP_URL/bin/que-sys-bootstrap.bash)"
}

# Error out of script if _anything_ goes wrong
set -e

# This is meant to be a user space utility, bail if we are root
test $UID -eq 0 && fail "Don't be root!"
cd $HOME

# If we don't have these tools, we should be running que-sys-bootstrap.bash instead
which git mr curl ssh-agent vcsh > /dev/null || fail_deps  "Some tools not available"

grep -q 'hook pre-merge' $(which vcsh) ||
    fail "VCSH version too old, does not have required pre-merge hook system"

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
test -f /tmp/id_rsa || (
    umask 177
    curl --request GET \
        --header "Private-Token: $(read -s -p 'Gitlab Private-Token: ' && echo $REPLY)" \
        -o /tmp/id_rsa 'https://gitlab.alerque.com/api/v4/projects/37/repository/files/.ssh%2Fid_rsa/raw?ref=master'
)
grep -q 'PRIVATE KEY' /tmp/id_rsa ||
    fail "Invalid creds, got garbage files, fix /tmp/id_rsa or remove and try again"

eval $(ssh-agent)
ssh-add /tmp/id_rsa

# Rename repository if it exists under old name
test -d .config/vcsh/repo.d/caleb-private.git && (
    mv .config/vcsh/repo.d/{caleb-private,que-secure}.git
    mv .gitattributes.d/{caleb-private,que-secure} ||:
    mv .gitignores.d/{caleb-private,que-secure} ||:
    sed -i -e 's/caleb-private/que-secure/g' .config/vcsh/repo.d/que-secure.git/config ||:
    ) ||:

# For the sake of un-updated que repos, get hooks to handle existing files
mkdir -p .config/vcsh/hooks-enabled
test -f .config/vcsh/hooks-enabled/pre-merge-unclobber ||
    curl -L -o .config/vcsh/hooks-enabled/pre-merge-unclobber $STRAP_URL/.config/vcsh/hooks-enabled/pre-merge-unclobber
test -f .config/vcsh/hooks-enabled/post-merge-unclobber ||
    curl -L -o .config/vcsh/hooks-enabled/post-merge-unclobber $STRAP_URL/.config/vcsh/hooks-enabled/post-merge-unclobber
chmod +x .config/vcsh/hooks-enabled/{pre,post}-merge-unclobber

# mr would clone this, but it needs this to clone other things and this needs manual care on first setup
test -d .config/vcsh/repo.d/que-secure.git &&
    vcsh run que-secure git pull ||
    vcsh clone gitlab@gitlab.alerque.com:caleb/que-secure.git que-secure
vcsh run que-secure git config core.attributesfile .gitattributes.d/que-secure
chmod 700 ~/.gnupg{,/private-keys*}
chmod 600 ~/.ssh/{config,authorized_keys} $(grep 'PRIVATE KEY' -Rl ~/.ssh) ~/.gnupg/private-keys*/*

ssh-add .ssh/github
ssh-add .ssh/aur

vcsh run que-secure git crypt unlock ||:

# Get or update man repo that has mr configs
test -d .config/vcsh/repo.d/que.git &&
    vcsh que pull ||
    vcsh clone git@github.com:alerque/que.git que

# checkout everything else
mr co
