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


source /tb2/build/dk-build-0libs.sh




# wait until average load is OK
#-------------------------------------------
wait_by_average_load


# special version
#-------------------------------------------
VEROVR="0.5.1"


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-nutcracker
rm -rf /tb2/build/$RELNAME-nutcracker/*deb
mkdir -p /root/src/nutcracker


# get source
#-------------------------------------------
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/nutcracker/ /root/src/nutcracker/


# delete old debs
#-------------------------------------------
rm -rf /root/src/nutcracker/*deb


# build
#-------------------------------------------
BUILDDIR="/root/src/nutcracker/git-nutcracker"
cd $BUILDDIR

# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa



# override version from source
#-------------------------------------------
if [ -e configure.ac ]; then
	VMAJOR=$(cat configure.ac | grep "NC_MAJOR" | grep define | sed -r "s/\)//g" | cut -d" " -f2)
	VMINOR=$(cat configure.ac | grep "NC_MINOR" | grep define | sed -r "s/\)//g" | cut -d" " -f2)
	VPATCH=$(cat configure.ac | grep "NC_PATCH" | grep define | sed -r "s/\)//g" | cut -d" " -f2)
	VEROVR="${VMAJOR}.${VMINOR}.${VPATCH}.1"
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

/bin/bash /tb2/build/dk-build-full.sh -d $BUILDDIR


# delete unneeded packages
#-------------------------------------------
cd /root/src/nutcracker
find /root/src/nutcracker/ -type f -iname "*udeb" -delete
find /root/src/nutcracker/ -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nutcracker
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-nutcracker
cp nutcracker*.deb /tb2/build/$RELNAME-nutcracker/ -Rfav
ls -la /tb2/build/$RELNAME-nutcracker/


# rebuild the repo
#-------------------------------------------
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
