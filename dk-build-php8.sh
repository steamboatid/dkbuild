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



doback(){
	adir="$1"
	cd "$adir"
	/usr/bin/nohup /bin/bash /tb2/build/dk-build-full.sh -d "$adir" 2>&1 >/dev/null 2>&1 &
	printf "\n\n\n"
	sleep 1
}
dofore(){
	adir="$1"
	cd "$adir"
	/bin/bash /tb2/build/dk-build-full.sh -d "$adir"
	printf "\n\n\n"
	sleep 1
}

fix_php_pecl_http(){
	cp debian/control debian/control.in

	sed -i -r '0,/^php-pecl-http/{s/^php-pecl-http/php-http/}' debian/changelog
	sed -i -r 's/pecl-http\.so/http\.so/' debian/php-http.pecl

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control.in
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control.in
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
}

fix_php_lz4(){
	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules
}
fix_php_ps(){
	odir=$PWD

	cd /tmp;
	wget -c wget https://pecl.php.net/get/ps-1.4.4.tgz; \
	tar xvzf ps-1.4.4.tgz

	cd "$odir"
	[[ -e ps-1.4.1 ]] && mv ps-1.4.1 old.ps-1.4.1
	cp /tmp/ps-1.4.4 . -Rfa

	cp debian/control debian/control.in
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/<min>4.3.10/<min>7.0.33/' package.xml
	sed -i -r 's/<release>1.4.1/<release>1.4.4/' package.xml
}
fix_php_phalcon3(){
	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules
}



# wait until average load is OK
#-------------------------------------------
wait_by_average_load


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
/root/src/php8.0 /root/org.src/php8.0 \
/root/src/php8.1 /root/org.src/php8.1

find /root/org.src/php -iname "*phalcon3*" | xargs rm -rf
find /root/src/php -iname "*phalcon3*" | xargs rm -rf

# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-php
rm -rf /tb2/build/$RELNAME-php/*deb
mkdir -p /root/src/php


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/php/ /root/src/php/


# delete old debs
#-------------------------------------------
rm -rf /root/src/php/*deb


# BUGGY libzip
#-------------------------------------------
# rm -rf /root/src/php/libzip*


# Compiling all packages
#-------------------------------------------
cd /root/src/php

# pwd
# find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip"
# exit 0;

# for adir in $(find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip" | sort); do

for adir in $(find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -i "phalcon3\|http\|lz4\|\-ps\-" | sort); do

	#--- ovveride version
	VEROVR=""

	#--- wait until average load is OK
	wait_by_average_load

	#--- starting building
	cd $adir
	pwd

	# revert backup if exists
	if [ -e "debian/changelog.1" ]; then
		cp debian/changelog.1 debian/changelog
	fi
	# backup changelog
	cp debian/changelog debian/changelog.1 -fa

	if [[ -d debian/rules.d ]]; then
		echo "
override_dh_shlibdeps:
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info

">debian/rules.d/ovr-shlibdeps.mk
	fi


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
		printf "\n by VEROVR \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
	fi


	dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
	-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
	head debian/changelog

	# temporary solution
	if [[ $adir == *"http"* ]]; then
		fix_php_pecl_http
	fi
	if [[ $adir == *"lz4"* ]]; then
		fix_php_lz4
	fi
	if [[ $adir == *"-ps-"* ]]; then
		fix_php_ps
	fi
	if [[ $adir == *"phalcon3"* ]]; then
		fix_php_phalcon3
	fi

	if [[ $adir == *"redis"* ]]; then
		printf "\n\n\n --- its PHP-REDIS -- do rsync $adir \n"
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		/root/src/git-phpredis $adir
		pwd
		printf "\n\n\n"
	fi

	# NUMINS=$(ps -e -o command | grep -v grep | grep "dk-build-full" | awk '{print $NF}' | wc -l)
	# if [[ $NUMINS -lt 5 ]]; then
	# 	doback "$adir"
	# else
	# 	if [[ $adir == *"phalcon"* ]]; then doback "$adir"; else dofore "$adir"; fi
	# fi

	# always do background, avg load already checked in the beginning loop
	dofore "$adir"
	sleep 1
done


# wait all background jobs
#-------------------------------------------
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



# delete unneeded packages
#-------------------------------------------
cd /root/src/php
find /root/src/php/ -type f -iname "*udeb" -delete
find /root/src/php/ -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-php8.x
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-php
cp *.deb /tb2/build/$RELNAME-php/ -Rfav
ls -la /tb2/build/$RELNAME-php/


# rebuild the repo
#-------------------------------------------
# nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
