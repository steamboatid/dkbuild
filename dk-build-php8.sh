#!/bin/bash


sdir=$(realpath $(dirname $0))
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

export PHPVERS=("php8.2" "php8.1")
export PHPGREP="php8.2\|php8.1"


source /tb2/build-devomd/dk-build-1libs.sh
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



clean_apt_lock(){
	find -L /var/lib/apt/lists/ -type f -delete; \
	find -L /var/cache/apt/ -type f -delete; \
	rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
	/etc/apt/preferences.d/00-revert-stable \
	/var/cache/debconf/ /var/lib/apt/lists/* \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
	mkdir -p /root/.local/share/nano/ /root/.config/procps/; \
	dpkg --configure -a; \
	systemctl restart systemd-timesyncd.service; \
	apt autoclean; apt clean; apt update --allow-unauthenticated

	aptold full-upgrade --auto-remove --purge --fix-missing -fy \
		-o Dpkg::Options::="--force-overwrite"
}

reinstall_db48(){
	clean_apt_lock

	dpkg -l | grep db4.8 | grep omd | awk '{print $2}' | xargs apt remove -fy

	apt-cache search db4.8 | grep -v "cil\|gcj" | \
		awk '{print $1}' | \
		xargs aptold install -o Dpkg::Options::="--force-overwrite" -fy
}



doback(){
	adir="$1"
	cd "$adir"
	/usr/bin/nohup /bin/bash /tb2/build-devomd/dk-build-full.sh -h "$alxc" -d "$adir" 2>&1 >/dev/null 2>&1 &
	printf "\n\n\n"
	sleep 1
}

dofore(){
	adir="$1"
	cd "$adir"
	/bin/bash /tb2/build-devomd/dk-build-full.sh -h "$alxc" -d "$adir"
	printf "\n\n\n"
	sleep 1
}

prepare_php_build(){
	bdir="$1"
	odir=$PWD
	cd "$bdir"

	# revert backup if exists
	if [ -e "debian/changelog.1" ]; then
		cp debian/changelog.1 debian/changelog
	fi
	# backup changelog
	cp debian/changelog debian/changelog.1 -fa

	mkdir -p debian/rules.d
	echo "
override_dh_shlibdeps:
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info
">debian/rules.d/ovr-shlibdeps.mk


	# override version from source
	#-------------------------------------------
	if [ -e main/php_version.h ]; then
		VERSRC=$(cat main/php_version.h | grep "define PHP_VERSION " | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
		VEROVR="${VERSRC}.1"
		printf "\n\n VERSRC=$VERSRC ---> VEROVR=$VEROVR \n"
	fi
	if [ -e php_redis.h ]; then
		VERSRC=$(cat php_redis.h | grep "define PHP_REDIS_VERSION " | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
		VEROVR="${VERSRC}.1"
		printf "\n\n VERSRC=$VERSRC ---> VEROVR=$VEROVR \n"
	fi


	VERNUM=$(basename "$PWD" | tr "-" " " | awk '{print $NF}' | cut -f1 -d"+")
	VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
	printf "\n\n$adir \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
	sleep 1

	if [ -e "debian/changelog" ]; then
		VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
		VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
		printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
	fi

	if [ -n "$VEROVR" ]; then
		VERNEXT=$VEROVR

		if [[ $VERNUM = *":"* ]]; then
			AHEAD=$(echo $VERNUM | cut -d':' -f1)
			AHEAD=$(( $AHEAD + 20 ))
			VERNEXT="$AHEAD:$VERNEXT"
		fi

		printf "\n by VEROVR \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
		sleep 1
	fi


	dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
	-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.omd.id" -D buster -u high; \
	head debian/changelog

	cd "$odir"
}

wait_build_jobs_php(){
	printf "\n\n --- wait all background build jobs: "
	numo=0
	while :; do
		numa=$(ps auxw | grep -v grep | grep "dk-build-full.sh" | wc -l)
		if [[ $numa -lt 1 ]]; then break; fi
		if [[ $numa -ne $numo ]]; then
			printf " $numa"
			numo=$numa
		else
			printf "."
		fi
		sleep 3
	done

	wait
	sleep 1
	printf "\n\n"
}

build_install_msgpack_debs(){
	printf "\n\n --- $sdir \n\n"
	build_msgpack=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "msgpack" | wc -l)
	if [[ $build_msgpack -lt 1 ]]; then
		msgpack_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*msgpack*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$msgpack_dir"
	fi
}

build_install_igbinary_debs(){
	printf "\n\n --- $sdir \n\n"
	build_igbinary=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "igbinary" | wc -l)
	if [[ $build_igbinary -lt 1 ]]; then
		igbinary_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*igbinary*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$igbinary_dir"
	fi
}

build_install_raph_debs(){
	printf "\n\n --- $sdir \n\n"
	build_raph=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "raph" | wc -l)
	if [[ $build_raph -lt 1 ]]; then
		raph_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*raph*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$raph_dir"
	fi
}

build_install_propro_debs(){
	printf "\n\n --- $sdir \n\n"
	build_propro=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "propro" | wc -l)
	if [[ $build_propro -lt 1 ]]; then
		propro_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*propro*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$propro_dir"
	fi
}

build_install_http_debs(){
	printf "\n\n --- $sdir \n\n"
	build_http=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "http" | wc -l)
	if [[ $build_http -lt 1 ]]; then
		http_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*http*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$http_dir"
	fi
}

build_install_redis_debs(){
	printf "\n\n --- $sdir \n\n"
	build_redis=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "redis" | wc -l)
	if [[ $build_redis -lt 1 ]]; then
		redis_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*redis*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$redis_dir"
	fi
}

build_install_memcached_debs(){
	printf "\n\n --- $sdir \n\n"
	build_memcached=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "memcached" | wc -l)
	if [[ $build_memcached -lt 1 ]]; then
		memcached_dir=$(find -L /root/src/php -maxdepth 1 -type d -iname "php*memcached*" | sort -n | head -n1)
		/bin/bash $sdir/dk-build-full.sh -h "$alxc" -d "$memcached_dir"
	fi
}



install_propro_debs(){
	build_propro=$(ps axww | grep -v grep | grep "dk-build-full.sh" | grep -i "propro" | wc -l)
	debs_propro=$(find -L /root/src/php -maxdepth 2 -type f -iname "php*-propro*deb" | wc -l)
	if [[ $debs_propro -gt 0 ]] && [[ $build_propro -lt 0 ]]; then
		find -L /root/src/php -maxdepth 2 -type f -iname "php*-propro*deb" | \
			xargs dpkg -i --force-all
	fi
}

building_php(){
	adir="$1"
	odir=$PWD

	#--- ovveride version
	VEROVR=""

	#--- wait until average load is OK
	wait_by_average_load

	#--- starting building
	cd $adir
	pwd

	#--- prepare changelog, rules.d, etc
	prepare_php_build "$adir"


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
	if [[ $adir != *"defaults"* ]] && [[ $adir != *"php8"* ]]; then
		fix_debian_controls "$adir"
		fix_debian_controls "$adir"
	fi

	#---
	if [[ $adir == *"php"* ]]; then
		fix_php_pecl_package_xml "$adir"
	fi


	if [[ $adir == *"redis"* ]]; then
		printf "\n\n\n --- its PHP-REDIS -- do rsync $adir \n"
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		/root/src/git-phpredis $adir
		pwd
		printf "\n\n\n"
	fi


	if [[ $adir == *"http"* ]]; then
		cdir=$PWD
		propro_dir=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*propro*" | sort | tail -n1)
		cd "$propro_dir"
		prepare_php_build "$propro_dir"
		fix_debian_controls "$propro_dir"
		pwd
		doback "$propro_dir" "$alxc"
		wait_build_jobs_php

		sleep 1
		dpkg -i --force-all ../php*-propro*deb

		cd "$cdir"
		adir=$cdir
	fi

	# always do background, avg load already checked in the beginning loop
	doback "$adir"
	sleep 1

	# install after build
	install_propro_debs

	cd "$odir"
}






# wait until average load is OK
#-------------------------------------------
wait_by_average_load
reinstall_db48
set_php81_as_default


# delete duplicate dirs
#-------------------------------------------
# /bin/bash /tb2/build-devomd/dk-prep-del-dups.sh


# special version
#-------------------------------------------
VEROVR=""


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags
# alter_berkeley_dbh


# remove old dirs
#-------------------------------------------
rm -rf /root/src/php8 /root/org.src/php8 \
/root/src/php8.0 /root/org.src/php8.0


# prepare dirs
#-------------------------------------------
rm -rf /tb2/build-devomd/$RELNAME-php
mkdir -p /tb2/build-devomd/$RELNAME-php
mkdir -p /root/src/php


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/php/ /root/src/php/
find -L /root/src/php -maxdepth 2 -name "php8*-8*"

# delete old debs
#-------------------------------------------
rm -rf /root/src/php/*deb


# BUGGY extensions
#-------------------------------------------
# rm -rf /root/src/php/libzip*
delete_bad_php_ext

export ERRFIX=0
/bin/bash /tb2/build-devomd/dk-fix-php-sources.sh
if [[ $ERRFIX -gt 0 ]]; then
	printf "\n\n\n ERROR \n\n"
	exit 10
fi



# Compiling all packages
#-------------------------------------------
cd /root/src/php

# pwd
# find -L /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip"
# exit 0;

# for adir in $(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -i "phalcon3\|http\|lz4\|\-ps\-" | sort -nr); do
# for adir in $(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d | grep "http" | sort -nr); do


#--- build & install some extensions first
clean_apt_lock
#--- pre-request for redis + memcached
build_install_igbinary_debs &
build_install_msgpack_debs &

#--- pre-request for pecl-http
build_install_raph_debs &
build_install_propro_debs &
wait_jobs
wait_build_jobs_php

#--- install first
exts=("msgpack" "igbinary" "raph" "propro")
for aext in "${exts[@]}"; do
	ftmp1=$(mktemp)
	find -L /root/src/php -maxdepth 1 -type f -iname "php*${aext}*deb" > $ftmp1

	if [[ -s $ftmp1 ]]; then
		printf "\n\n $aext \tOK --- installing "
		cat $ftmp1 | xargs dpkg -i --force-all >/dev/null 2>&1
	else
		printf "\n\n $aext \tFAILED "
		exit 0;
	fi
done
printf "\n\n"
wait_jobs


#--- build install pecl-http
build_install_http_debs &
build_install_redis_debs &
build_install_memcached_debs &
wait_jobs
wait_build_jobs_php

#--- install first
exts=("http" "redis" "memcached")
for aext in "${exts[@]}"; do
	ftmp1=$(mktemp)
	find -L /root/src/php -maxdepth 1 -type f -iname "php*${aext}*deb" | sort -nr > $ftmp1

	if [[ -s $ftmp1 ]]; then
		printf "\n\n $aext \tOK --- installing "
		cat $ftmp1 | xargs dpkg -i --force-all >/dev/null 2>&1
	else
		printf "\n\n $aext \tFAILED "
		exit 0;
	fi
done
printf "\n\n"
wait_jobs
# exit 0

#--- clean apt lock first
clean_apt_lock

#--- initial build
for adir in $(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d | sort -n | \
grep -v "git-phpredis\|libzip\|libvirt\|xcache\|tideways\|phalcon3\|lz4" | sort -nr); do
	building_php "$adir" "$alxc"
done

#--- immediate install
# install_propro_debs

#--- rebuild if dkbuild.log not found
wait_build_jobs_php
for adir in $(find -L /root/src/php -mindepth 1 -maxdepth 1 -type d | sort -n); do
	if [[ $(find $adir -maxdepth 1 -type f -iname "dkbuild.log" | wc -l) -lt 1 ]]; then
		building_php "$adir" "$alxc"
	fi
done



# wait all background jobs
#-------------------------------------------
wait_build_jobs_php



# delete unneeded packages
#-------------------------------------------
cd /root/src/php
find -L /root/src/php/ -maxdepth 3 -type f -iname "*udeb" -delete
find -L /root/src/php/ -maxdepth 3 -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build-devomd/{$RELNAME}-php8.x
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-php
cp *.deb /tb2/build-devomd/$RELNAME-php/ -Rfav
ls -la /tb2/build-devomd/$RELNAME-php/

ls -la /tb2/build-devomd/$RELNAME-php/ | grep omd | grep 8.1 |\
	grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|propro"


printf "\n\n --- check essential extensions \n"
essphp=("apcu" "http" "igbinary" "imagick" "memcached" "msgpack" "raphf" "redis" "propro")
for pkg in "${essphp[@]}"; do
	num=$(find -L /root/src/php/ -maxdepth 2 -type f -iname "*$pkg*deb" | wc -l)
	printf "\n --- $pkg \t-- $num"
	[[ $num -lt 1 ]] && printf " \t--- MISS "
done
printf "\n\n"

# rebuild the repo
#-------------------------------------------
#--- nohup ssh devomd "nohup /bin/bash /tb2/build-devomd/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &

# find ~/src/php -maxdepth 1 -type f -iname "*igbinary*deb" | xargs dpkg -i --force-all
# find ~/src/php -maxdepth 1 -type f -iname "*msgpack*deb" | xargs dpkg -i --force-all
