#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)


# special version
#-------------------------------------------
#--- file: lrucache.lua --- looking for: _VERSION
VEROVR="0.11.1"


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-lua-resty-lrucache
rm -rf /tb2/build/$RELNAME-lua-resty-lrucache/*deb


# build
#-------------------------------------------
cd /root/src/lua-resty-lrucache/git-lua-resty-lrucache

# revert backup if exists
if [ -e "debian/changelog.bak" ]; then
	cp debian/changelog.bak debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.bak


VERNUM=$(basename "$PWD" | tr "-" " " | awk '{print $NF}' | cut -f1 -d"+")
VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
printf "\n\n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT---\n"

if [ -e "debian/changelog" ]; then
	AISITS=$(cat debian/changelog | head -n1 | grep "aisits" | wc -l)
	if [[ $AISITS -lt 1 ]]; then
		VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
		VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
		printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
	fi
fi

if [ -n "$VEROVR" ]; then
	VERNEXT=$VEROVR
	printf "\n\n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
fi


dch -p -b "backport to $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
-v "$VERNEXT+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
head debian/changelog
sleep 2

/bin/bash /tb2/build/dk-build-full.sh



# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/lua-resty-lrucache
cd /root/src/lua-resty-lrucache
find /root/src/lua-resty-lrucache -type f -iname "*udeb" -delete
find /root/src/lua-resty-lrucache -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nginx
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-lua-resty-lrucache
cp *.deb /tb2/build/$RELNAME-lua-resty-lrucache/ -Rfa
ls -la /tb2/build/$RELNAME-lua-resty-lrucache/
