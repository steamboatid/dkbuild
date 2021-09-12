#!/bin/bash


apt update
apt install -fy lsb-release

export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)


#-- killing first
killall -9 php php8.0-fpm nginx keydb-server nutcracker >/dev/null 2>&1
killall -9 php php8.0-fpm nginx keydb-server nutcracker >/dev/null 2>&1
systemctl stop keydb-server
systemctl stop nutcracker
systemctl stop php8.0-fpm
systemctl stop nginx

#-- remove first
cd `mktemp -d`; \
apt remove php* nginx* nutcracker* keydb* -fy
rm -rf /etc/php/ /usr/lib/php/ /etc/keydb /etc/nginx /etc/nutcracker
sleep 0.5

#-- installing dependencies
apt install -fy --fix-broken libxml2 libsodium23 libzip4 libcurl4 ucf procps bison flex
apt install -fy --fix-broken


cd /tb2/build/$RELNAME-all

find /tb2/build/$RELNAME-all -name "*udeb" -delete

#-- NGINX
dpkg --force-all -i lua*deb libpcre*deb pcre*deb \
nginx-common*deb nginx-extras*deb libnginx*deb \
keydb-*deb nutcracker*deb || apt install -fy --allow-downgrades
apt install -fy --fix-broken  --allow-downgrades --allow-change-held-packages


#-- PHP
dpkg --force-all -i php8*deb php-common*deb || apt install -fy --allow-downgrades
apt install -fy --fix-broken  --allow-downgrades --allow-change-held-packages

#-- check
php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
NUMEXT=$(php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
if [[ $NUMEXT -lt 8 ]]; then printf "\n\n\t php ext:NOT OK\n\n"; else printf "\n\n\t php ext: OK\n\n"; fi
