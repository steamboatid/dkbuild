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

delete_duplicate_dirs(){
	odir=$PWD
	adir="$1"
	cd "$adir"
	pwd

	tmpf=$(mktemp)
	for adir in $(find . -mindepth 1 -maxdepth 1 -type d | grep -iv "php8\|xdebug" | sort -nr); do
		bname=$(basename $adir)
		vernum=$(printf "$bname" | rev | cut -d"-" -f1 | rev)
		patsed=$(printf "$vernum" | sed -r 's/\+/\\+/g' | sed -r 's/\~/\\~/g')
		extname=$(printf "$bname" | sed -r "s/$patsed//")

		if [[ $extname == *"apcu"* ]] && [[ $extname != *"-bc-"* ]]; then
			dirnum=$(find . -mindepth 1 -maxdepth 1 -type d -iname "$extname*" | grep -iv "\-bc\-" | wc -l)
		else
			dirnum=$(find . -mindepth 1 -maxdepth 1 -type d -iname "$extname*" | wc -l)
		fi
		[[ $dirnum -le 1 ]] && continue;

		printf "\n --- $adir -- $vernum -- $extname "
		echo "$extname" >> $tmpf
	done

	printf "\n"
	for aext in $(cat $tmpf | sort -u | sort); do
		lastver=$(find . -mindepth 1 -maxdepth 1 -type d -iname "$aext*" | \
			sort -nr | head -n1)
		printf "\n --- $aext --- $lastver \n"

		find . -mindepth 1 -maxdepth 1 -type d -iname "$aext*" | \
			sort -nr | tail -n +2

		find . -mindepth 1 -maxdepth 1 -type d -iname "$aext*" | \
			sort -nr | tail -n +2 | xargs rm -rf
	done
	rm -rf $tmpf

	cd "$odir"
}

delete_duplicate_dirs "/root/org.src/php"
delete_duplicate_dirs "/root/org.src/php"

delete_duplicate_dirs "/root/src/php"
delete_duplicate_dirs "/root/src/php"


cd /root/src/php
for adir in $(find . -mindepth 1 -maxdepth 1 -type d | grep -iv "php8\|xdebug" | sort -nr); do
	nums=$(find -L "$adir/debian" -iname "control.in" | wc -l)
	if [[ $nums -lt 1 ]]; then
		printf "\n -- missing control.in: $adir "
	fi
done

printf "\n\n"
