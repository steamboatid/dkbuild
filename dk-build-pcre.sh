#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-pcre
rm -rf /tb2/build/$RELNAME-pcre/*deb


# get source
#-------------------------------------------
mkdir -p /root/src/pcre
cd /root/src/pcre
apt source -y libpcre3


# build
#-------------------------------------------
find /root/src/pcre -maxdepth 1 -mindepth 1 -type d -name "pcre*" | head -n1 |
while read adir; do
	cd $adir
	pwd

	# revert backup if exists
	if [ -e "debian/changelog.bak" ]; then
		cp debian/changelog.bak debian/changelog
		cp debian/changelog.bak debian/changelog.1
	fi
	if [ ! -e "debian/changelog.org" ]; then
		cp debian/changelog debian/changelog.org
	fi
	# backup changelog
	cp debian/changelog debian/changelog.bak


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
	-v "$VERNEXT+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
	head debian/changelog
	sleep 2
	exit 0;

	/bin/bash /tb2/build/dk-build-full.sh
done


# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/pcre
cd /root/src/pcre
find /root/src/pcre -type f -iname "*udeb" -delete
find /root/src/pcre -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nginx
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-pcre
cp *.deb /tb2/build/$RELNAME-pcre/ -Rfa
ls -la /tb2/build/$RELNAME-pcre/
