que
===

My personal computing environment including but not limited to system initialization tools, dotfiles, scripts and other paraphanalia.

system setup
------------

Requires:

* bash, curl
* working network connection
* booted and logged in as user with sudo privs

Setup a fresh system from scratch (or update an existing one):

	bash <(curl -s -L https://raw.github.com/alerque/que/master/bin/que-sys-bootstrap.bash)

home setup
----------

Initialization on a fresh user directory:

	bash <(curl -s -L https://raw.github.com/alerque/que/master/bin/que-home-bootstrap.bash)

Otherwise to update:

	mr up

No really, that's all.

usage
-----

Adding a new repo

1. Create config file `.config/mr/available.d/$NAME.vcsh`
2. Create sylink `cd .config/mr/config/d; ln -s ../available.d/$NAME.vcsh`
3. Add config to que repo `vcsh run que git add .config/mr/available.d/$NAME.vcsh`
4. Init repo `vcsh init $NAME`
5. Setup ignores `vcsh write-gitignore $NAME`
6. Add something to get the repo off the ground `vcsh run $NAME git add -f <at least one something>`
7. Commit so we actually have a repo`vcsh run $NAME git commit -m "initial commit"`
8. Optionally add an upstream `vcsh run $NAME git remote add origin $URL`
9. Optionally push to upstream `vcsh run $NAME git push -u origin master`

After that, the usual `mr up`, `mr ci`, `mr push` etc should just work.
