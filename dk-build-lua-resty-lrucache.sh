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
#--- file: lrucache.lua --- looking for: _VERSION
VEROVR="0.11.1"


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-lua-resty-lrucache
rm -rf /tb2/build/$RELNAME-lua-resty-lrucache/*deb
mkdir -p /root/src/lua-resty-lrucache


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/lua-resty-lrucache/ /root/src/lua-resty-lrucache/


# delete old debs
#-------------------------------------------
rm -rf /root/src/lua-resty-lrucache/*deb


# build
#-------------------------------------------
cd /root/src/lua-resty-lrucache/git-lua-resty-lrucache

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e lib/resty/lrucache.lua ]; then
	VERSRC=$(cat lib/resty/lrucache.lua | grep "_VERSION" | sed -r "s/\s+/ /g" | sed "s/^\s//g" | tr "'" '"'| sed "s/\"//g" | cut -d" " -f3)
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


dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
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
cp *.deb /tb2/build/$RELNAME-lua-resty-lrucache/ -Rfav
ls -la /tb2/build/$RELNAME-lua-resty-lrucache/


# rebuild the repo
#-------------------------------------------
ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &"
