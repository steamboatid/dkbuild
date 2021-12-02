#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then apt update; apt install -fy lsb-release; fi
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

wait_build_full(){
	printf "\n\n --- wait all background build jobs: "
	numo=0
	while :; do
		numa=$(ps auxw | grep -v grep | grep "dk-build-full.sh" | wc -l)
		if [[ $numa -lt 1 ]]; then break; fi
		if [[ $numa -ne $numo ]]; then
			printf " $numa"
			numo=$numa
		else
			printf "."
		fi
		sleep 3
	done

	wait
	sleep 1
}



# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



#--- delete OLD files
find /root/src -type f -iname "*deb" -delete
find /tb2/build/$RELNAME-all/ -type f -iname "*deb" -delete



# some job at foreground: build & istall base packages
#-------------------------------------------
doback_bash /tb2/build/dk-build-libzip.sh &
doback_bash /tb2/build/dk-build-pcre.sh


# some job at background
#-------------------------------------------
doback_bash /tb2/build/dk-build-nutcracker.sh &
doback_bash /tb2/build/dk-build-keydb.sh &
doback_bash /tb2/build/dk-build-lua-resty-lrucache.sh &
doback_bash /tb2/build/dk-build-lua-resty-core.sh &
doback_bash /tb2/build/dk-build-sshfs-fuse.sh &


# some job at foreground, wait first
#-------------------------------------------
wait_build_full
doback_bash /tb2/build/dk-build-nginx.sh &


# build & install db4 first, then php
#-------------------------------------------
if /bin/bash /tb2/build/dk-build-db4.sh; then
	printf "\n\n\n"
	sleep 1
	/bin/bash /tb2/build/dk-build-php8.sh
fi

printf "\n\n\n"
sleep 1


# wait all background jobs
#-------------------------------------------
wait_build_full


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

for afile in $(find /root/src -type f -name "*deb" | sort -u | sort); do
	printf "\n $afile "
	cp $afile /tb2/build/$RELNAME-all/ -f
done
printf "\n\n"

NUMDEBS=$(find /root/src -type f -name "*deb" | wc -l)
printf "\n NUMDEBS= $NUMDEBS \n\n"

# debs nums
numLUA=$(find   /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "lua"   | wc -l)
numNGINX=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nginx" | wc -l)
numPHPA=$(find  /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php"   | wc -l)
numPHP8=$(find  /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php8"  | wc -l)
numKEYDB=$(find /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "keydb" | wc -l)
numNUTC=$(find  /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nutcr" | wc -l)
numLZIP=$(find  /tb2/build/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "zip"   | wc -l)

printf "\n lua:    $numLUA"
printf "\n nginx:  $numNGINX"
printf "\n phpAll: $numPHPA"
printf "\n php8:   $numPHP8"
printf "\n keydb:  $numKEYDB"
printf "\n nutc:   $numNUTC"
printf "\n lzip:   $numLZIP"
printf "\n\n\n"


#--- save all git for future used
>/tmp/all.git
>/root/all.git

for afile in $(find /root/src -type f -name "*dsc" | sort -u | sort); do
	printf "\n $afile "
	cat $afile | grep -i vcs | awk '{print $NF}' | sort -u >>/tmp/all.git
done
cat /tmp/all.git | grep "http" | sort -u | sort >/root/all.git


# rebuild the repo
#-------------------------------------------
nohup ssh argo "nohup /bin/bash /tb2/build/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &


printf "\n\n --- done \n\n\n"
