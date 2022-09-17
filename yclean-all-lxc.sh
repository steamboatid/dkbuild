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


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_bookworm
fix_apt_bookworm


cd /tb2/var-lib-lxc


lxcs=( "bus" "eye" "wor" "tbus" "teye" "twor" )

for alxc in "${lxcs[@]}"; do
	printf "\n --- $alxc "
	lxc-stop -kqn $alxc

	cd /tb2/var-lib-lxc/$alxc/rootfs
	rm -rf root/.ccache var/cache/apt/archives &
	rm -rf root/org.src root/src &
	rm -rf var/cache/apt/* var/lib/dpkg/lock var/lib/dpkg/lock-frontend \
		var/lib/dpkg/lock var/lib/dpkg/lock-frontend var/cache/debconf \
		etc/apt/preferences.d/00-revert-stable \
		var/cache/debconf var/lib/apt/lists/* \
		var/lib/dpkg/lock var/lib/dpkg/lock-frontend var/cache/debconf &

	rm -rf \
		etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service \
		etc/systemd/system/sockets.target.wants/systemd-networkd.socket \
		etc/systemd/system/dbus-org.freedesktop.network1.service \
		etc/systemd/system/multi-user.target.wants/systemd-networkd.service &

done

wait

for alxc in "${lxcs[@]}"; do
	printf "\n --- $alxc "
	lxc-start -qn $alxc
done
lxc-ls --fancy

printf "\n\n\n"