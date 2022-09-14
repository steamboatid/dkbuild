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

	rm -rf $alxc/rootfs/root/.ccache
	rm -rf $alxc/rootfs/var/cache/apt/archives
	rm -rf $alxc/rootfs/root/org.src/ $alxc/rootfs/root/src
done

printf "\n\n\n"