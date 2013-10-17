#!/bin/bash

# Freshen everything up
sudo pacman -Syu --needed --noconfirm

# Make sure the basics every system is going to need are installed and updated
sudo pacman -Su --needed --noconfirm ${BASEPACKAGES[@]}
