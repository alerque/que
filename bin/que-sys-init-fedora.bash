#!/bin/bash

# Make sure the system is up to date with the repos
sudo yum -y distribution-synchronization

# Get packages that we're going to want across the board
sudo yum -y install ${BASEPACKAGES[@]}
