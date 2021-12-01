#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

export PHPVERS=("php8.0" "php8.1")
export PHPGREP=("php8.0\|php8.1")


source /tb2/build/dk-build-0libs.sh



cd /root/src/php

for adir in $(find . -mindepth 1 -maxdepth 1 -type d | grep -iv "php8\|xdebug"); do
	bname=$(basename $adir)
	vernum=$(echo $bname | rev | cut -d"-" -f1 | rev)
	printf "\n --- $adir -- $vernum"
done

