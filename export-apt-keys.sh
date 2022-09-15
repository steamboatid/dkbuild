#!/bin/bash


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_bookworm
fix_apt_bookworm

#-- kill prev apts
ps auxw | grep -v grep | grep "apt-key add\|gpg" | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
sleep 0.2
ps auxw | grep -v grep | grep "apt-key add\|gpg" | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
sleep 0.2

#-- delete empty files
find -L /etc/apt/trusted.gpg.d -type f -empty -delete
find -L /etc/apt/trusted.gpg.d -type f -name ".#*" -delete
find -L /etc/apt/trusted.gpg.d -type f -name "*gpg~" -delete
chmod -x /etc/apt/trusted.gpg.d/*

#-- apt install
printf "\n --- apt install: gnupg2 apt-utils tzdata curl "
aptold install -yf gnupg2 apt-utils tzdata curl \
	2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

#-- fetch from repo.omd.id
# printf "\n --- fetch from repo.omd.id \n"
# apt-key adv --fetch-keys http://repo.omd.id/trusted-keys \
# 	2>&1 | grep --color -i "processed"

#-- import from /etc/apt/trusted.gpg.d
printf "\n\n --- import from /etc/apt/trusted.gpg.d \n"
for afile in $(find -L /etc/apt/trusted.gpg.d -type f); do
	printf " --- File: $afile --- \n"
	# cat $afile | apt-key add 2>&1 | grep -v "Warning"
	cat $afile | apt-key add >/dev/null 2>&1 &
	sleep 0.1
done

#-- import from /usr/share/keyrings
printf "\n\n --- import from /usr/share/keyrings \n"
for afile in $(find -L /usr/share/keyrings -type f -iname "*.gpg"); do
	if [[ $afile == *"debian"* ]] || [[ $afile == *"dbg"* ]] || [[ $afile == *"sym"* ]]; then
		continue
	fi
	printf " --- File: $afile --- \n"

	# cat $afile | apt-key add 2>&1 | grep -v "Warning"
	cat $afile | apt-key add >/dev/null 2>&1 &
	sleep 0.1
done


#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n --- wait for all background process...  [$bname] "
wait_backs_wpatt "apt-key"
printf "\n\n --- wait finished... \n\n\n"


printf "\n\n exporting... \n"
sleep 0.5
apt-key exportall > ./trusted-keys; \
ls -lah ./trusted-keys

LOCSIZE=$(ls -la ./trusted-keys | cut -d' ' -f5)
OMDSIZE=$(ssh devomd -C "ls -la /tb2/phideb/trusted-keys | cut -d' ' -f5")
OMDSIZE2=$(( $OMDSIZE * 2 ))

printf "\n\n SIZES: local=$LOCSIZE omd=$OMDSIZE \n"
if [[ $LOCSIZE -gt $OMDSIZE ]] && [[ $LOCSIZE -lt $OMDSIZE2 ]]; then
	scp ./trusted-keys devomd:/tb2/phideb/
	scp ./trusted-keys omd:/tb2/phideb/
fi

printf "\n\n"
