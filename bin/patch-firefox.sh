#!/usr/bin/env sh

sudo perl -i -pne 's/reserved="true"/               /g' /usr/lib/firefox/browser/omni.ja
