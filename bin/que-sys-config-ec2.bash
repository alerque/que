#!/bin/bash

if [[ $IS_VBOX ]]; then
	# (Uses que user that has read only permission to access tags on my EC2 account)
	export HOSTNAME=$(ec2-describe-tags \
			--aws-access-key AKIAIMSI2QP22SMUTUVQ \
			--aws-secret-key 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 \
			--filter "resource-type=instance" \
			--filter "resource-id=$(ec2-metadata -i | cut -d ' ' -f2)" \
			--filter "key=Name" | cut -f5)
fi
