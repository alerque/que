#!/usr/bin/env zsh

: ${STRAP_URL:=https://raw.github.com/alerque/que/master}

function fail () {
    echo "$@" >&2
    exit 1
}

function fail_deps () {
    fail "$1\n\nRun que-sys-bootstrap.bash as root instead.\n\nbash <(curl -sfSL $STRAP_URL/bin/que-sys-bootstrap.bash)"
}

function vcsh_get () {
    test -d .config/vcsh/repo.d/$1.git &&
    vcsh $1 pull ||
    case $2 in
        gitlab)
            vcsh clone gitlab@gitlab.alerque.com:caleb/$1.git $1
            ;;
        github|*)
            vcsh clone git@github.com:alerque/$1.git $1
            ;;
    esac
}

function auth () {
    eval $(keychain --agents gpg,ssh --ignore-missing --inherit any --eval --quick --systemd --quiet id_rsa 63CC496475267693)
}

# Error out of script if _anything_ goes wrong
set -e

# This is meant to be a user space utility, bail if we are root
test $UID -eq 0 && fail "Don't be root!"
cd $HOME

# If we don't have these tools, we should be running que-sys-bootstrap.bash instead
whence -p curl git gpg-agent keychain mr ssh-agent vcsh > /dev/null || fail_deps  "Some tools not available"

grep -q 'hook pre-merge' $(which vcsh) ||
    fail "VCSH version too old, does not have required pre-merge hook system"

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
if ! grep -q 'PRIVATE KEY' ~/.ssh/id_rsa; then
    until [[ -v BOOTSTRAP_TOKEN ]]; do
        read -s 'REPLY?Gitlab Private-Token: '
        [[ -n "$REPLY" ]] && BOOTSTRAP_TOKEN="$REPLY"
    done
    mkdir -p -m700 ~/.ssh
    (umask 177
        curl -sfSL -H "Private-Token: $BOOTSTRAP_TOKEN" \
             -o .ssh/id_rsa 'https://gitlab.alerque.com/api/v4/projects/37/repository/files/.ssh%2Fid_rsa/raw?ref=master' \
             -o .ssh/id_rsa.pub 'https://gitlab.alerque.com/api/v4/projects/37/repository/files/.ssh%2Fid_rsa.pub/raw?ref=master'
    )
    grep -q 'PRIVATE KEY' ~/.ssh/id_rsa ||
        fail "Invalid creds, got garbage files, fix /tmp/id_rsa or remove and try again"
fi

auth

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
    curl -sfSLo {,$STRAP_URL/}.config/vcsh/hooks-enabled/pre-merge-unclobber
test -f .config/vcsh/hooks-enabled/post-merge-unclobber ||
    curl -sfSLo {,$STRAP_URL/}.config/vcsh/hooks-enabled/post-merge-unclobber
chmod +x .config/vcsh/hooks-enabled/{pre,post}-merge-unclobber

# Get repo that has GPG unlock stuff
vcsh_get que-secure gitlab
vcsh run que-secure git config core.attributesfile .gitattributes.d/que-secure
chmod 644 ~/.ssh/*.pub
chmod 700 ~/.ssh ~/.gnupg{,/private-keys*/}
chmod 600 ~/.ssh/{config,authorized_keys}
echo
echo "scp .gnupg/private-keys-v1.d/{02CEA3B5FBD0521F3944535624C6670544B15F69,765C5CFB48FBC1E9038E9BCDA7916E241E9835FE}.key $HOSTNAME:.gnupg/private-keys-v1.d/"
echo
read -n "foo?Copy keys from somewhere to this machine, enter to continue when ready"
chmod 600 $(grep 'PRIVATE KEY' -Rl ~/.ssh) ~/.gnupg/private-keys*/*

auth

vcsh run que-secure git stash
vcsh run que-secure git-crypt unlock

# TODO: Test in que-secure actually got unlocked

# TODO: Fix find in AUR repo dir before it exists

# Get repo that has mr configs
vcsh_get que

# Setup permanent agent(s)
auth

# checkout everything else
mr co
