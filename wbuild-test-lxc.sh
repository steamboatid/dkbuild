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


# read command parameter
#-------------------------------------------
# while getopts d:y:a: flag
while getopts h: flag
do
	case "${flag}" in
		h) alxc=${OPTARG};;
	esac
done

# if empty lxc, the use hostname
if [ -z "${alxc}" ]; then
	alxc="$HOSTNAME"
fi




mkdir -p /var/log/dkbuild
alog="/var/log/dkbuild/dk-$1-build-ops.log"
>$alog

printf "\n\n --- init debian -- $alxc \n"
/bin/bash /tb2/build-devomd/dk-init-debian.sh -h "$alxc"

printf "\n\n --- apt upgrade -- $alxc \n"
/bin/bash /tb2/build-devomd/dk-apt-upgrade.sh -h "$alxc"

# printf "\n\n --- fix base files -- $alxc \n"
# /bin/bash /tb2/build-devomd/dk-fix-base-files.sh -h "$alxc"

cat $alog | grep -i "fatal failed"
isfail=$(cat $alog | grep -i "fatal failed" | wc -l)
if [[ $isfail -lt 1 ]]; then
	printf "\n\n --- prep-all -- $alxc \n"
	/bin/bash /tb2/build-devomd/dk-prep-all.sh -h "$alxc"
fi

cat $alog | grep -i "fatal failed"
isfail=$(cat $alog | grep -i "fatal failed" | wc -l)
if [[ $isfail -lt 1 ]]; then
	printf "\n\n --- build-all -- $alxc \n"
	/bin/bash /tb2/build-devomd/dk-build-all.sh -h "$alxc"
fi
