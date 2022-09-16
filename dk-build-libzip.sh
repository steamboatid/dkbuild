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
fix_relname_bookworm
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




# wait until average load is OK
#-------------------------------------------
wait_by_average_load


# special version
#-------------------------------------------
#--- file: lib/resty/core/base.lua --- looking for: _M.version
VEROVR="0.1.22.1"


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-libzip
rm -rf /tb2/build-devomd/$RELNAME-libzip/*deb
mkdir -p /root/src/libzip


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/libzip/ /root/src/libzip/


# delete old debs
#-------------------------------------------
rm -rf /root/src/libzip/*deb


# build
#-------------------------------------------
BUILDDIR="/root/src/libzip/git-libzip"
cd $BUILDDIR

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e CMakeLists.txt ]; then
	VERSRC=$(cat CMakeLists.txt | sed "s/\s//g" | grep "^VERSION" | sed "s/VERSION//g")
	VEROVR="${VERSRC}.1"
	printf "\n\n VERSRC=$VERSRC ---> VEROVR=$VEROVR \n"
fi



VERNUM=$(basename "$PWD" | tr "-" " " | awk '{print $NF}' | cut -f1 -d"+")
VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
printf "\n\n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT---\n"

if [ -e "debian/changelog" ]; then
	VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
	VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
	printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
fi

if [ -n "$VEROVR" ]; then
	VERNEXT=$VEROVR

	if [[ $VERNUM = *":"* ]]; then
		AHEAD=$(echo $VERNUM | cut -d':' -f1)
		AHEAD=$(( $AHEAD + 20 ))
		VERNEXT="$AHEAD:$VERNEXT"
	fi

	printf "\n\n by VEROVR --- $adir \n--- VERNUM= $VERNUM NEXT= $VERNEXT ---\n"
fi


dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.omd.id" -D buster -u high; \
head debian/changelog
sleep 2

/bin/bash /tb2/build-devomd/dk-build-full.sh -h "$alxc" -d $BUILDDIR



# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/libzip
cd /root/src/libzip
find -L /root/src/libzip -maxdepth 3 -type f -iname "*udeb" -delete
find -L /root/src/libzip -maxdepth 3 -type f -iname "*dbgsym*deb" -delete


# install current debs
#-------------------------------------------
dpkg -i --force-all *deb


# upload to /tb2/build-devomd/{$RELNAME}-nginx
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-libzip
cp *.deb /tb2/build-devomd/$RELNAME-libzip/ -Rfav
ls -la /tb2/build-devomd/$RELNAME-libzip/


# rebuild the repo
#-------------------------------------------
#--- nohup ssh devomd "nohup /bin/bash /tb2/build-devomd/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
