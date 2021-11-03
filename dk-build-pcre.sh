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




# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-pcre
rm -rf /tb2/build/$RELNAME-pcre/*deb
mkdir -p /root/src/pcre
rm -rf /root/src/pcre/*deb


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# get source
#-------------------------------------------
mkdir -p /root/org.src/pcre /root/src/pcre
cd /root/org.src/pcre
apt source -y libpcre3


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src pcre \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/pcre/ /root/src/pcre/


# delete old debs
#-------------------------------------------
rm -rf /root/src/pcre/*deb


# build
#-------------------------------------------
find /root/src/pcre -maxdepth 1 -mindepth 1 -type d -name "pcre*" | head -n1 |
while read adir; do
	cd $adir
	pwd

	# revert backup if exists
	if [ -e "debian/changelog.1" ]; then
		cp debian/changelog.1 debian/changelog
	fi
	# backup changelog
	cp debian/changelog debian/changelog.1 -fa


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
cp *.deb /tb2/build/$RELNAME-pcre/ -Rfav
ls -la /tb2/build/$RELNAME-pcre/


# rebuild the repo
#-------------------------------------------
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
