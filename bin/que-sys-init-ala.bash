#!/bin/bash

# Make sure the system is up to date with the repos
sudo yum -y distribution-synchronization

# Enable extra repros
sudo sed -i 's/^enabled=0$/enabled=1/g' /etc/yum.repos.d/epel.repo

# Get packages that we're going to want across the board
sudo yum -y install ${BASEPACKAGES[@]}

if [[ $IS_EC2 ]]; then
	source <(curl -s -L https://raw.github.com/alerque/que/master/bin/que-sys-config-ec2.bash)                       

	sudo sed -i -e "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME.alerque.com/g" /etc/sysconfig/network
	sudo hostname $HOSTNAME.alerque.com
fi
