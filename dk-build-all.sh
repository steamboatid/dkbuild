#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

apt install -fy lsb-release
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh



doback(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}


# reset default build flags
#-------------------------------------------
reset_build_flags



# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



#--- delete OLD files
find /root/src -type f -iname "*deb" -delete
find /tb2/build/$RELNAME-all/ -type f -iname "*deb" -delete



# some job at background
#-------------------------------------------
doback_bash /tb2/build/dk-build-nutcracker.sh &
doback_bash /tb2/build/dk-build-keydb.sh &
doback_bash /tb2/build/dk-build-pcre.sh &
doback_bash /tb2/build/dk-build-lua-resty-lrucache.sh &
doback_bash /tb2/build/dk-build-lua-resty-core.sh &
doback_bash /tb2/build/dk-build-libzip.sh &


# some job at foreground
#-------------------------------------------
/bin/bash /tb2/build/dk-build-nginx.sh
printf "\n\n\n"
sleep 1

/bin/bash /tb2/build/dk-build-php8.sh
printf "\n\n\n"
sleep 1


# wait all background jobs
#-------------------------------------------
wait
sleep 1


# check if any fails
#-------------------------------------------
# dpkg-buildpackage: info: binary-only upload (no source included)
check_build_log


#--- delete unneeded files
find /root/src -type f -iname "*udeb" -delete
find /root/src -type f -iname "*dbgsym*deb" -delete


#--- delete old debs
mkdir -p /tb2/build/$RELNAME-all
rm -rf /tb2/build/$RELNAME-all/*deb


#--- COPY to $RELNAME-all
printf "\n\n\n-- copying files to /tb2/build/$RELNAME-all/ \n\n"

find /root/src -type f -name "*deb" | sort -u | sort |
while read afile; do
	printf "\n $afile "
	cp $afile /tb2/build/$RELNAME-all/ -f
done
printf "\n\n"

NUMDEBS=$(find /root/src -type f -name "*deb" | wc -l)
printf "\n NUMDEBS= $NUMDEBS \n"

# debs nums
numLUA=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "lua" | wc -l)
numNGINX=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nginx" | wc -l)
numPHP=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php" | wc -l)
numPHP8=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php8" | wc -l)
numKEYDB=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "keydb" | wc -l)
numNUTC=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nutcracker" | wc -l)
printf "\n lua:    $numLUA"
printf "\n nginx:  $numNGINX"
printf "\n php:    $numPHP"
printf "\n php8:   $numPHP8"
printf "\n keydb:  $numKEYDB"
printf "\n nutc:   $numNUTC"


#--- save all git for future used
>/tmp/all.git
>/root/all.git
find /root/src -type f -name "*dsc" | sort -u | sort |
while read afile; do
	printf "\n $afile "
	cat $afile | grep -i vcs | awk '{print $NF}' | sort -u >>/tmp/all.git
done
cat /tmp/all.git | grep "http" | sort -u | sort >/root/all.git
