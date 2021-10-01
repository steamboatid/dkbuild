#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh



# special version
#-------------------------------------------
#--- file: build_windows/db_config.h --- looking for: PACKAGE_VERSION
VEROVR="4.8.30.1"


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-db4
rm -rf /tb2/build/$RELNAME-db4/*deb
mkdir -p /root/src/db4
rm -rf /root/src/db4/*deb


# build
#-------------------------------------------
cd /root/src/db4/git-db4

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e lib/resty/core/base.lua ]; then
	VERSRC=$(cat build_windows/db_config.h | grep "PACKAGE_VERSION" | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
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
	printf "\n\n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
fi


dch -p -b "backport to $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
head debian/changelog
sleep 2

/bin/bash /tb2/build/dk-build-full.sh


# install all after build
#-------------------------------------------
cd /root/src/db4
apt purge -fy libdb5*dev libdb++-dev libdb5.3-tcl
dpkg -i --force-all *deb


# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/db4
cd /root/src/db4
find /root/src/db4 -type f -iname "*udeb" -delete
find /root/src/db4 -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nginx
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-db4
cp *.deb /tb2/build/$RELNAME-db4/ -Rfav
ls -la /tb2/build/$RELNAME-db4/


# rebuild the repo
#-------------------------------------------
ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &"