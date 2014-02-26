#!/bin/bash

export PATH=/usr/local/bin:$PATH

# To start with we need a package manager and data set ready
command -v brew || ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
brew doctor
brew update

brew install ${BASEPACKAGES[@]}
brew upgrade ${BASEPACKAGES[@]}

is_opt $ISDESKTOP && brew install ${DESKTOPPACKAGES[@]}
is_opt $ISDESKTOP && brew upgrade ${DESKTOPPACKAGES[@]}

brew linkapps
