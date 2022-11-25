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

export PHPVERS=("php8.1")
export PHPGREP="php8.1"
export ERRFIX=0


source /tb2/build-devomd/dk-build-1libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm



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

fix_controls_rules(){
	for adir in $(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d | \
		grep -v "git-phpredis\|libzip\|libgd\|libxml" | sort -n); do

		cd $adir

		# temporary solution
		if [[ $adir == *"http"* ]]; then
			fix_php_pecl_http "$adir"
		fi
		if [[ $adir == *"lz4"* ]]; then
			fix_php_lz4 "$adir"
		fi
		if [[ $adir == *"phalcon3"* ]]; then
			fix_php_phalcon3 "$adir"
		fi
		if [[ $adir == *"pinba"* ]]; then
			fix_php_pinba "$adir"
		fi
		if [[ $adir == *"imagick"* ]]; then
			fix_php_imagick "$adir"
		fi
		if [[ $adir == *"-ps-"* ]] && [[ $adir == *"1.4.1"* ]]; then
			fix_php_ps "$adir"
		fi

		#---
		if [[ $adir == *"php"* ]]; then
			fix_php_pecl_package_xml "$adir"
		fi

		#---
		if [[ $adir != *"defaults"* ]] && [[ $adir != *"php8"* ]] && \
			 [[ $adir != *"icu"* ]] && [[ $adir != *"libsodium"* ]] && \
			 [[ $adir != *"libzip"* ]] &&[[ $adir != *"libgd"* ]] && \
			 [[ $adir != *"libxml"* ]]; then
			fix_debian_controls "$adir"
			/usr/share/dh-php/gen-control

			dhphp4=$(grep "dh\-php (>= " "$adir"/debian/control* | grep " 4" | wc -l)
			if [[ $dhphp4 -lt 1 ]]; then
				printf "\n --- $adir ERROR \n"
				grep "dh\-php (>= " "$adir"/debian/control*
				printf "\n\n"
				ERRFIX=$(( $ERRFIX + 1 ))
			fi
		fi
	done
}

check_missing_controls(){
	cd /root/src/php
	for adir in $(find . -mindepth 1 -maxdepth 1 -type d | grep -iv "php8\|xdebug" | sort -nr); do
		nums=$(find -L "$adir/debian" -iname "control.in" | wc -l)
		if [[ $nums -lt 1 ]]; then
			printf "\n -- missing control.in: $adir "
			ERRFIX=$(( $ERRFIX + 1 ))
		fi
	done
}



printf "\n\n --- delete duplicates: org.src \n"
delete_duplicate_dirs "/root/org.src/php"
delete_duplicate_dirs "/root/org.src/php"

printf "\n\n --- fix package-5.xml "
fix_package_57_xml

printf "\n\n -------------------------------"
printf "\n\n --- rsync from org.src "
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
~/org.src/php/* ~/src/php/

printf "\n\n --- delete duplicates: src \n"
delete_duplicate_dirs "/root/src/php"
delete_duplicate_dirs "/root/src/php"

printf "\n\n --- delete bad ext "
delete_bad_php_ext

printf "\n\n -------------------------------"
printf "\n\n --- fix controls, rules, etc \n"
ERRFIX=0
fix_controls_rules
if [[ $ERRFIX -gt 0 ]]; then
	ERRFIX=0
	fix_controls_rules

	if [[ $ERRFIX -lt 1 ]]; then
		printf " --- OK (2nd try) \n"
	fi
else
	printf " --- OK \n"
fi


printf "\n\n -------------------------------"
printf "\n\n --- check missing controls "
olderr=$ERRFIX
ERRFIX=0
check_missing_controls
if [[ $ERRFIX -lt 1 ]]; then
	printf " --- OK \n"
else
	export ERRFIX=$(( $ERRFIX + $olderr ))
fi

printf "\n\n"
