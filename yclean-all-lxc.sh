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
fix_relname_relver_bookworm
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
sleep 1
/etc/init.d/squid restart


printf "\n\n\n\n --------- INIT DEBIAN \n"
while :; do
	>/tmp/init-clean.log
	for alxc in "${lxcs[@]}"; do
		printf "\n --- INIT DEBIAN: $alxc "
		lxc-start -qn $alxc
		sleep 1
		lxc-attach -n $alxc -- reset
		lxc-attach -n $alxc -- bash /tb2/build-devomd/dk-init-debian.sh 2>&1 | tee -a /tmp/init-clean.log &
	done
	lxc-ls --fancy

	wait
	sleep 1

	cat /tmp/init-clean.log | grep -i "setting up \|unpacking\|preparing"
	newp=$(cat /tmp/init-clean.log | grep -i "setting up \|unpacking\|preparing" | wc -l)
	if [[ $newp -lt 1 ]]; then break; fi
	sleep 1
done

printf "\n\n\n"