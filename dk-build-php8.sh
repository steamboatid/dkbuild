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
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r '0,/^php-pecl-http/{s/^php-pecl-http/php-http/}' debian/changelog
	sed -i -r 's/pecl-http\.so/http\.so/' debian/php-http.pecl

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.33~/dh-php \(>= 4~/' debian/control

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control.in
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control.in
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/dh-php \(>= 0.33~/dh-php \(>= 4~/' debian/control.in

	cd "$odir"
}

fix_php_lz4(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules

	cd "$odir"
}
fix_php_ps(){
	odir=$PWD
	adir="$1"

	cd /tmp;
	wget -c wget https://pecl.php.net/get/ps-1.4.4.tgz; \
	tar xvzf ps-1.4.4.tgz

	cd "$adir"
	[[ -e ps-1.4.1 ]] && mv ps-1.4.1 old.ps-1.4.1
	cp /tmp/ps-1.4.4 . -Rfa

	cp debian/control debian/control.in
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/<min>4.3.10/<min>7.0.33/' package.xml
	sed -i -r 's/<release>1.4.1/<release>1.4.4/' package.xml

	cd "$odir"
}
fix_php_phalcon3(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules

	cd "$odir"
}


fix_debian_controls(){
	bdir="$1"
	odir=$PWD
	cd "$bdir"

	# copy if not exists
	[[ ! -e debian/control.in ]] && cp debian/control debian/control.in
	/usr/share/dh-php/gen-control

	files=('debian/control.in' 'debian/control')
	for afile in "${files[@]}"; do
		if [[ $(grep "Package\:.*all-dev" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php.*-all-dev/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 8.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php8.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 7.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php7.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 5.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php5.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi
	done

	/usr/share/dh-php/gen-control
	cd "$odir"
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
		printf "\n by VEROVR \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
		sleep 1
	fi


	dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
	-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
	head debian/changelog

	cd "$odir"
}


# wait until average load is OK
#-------------------------------------------
wait_by_average_load


# delete duplicate dirs
#-------------------------------------------
/bin/bash /tb2/build/dk-prep-del-dups.sh


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


# BUGGY extensions
#-------------------------------------------
# rm -rf /root/src/php/libzip*

find /root/org.src/php -maxdepth 1 -type d -iname "*xmlrpc*" | xargs rm -rf
find /root/org.src/php -maxdepth 1 -type f -iname "*xmlrpc*" | xargs rm -rf
find /root/src/php -maxdepth 1 -type d -iname "*xmlrpc*" | xargs rm -rf
find /root/src/php -maxdepth 1 -type f -iname "*xmlrpc*" | xargs rm -rf

http_v3=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-3*" | wc -l)
http_v4=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-4*" | wc -l)
if [[ $http_v3 -gt 0 ]] && [[ $http_v4 -gt 0 ]]; then
	find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-3*" | xargs rm -rf
fi

ps_141=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.1*" | wc -l)
ps_144=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.4*" | wc -l)
if [[ $ps_141 -gt 0 ]] && [[ ps_144 -gt 0 ]]; then
	find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.1*" | xargs rm -rf
fi

pinba_110=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.0*" | wc -l)
pinba_112=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.2*" | wc -l)
if [[ $pinba_110 -gt 0 ]] && [[ $pinba_112 -gt 0 ]]; then
	find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.0*" | xargs rm -rf
fi



# Compiling all packages
#-------------------------------------------
cd /root/src/php

# pwd
# find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip"
# exit 0;

# for adir in $(find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -i "phalcon3\|http\|lz4\|\-ps\-" | sort -nr); do


# for adir in $(find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip" | sort -nr); do
for adir in $(find /root/src/php -maxdepth 1 -mindepth 1 -type d | grep "http" | sort -nr); do

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
	if [[ $adir == *"-ps-"* ]] && [[ $adir == *"1.4.1"* ]]; then
		fix_php_ps "$adir"
	fi

	#---
	fix_debian_controls "$adir"


	if [[ $adir == *"redis"* ]]; then
		printf "\n\n\n --- its PHP-REDIS -- do rsync $adir \n"
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		/root/src/git-phpredis $adir
		pwd
		printf "\n\n\n"
	fi


	if [[ $adir == *"http"* ]]; then
		propro_dir=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*propro*" | sort | tail -n1)
		cd "$propro_dir"
		prepare_php_build "$propro_dir"
		fix_debian_controls "$adir"
		dofore "$propro_dir"

		sleep 1
		cd "$adir"
		dofore "$adir"
		continue
	fi

	# if [[ $adir == *"propro"* ]]; then
	# 	cd "$adir"
	# 	dofore "$adir"
	# 	dpkg -i --force-all ../php*-propro*deb

	# 	sleep 1
	# 	http_dir=$(find /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http*" | sort | tail -n1)
	# 	cd "$http_dir"
	# 	prepare_php_build "$http_dir"
	# 	fix_php_pecl_http "$http_dir"
	# 	dofore "$http_dir"
	# 	continue
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
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
