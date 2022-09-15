#!/bin/bash
set -e

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

export PHPVERS=("php8.0" "php8.1")
export PHPGREP="php8.0\|php8.1"


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_bookworm
fix_apt_bookworm




rm -rf /root/org.src /root/src

>/tmp/zdev.txt
/bin/bash /tb2/build-devomd/dk-prep-core-php8.sh 2>&1 | tee -a /tmp/zdev.txt
/bin/bash /tb2/build-devomd/dk-prep-deps-php8.sh 2>&1 | tee -a /tmp/zdev.txt

printf "\n\n"
cat /tmp/zdev.txt | grep -i unable

dsc_num=$(find /root/org.src/php -maxdepth 1 -type f -iname "*.dsc" | grep -iv "xmlrpc" | wc -l)
dir_num=$(find /root/org.src/php -maxdepth 1 -type d | wc -l)
printf "\n\n\n --- DSC=${blue}$dsc_num ${end} --- DIR=${blue}$dir_num ${end} \n\n"

