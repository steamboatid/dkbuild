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
fix_relname_bookworm
fix_apt_bookworm




# wait until average load is OK
#-------------------------------------------
wait_by_average_load


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-pcre
rm -rf /tb2/build-devomd/$RELNAME-pcre/*deb
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
aptold source -y libpcre3


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
cd /root/src/pcre
find -L /root/src/pcre -maxdepth 1 -mindepth 1 -type d -name "pcre*"

for adir in $(find -L /root/src/pcre -maxdepth 1 -mindepth 1 -type d -name "pcre*" | sort -nr); do
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
	printf "\n\n$adir --- VERNUM= $VERNUM NEXT= $VERNEXT ---\n"

	# pcre only
	if [ -e "debian/changelog" ]; then
		VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~]/ /g"| cut -f1 -d" ")
		VERNEXT=$(echo ${VERNUM} | awk -F- -v OFS=- '{$NF=$NF+20;print}')
		printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT ---\n"
	fi

	# if [ -e "debian/changelog" ]; then
	# 	VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
	# 	VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
	# 	printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT ---\n"
	# fi

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

	/bin/bash /tb2/build-devomd/dk-build-full.sh -d "$adir"
done


# delete unneeded packages
#-------------------------------------------
mkdir -p /root/src/pcre
cd /root/src/pcre
find -L /root/src/pcre -maxdepth 3 -type f -iname "*udeb" -delete
find -L /root/src/pcre -maxdepth 3 -type f -iname "*dbgsym*deb" -delete


# install current debs
#-------------------------------------------
dpkg -i --force-all *deb


# upload to /tb2/build-devomd/{$RELNAME}-nginx
#-------------------------------------------
mkdir -p /tb2/build-devomd/$RELNAME-pcre
cp *.deb /tb2/build-devomd/$RELNAME-pcre/ -Rfav
ls -la /tb2/build-devomd/$RELNAME-pcre/


# rebuild the repo
#-------------------------------------------
nohup ssh devomd "nohup /bin/bash /tb2/build-devomd/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
