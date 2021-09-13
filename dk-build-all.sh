#!/bin/bash


apt update
apt install -fy lsb-release

export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)


doback(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n\n"
	sleep 1
}

doback /tb2/build/dk-build-nutcracker.sh &
doback /tb2/build/dk-build-keydb.sh &
doback /tb2/build/dk-build-pcre.sh &
doback /tb2/build/dk-build-lua-resty-lrucache.sh &
doback /tb2/build/dk-build-lua-resty-core.sh &

/tb2/build/dk-build-nginx.sh
printf "\n\n\n"
sleep 1

/tb2/build/dk-build-php8.sh
printf "\n\n\n"
sleep 1


find /root/src -type f -iname "*udeb" -delete
find /root/src -type f -iname "*dbgsym*deb" -delete


#--- delete old debs
mkdir -p /tb2/build/$RELNAME-all
rm -rf /tb2/build/$RELNAME-all/*deb


printf "\n\n\n-- copying files \n"

find /root/src -type f -name "*deb" |
while read afile; do
	cp $afile /tb2/build/$RELNAME-all/ -fv
done
printf "\n\n"
