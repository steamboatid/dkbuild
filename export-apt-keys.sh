#!/bin/bash


#-- delete empty files
find /etc/apt/trusted.gpg.d -type f -empty -delete
find /etc/apt/trusted.gpg.d -type f -name ".#*" -delete
find /etc/apt/trusted.gpg.d -type f -name "*gpg~" -delete
chmod -x /etc/apt/trusted.gpg.d/*

#-- apt install
printf "\n apt install"
apt install -yf gnupg2 apt-utils tzdata curl

#-- fetch from repo.aisits.id
printf "\n fetch from repo.aisits.id"
apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys 2>&1 | grep -v "not changed"

find /etc/apt/trusted.gpg.d -type f |
while read afile; do
	printf "\n File: $afile --- "
	apt-key add $afile
	sleep 0.1
done

printf "\n\n exporting... \n"
sleep 0.5
apt-key exportall > ./trusted-keys
ls -la ./trusted-keys

LOCSIZE=$(ls -la ./trusted-keys | cut -d' ' -f5)
ARGOSIZE=$(ssh argo -C "ls -la /w3repo/trusted-keys | cut -d' ' -f5")

printf "\n\n SIZES: local=$LOCSIZE argo=$ARGOSIZE \n"
if [[ $LOCSIZE -gt $ARGOSIZE ]]; then
	scp ./trusted-keys argo:/w3repo/
fi

printf "\n\n"
