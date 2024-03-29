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
fix_relname_relver_bookworm
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
VEROVR="1.21.4.1"


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# prepare dirs
#-------------------------------------------
rm -rf /tb2/build-devomd/$RELNAME-nginx
mkdir -p /tb2/build-devomd/$RELNAME-nginx
mkdir -p /root/src/nginx


# get source from org.src
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/nginx/ /root/src/nginx/


# delete old debs
#-------------------------------------------
rm -rf /root/src/nginx/*deb

# build
#-------------------------------------------
BUILDDIR="/root/src/nginx/git-nginx"
cd $BUILDDIR

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
# exit 0

/bin/bash /tb2/build-devomd/dk-build-full.sh -h "$alxc" -d $BUILDDIR



# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/nginx
cd /root/src/nginx
find -L /root/src/nginx/ -maxdepth 3 -type f -iname "*udeb" -delete
find -L /root/src/nginx/ -maxdepth 3 -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build-devomd/{$RELNAME}-nginx
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-nginx
cp *.deb /tb2/build-devomd/$RELNAME-nginx/ -Rfav
ls -la /tb2/build-devomd/$RELNAME-nginx/
ls /tb2/build-devomd/$RELNAME-nginx/ | grep -i --color "sticky\|geoip2"


# rebuild the repo, temporary commented !
#-------------------------------------------
#--- #--- nohup ssh devomd "nohup /bin/bash /tb2/build-devomd/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
