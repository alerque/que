#!/usr/bin/env sh

sudo perl -i -pne 's/reserved="true"/               /g' /usr/lib/firefox/browser/omni.ja
find ~/.cache/mozilla/firefox -type d -name startupCache | xargs rm -rf
