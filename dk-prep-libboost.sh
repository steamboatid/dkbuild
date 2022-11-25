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


#-- install alldev
# apt install libboost-all-dev libroscpp-core-dev


>/tmp/libboost.pkgs

lbver=$(apt-cache search libboost | grep "tools\-dev" | \
grep -iv "libboost-tools-dev" | sort -nr | head -n1 | \
sed -r 's/libboost1\.//' | cut -d'-' -f1)

apt-cache search libboost |\
grep -i "\-dev" |\
grep -i "atomic\|chrono\|date-time\|serialization\|system\|thread\|filesystem\|wave" \
>> /tmp/libboost.pkgs

apt-cache search libboost |\
grep -i "\-dev" | grep "${lbver}" |\
grep -i "atomic\|chrono\|date-time\|serialization\|system\|thread\|filesystem\|wave" \
>> /tmp/libboost.pkgs


cat /tmp/libboost.pkgs | awk '{print $1}' | sort -u > /tmp/libboost.uniq
# echo "libboost-all-dev" >> /tmp/libboost.uniq
# echo "libroscpp-core-dev" >> /tmp/libboost.uniq

cat /tmp/libboost.uniq | xargs aptnew install -fy \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"

cat /tmp/libboost.uniq | xargs apt-mark manual  2>&1 >/dev/null
