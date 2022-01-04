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
#--- file: meson.build --- looking for: version
VEROVR="3.10.3"



# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-sshfs
rm -rf /tb2/build/$RELNAME-sshfs/*deb
mkdir -p /root/src/sshfs
rm -rf /root/src/sshfs/*deb


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# get source
#-------------------------------------------
mkdir -p /root/org.src/sshfs /root/src/sshfs
cd /root/org.src/sshfs
aptold source -y sshfs libfuse3-dev


# prepare dirs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-sshfs
rm -rf /tb2/build/$RELNAME-sshfs/*deb
mkdir -p /root/src/sshfs


#--- get source
#-------------------------------------------
printf "\n-- sync to src sshfs \n"
rsync -aHAXztrv --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/sshfs/ /root/src/sshfs/


# delete old debs
#-------------------------------------------
rm -rf /root/src/sshfs/*deb



do_build_sshfs_fuse() {
	bdir="$1"

	# revert backup if exists
	if [ -e "debian/changelog.1" ]; then
		cp debian/changelog.1 debian/changelog
	fi
	# backup changelog
	cp debian/changelog debian/changelog.1 -fa



	# override version from source
	#-------------------------------------------
	if [ -e meson.build ]; then
		VERSRC=$(cat meson.build | grep "version" | grep "project" | head -n1 | tr "'" " " | cut -d" " -f9)
		VEROVR="${VERSRC}.1"
		printf "\n by source \n--- VERSRC=$VERSRC ---> VEROVR=$VEROVR \n"
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
		printf "\n by verovr \n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
	fi


	dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
	-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
	head debian/changelog
	sleep 2

	/bin/bash /tb2/build/dk-build-full.sh -d "$bdir"
}



# build FUSE
#-------------------------------------------
dirname=$(find /root/src/sshfs -mindepth 1 -maxdepth 1 -type d -iname "*fuse*" | grep -v "sshfs\-" | head -n1)
cd $dirname
pwd
do_build_sshfs_fuse "$dirname"


# build SSHFS
#-------------------------------------------
dirname=$(find /root/src/sshfs -mindepth 1 -maxdepth 1 -type d -iname "*sshfs*" | head -n1)
cd $dirname
pwd
# hack iosize
sed -i -r "s/sshfs\.blksize = 4096/sshfs\.blksize = 104857600/g" sshfs.c
do_build_sshfs_fuse "$dirname"




# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/sshfs
cd /root/src/sshfs
find /root/src/sshfs -type f -iname "*udeb" -delete
find /root/src/sshfs -type f -iname "*dbgsym*deb" -delete


# upload to /tb2/build/{$RELNAME}-nginx
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-sshfs
cp *.deb /tb2/build/$RELNAME-sshfs/ -Rfav
ls -la /tb2/build/$RELNAME-sshfs/


# rebuild the repo
#-------------------------------------------
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &