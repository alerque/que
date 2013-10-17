#!/bin/bash

# Freshen everything up
sudo pacman -Syu

# Make sure the basics every system is going to need are installed and updated
sudo pacman -Sy ${BASEPACKAGES[@]}
