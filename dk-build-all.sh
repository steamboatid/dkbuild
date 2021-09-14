#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

apt install -fy lsb-release
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)


doback(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}

#--- check .bashrc
if [ `cat ~/.bashrc | grep alias | grep "find -L" | wc -l` -lt 1 ]; then
	echo "find alias not found"
	echo "alias find='find -L'" >> ~/.bashrc
fi
source ~/.bashrc


#--- delete OLD files
find /root/src -type f -iname "*deb" -delete
find /tb2/build/$RELNAME-all/ -type f -iname "*deb" -delete



# some job at background
#-------------------------------------------
doback /tb2/build/dk-build-nutcracker.sh &
doback /tb2/build/dk-build-keydb.sh &
doback /tb2/build/dk-build-pcre.sh &
doback /tb2/build/dk-build-lua-resty-lrucache.sh &
doback /tb2/build/dk-build-lua-resty-core.sh &


# some job at foreground
#-------------------------------------------
/tb2/build/dk-build-nginx.sh
printf "\n\n\n"
sleep 1

/tb2/build/dk-build-php8.sh
printf "\n\n\n"
sleep 1


# wait all background jobs
#-------------------------------------------
wait
sleep 1


# check if any fails
#-------------------------------------------
printf "\n\n\n"
find /root/src -iname "dkbuild.log" | sort -u |
while read alog; do
	printf "\n check $alog \t"
	NUMFAIL=$(grep "buildpackage" ${alog} | grep failed | wc -l)
	if [[ $NUMFAIL -gt 0 ]]; then
		grep "buildpackage" ${alog} | grep failed
	fi
	printf "\n\n\n\tFAILS = $NUMFAIL\n\n"
done
printf "\n\n\n"


#--- delete unneeded files
find /root/src -type f -iname "*udeb" -delete
find /root/src -type f -iname "*dbgsym*deb" -delete


#--- delete old debs
mkdir -p /tb2/build/$RELNAME-all
rm -rf /tb2/build/$RELNAME-all/*deb


printf "\n\n\n-- copying files to /tb2/build/$RELNAME-all/ \n\n"

find /root/src -type f -name "*deb" |
while read afile; do
	printf "\n $afile "
	cp $afile /tb2/build/$RELNAME-all/ -f
done
printf "\n\n"

NUMDEBS=$(find /root/src -type f -name "*deb" | wc -l)
printf "\n NUMDEBS= $NUMDEBS \n\n"
