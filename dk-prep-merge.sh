#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)


# NGINX
#-------------------------------------------
echo \
'deb http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu bionic main
deb-src http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu bionic main
'>/etc/apt/sources.list.d/nginx-ppa.list

apt update

mkdir -p /root/src/nginx
cd /root/src/nginx
rm -rf /root/src/nginx/*deb

NUMDIR=$(find /root/src/nginx -mindepth 1 -maxdepth 1 -type d -iname "nginx*" | head -n1 | xargs basename 2>&1 | wc -l)
if [[ $NUMDIR -lt 1 ]]; then
	# assume no other sources
	apt source nginx libpcre3
	apt source lua-resty-core lua-resty-lrucache
fi

# NGINX-LUA
#-------------------------------------------
NUMDIR=$(find /root/src/nginx -mindepth 1 -maxdepth 1 -type d -iname "lua*" | wc -l)
if [[ $NUMDIR -lt 1 ]]; then
	apt source lua-resty-core lua-resty-lrucache
fi

# NGINX-PCRE
#-------------------------------------------
NUMDIR=$(find /root/src/nginx -mindepth 1 -maxdepth 1 -type d -iname "pcre*" | wc -l)
if [[ $NUMDIR -lt 1 ]]; then
	apt source libpcre3
fi


# PHP8
#-------------------------------------------


# KEYDB
#-------------------------------------------


# NUTCRACKER
#-------------------------------------------


apt update