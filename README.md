que
===

My personal computing environment including but not limited to system initialization tools, dotfiles, scripts and other paraphanalia.

Initialization on a fresh user directory:

	sh <(curl https://raw.github.com/alerque/que/master/bin/questrap)

Otherwise to update:

	mr up

No really, that's all.

----

Adding a new repo

1. Create config file `.config/mr/available.d/$NAME.vcsh`
2. Create sylink `cd .config/mr/config/d; ln -s ../available.d/$NAME.vcsh`
3. Add config to que repo `vcsh run que git add .config/mr/available.d/$NAME.vcsh`
4. Init repo `vcsh init`
5. `vcsh write-gitignore $NAME`
6. `vcsh run $NAME git add -f <at least one something>`
7. `vcsh run $NAME git commit`
8. Optionally add an upstream `vcsh run $NAME git remote add origin $URL`
9. Optionally add an upstream `vcsh run $NAME git push -u origin master`
