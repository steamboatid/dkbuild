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
	vernum=$(printf "$bname" | rev | cut -d"-" -f1 | rev)
	patsed=$(printf "$vernum" | sed -r 's/\+/\\+/g' | sed -r 's/\~/\\~/g')
	extname=$(printf "$bname" | sed -r "s/$patsed//")

	dirnum=$(find . -mindepth 1 -maxdepth 1 -type d -iname "$extname*" | wc -l)
	[[ $dirnum -le 1 ]] && continue;

	printf "\n --- $adir -- $vernum -- $extname"

	find . -mindepth 1 -maxdepth 1 -type d -iname "$extname-*" | sort -nr | tail -n +2
	# find . -mindepth 1 -maxdepth 1 -type d -iname "$extname-*" | sort -nr | tail -n +2 | xargs rm -rf
done

printf "\n\n"
