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
VEROVR="1.21.4.1"


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
mkdir -p /tb2/build/$RELNAME-nginx
rm -rf /tb2/build/$RELNAME-nginx/*deb
mkdir -p /root/src/nginx
rm -rf /root/src/nginx/*deb

# build
#-------------------------------------------
cd /root/src/nginx/git-nginx

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e src/core/nginx.h ]; then
	VERSRC=$(cat src/core/nginx.h | grep "#define NGINX_VERSION" | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
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
mkdir -p /root/src/nginx
cd /root/src/nginx
find /root/src/nginx/ -type f -iname "*udeb" -delete
find /root/src/nginx/ -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nginx
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-nginx
cp *.deb /tb2/build/$RELNAME-nginx/ -Rfa
ls -la /tb2/build/$RELNAME-nginx/


# rebuild the repo
#-------------------------------------------
ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &"
