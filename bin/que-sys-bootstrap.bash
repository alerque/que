#!/bin/bash

# Detect distro
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala
test -f /etc/pld-release && DISTRO=pld

# Make sure we have privs
sudo -n true || exit 0

# Make sure we have dependencies the init scripts will need

# Check for network access

# Fetch and run init script for this os
bash <(curl -S -L https://raw.github.com/alerque/que/master/bin/que-sys-init-${DISTRO}.bash)
