#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

export PHPV_DEFAULT="php8.0"
export PHPV="${1:-$PHPV_DEFAULT}"
export PHPVNUM=$(echo $PHPV | sed 's/php//g')


source /tb2/build/dk-build-0libs.sh



doback(){
	/usr/bin/nohup /bin/bash /tb2/build/dk-build-full.sh 2>&1 >/dev/null 2>&1 &
	printf "\n\n\n"
	sleep 1
}
dofore(){
	/bin/bash /tb2/build/dk-build-full.sh
	printf "\n\n\n"
	sleep 1
}



# print php version
#-------------------------------------------
printf "\n\n --- php version: ${yel}$PHPV${end} [$PHPVNUM] \n\n"


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
rm -rf /root/src/php8 /root/org.src/php8

# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-$PHPV
rm -rf /tb2/build/$RELNAME-$PHPV/*deb
mkdir -p /root/src/$PHPV


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/$PHPV/ /root/src/$PHPV/


# delete old debs
#-------------------------------------------
rm -rf /root/src/$PHPV/*deb


# BUGGY libzip
#-------------------------------------------
# rm -rf /root/src/$PHPV/libzip*


# Compiling all packages
#-------------------------------------------
cd /root/src/$PHPV

# pwd
# find /root/src/$PHPV -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip"
# exit 0;

for adir in $(find /root/src/$PHPV -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis\|libzip"); do
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

	if [[ $adir == *"redis"* ]]; then
		printf "\n\n\n --- its PHP-REDIS -- do rsync $adir \n"
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		/root/src/git-phpredis $adir
		pwd
		printf "\n\n\n"
	fi

	NUMINS=$(ps -e -o command | grep -v grep | grep "dk-build-full" | awk '{print $NF}' | wc -l)
	if [[ $NUMINS -lt 8 ]]; then
		doback
	else
		if [[ $adir == *"phalcon"* ]]; then doback; else dofore; fi
	fi
done


# wait all background jobs
#-------------------------------------------
wait



# delete unneeded packages
#-------------------------------------------
cd /root/src/$PHPV
find /root/src/$PHPV/ -type f -iname "*udeb" -delete
find /root/src/$PHPV/ -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-php8.x
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-$PHPV
cp *.deb /tb2/build/$RELNAME-$PHPV/ -Rfav
ls -la /tb2/build/$RELNAME-$PHPV/


# rebuild the repo
#-------------------------------------------
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
