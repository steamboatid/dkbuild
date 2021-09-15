#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

# special version
#-------------------------------------------
VEROVR="6.2.0.1"


# reset default build flags
#-------------------------------------------
echo \
"STRIP CFLAGS -g -O2
STRIP CXXFLAGS -g -O2
STRIP LDFLAGS -g -O2

PREPEND CFLAGS -O3
PREPEND CXXFLAGS -O3
PREPEND LDFLAGS -Wl,-s
">/etc/dpkg/buildflags.conf


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-keydb
rm -rf /tb2/build/$RELNAME-keydb/*deb
mkdir -p /root/src/keydb
rm -rf /root/src/keydb/*deb


# build
#-------------------------------------------
cd /root/src/keydb/git-keydb

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e src/version.h ]; then
	VERSRC=$(cat src/version.h | grep "#define KEYDB_REAL_VERSION" | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
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



# delete unneeded packages
#-------------------------------------------
cd /root/src/keydb
find /root/src/keydb/ -type f -iname "*udeb" -delete
find /root/src/keydb/ -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-keydb
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-keydb
cp keydb*.deb /tb2/build/$RELNAME-keydb/ -Rfa
ls -la /tb2/build/$RELNAME-keydb/
