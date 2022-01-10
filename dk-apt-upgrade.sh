#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh




# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



systemctl daemon-reload; \
systemctl restart systemd-resolved.service; \
systemctl restart systemd-timesyncd.service; \
killall -9 apt; sleep 1; killall -9 apt; \
killall -9 apt; sleep 1; killall -9 apt


find /var/lib/apt/lists/ -type f -delete; \
find /var/cache/apt/ -type f -delete; \
rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
/etc/apt/preferences.d/00-revert-stable \
/var/cache/debconf/ /var/lib/apt/lists/* \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
mkdir -p /root/.local/share/nano/ /root/.config/procps/

apt autoclean
apt clean
apt update --allow-unauthenticated

aptold full-upgrade --auto-remove --purge --fix-missing -fy \
  -o Dpkg::Options::="--force-overwrite"
