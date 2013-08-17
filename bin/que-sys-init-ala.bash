#!/bin/bash

# Figure out and set our hostname based on the EC2 instance name
# (Uses que user that has read only permission to access tags on my EC2 account)
HOSTNAME=$(ec2-describe-tags \
		--aws-access-key AKIAIMSI2QP22SMUTUVQ \
		--aws-secret-key 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 \
		--filter "resource-type=instance" \
		--filter "resource-id=$(ec2-metadata -i | cut -d ' ' -f2)" \
		--filter "key=Name" | cut -f5)

sudo sed -i -e "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME.alerque.com/g" /etc/sysconfig/network
sudo hostname $HOSTNAME.alerque.com

# Make sure the system is up to date with the repos
sudo yum -y distribution-synchronization

# Get packages that we're going to want across the board
sudo yum -y install $BASEPACKAGES git ctags pcre-tools
