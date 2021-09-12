#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

doback(){
	/usr/bin/nohup /bin/bash /tb2/build/dk-build-full.sh 2>&1 | tee phpbuild.log >/dev/null 2>&1 &
	printf "\n\n\n"
	sleep 1
}
dofore(){
	/bin/bash /tb2/build/dk-build-full.sh 2>&1 | tee phpbuild.log
	NUMFAIL=$(grep "buildpackage" build.log | grep failed | wc -l)
	printf "\n\n\n\tFAILS = $NUMFAIL\n\n"
	if [[ $NUMFAIL -gt 0 ]]; then
		cat build.log
		printf "\n\n\n\tFAILS = $NUMFAIL\n\n"
		exit 0;
	fi
	sleep 1
}



# special version
#-------------------------------------------
VEROVR=""


# delete old debs
#-------------------------------------------
mkdir -p /tb2/build/$RELNAME-php8
rm -rf /tb2/build/$RELNAME-php8/*deb
mkdir -p /root/src/php8
rm -rf /root/src/php8/*deb


# Compiling all packages
#-------------------------------------------
cd /root/src/php8
find /root/src/php8 -maxdepth 1 -mindepth 1 -type d | grep -v "git-phpredis" |
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
	printf "\n\n$adir \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
	sleep 1

	if [ -e "debian/changelog" ]; then
		AISITS=$(cat debian/changelog | head -n1 | grep "aisits" | wc -l)
		if [[ $AISITS -lt 1 ]]; then
			VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
			VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
			printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
		fi
	fi

	if [ -n "$VEROVR" ]; then
		VERNEXT=$VEROVR
		printf "\n by VEROVR \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
	fi


	dch -p -b "backport to $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
	-v "$VERNEXT+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
	head debian/changelog

	if [[ $adir == *"redis"* ]]; then
		printf "\n\n\n --- its PHP-REDIS -- do rsync $adir \n"
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		/root/src/php8/git-phpredis $adir
		pwd
		printf "\n\n\n"
	fi

	# free -g; sleep 1

	NUMINS=$(ps -e -o command | grep -v grep | grep "dk-build-full" | awk '{print $NF}' | wc -l)
	if [[ $NUMINS -lt 3 ]]; then
		doback
	else
		dofore
	fi
done



# delete unneeded packages
#-------------------------------------------

cd /root/src/php8
find /root/src/php8/ -type f -iname "*udeb" -delete
find /root/src/php8/ -type f -iname "*dbgsym*deb" -delete
find /root/src/php8/ -type f -iname "php5*deb" -delete
find /root/src/php8/ -type f -iname "php7*deb" -delete


# test install
#-------------------------------------------

# dpkg --force-all -i php8*deb php-common*deb || apt install -fy --allow-downgrades
# apt install -fy --fix-broken  --allow-downgrades --allow-change-held-packages


# NONCUS=$(dpkg -l | grep php8 | grep -v aisits | wc -l)
# printf "\n\n NON custom packages: $NONCUS \n\n"


# upload to /tb2/build/{$RELNAME}-php8
#-------------------------------------------
export RELNAME=$(lsb_release -sc)
mkdir -p /tb2/build/$RELNAME-php8
cp *.deb /tb2/build/$RELNAME-php8/ -Rfa
ls -la /tb2/build/$RELNAME-php8/
