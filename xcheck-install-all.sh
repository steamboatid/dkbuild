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

MYFILE=$(which $0)
MYDIR=$(realpath $(dirname $MYFILE))


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm



printf "\n\n\n TBUS \n"
lxc-attach -n tbus -- /bin/bash /tb2/build-devomd/dk-install-check.sh

printf "\n\n\n TEYE \n"
lxc-attach -n teye -- /bin/bash /tb2/build-devomd/dk-install-check.sh

# printf "\n\n\n TWOR \n"
# lxc-attach -n twor -- /bin/bash /tb2/build-devomd/dk-install-check.sh



printf "\n\n done. \n\n"
