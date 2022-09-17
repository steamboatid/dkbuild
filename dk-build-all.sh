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
export ERRBASE=0


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relname_bookworm
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






doback(){
	/usr/bin/nohup /bin/bash $1 -l "$2" >/dev/null 2>&1 &
	printf "\n\n exec back: $1 at $2 \n\n\n"
	sleep 1
}

wait_build_full(){
	printf "\n\n --- wait all background build jobs: "
	numo=0
	while :; do
		numa=$(ps auxw | grep -v grep | grep "dk-build-full" | wc -l)
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

check_installed_pkgs(){
	printf "\n\n"
	export ERRBASE=0
	if [[ $(dpkg -l | grep "^ii" | grep db4 | grep omd | wc -l) -lt 1 ]]; then
		printf "\n --- ${red}db4 fatal failed ${end}"
		export ERRBASE=1
	fi
	if [[ $(dpkg -l | grep "^ii" | grep pcre | grep omd | wc -l) -lt 1 ]]; then
		printf "\n --- ${red}pcre fatal failed ${end}"
		export ERRBASE=1
	fi
	if [[ $(dpkg -l | grep "^ii" | grep zip | grep omd | wc -l) -lt 1 ]]; then
		printf "\n --- ${red}libzip fatal failed ${end}"
		export ERRBASE=1
	fi

	if [[ $ERRBASE -gt 0 ]]; then
		printf "\n\n --- ${red}base packages: fatal failed ${end} \n\n"
		exit 1
	else
		printf "\n\n --- ${green}base packages: OK ${end} \n\n"
		sleep 3
	fi
}



# reset default build flags, stop services
#-------------------------------------------
reset_build_flags
prepare_build_flags
stop_services


# gen config
#-------------------------------------------
/bin/bash /tb2/build-devomd/dk-config-gen.sh -h "$alxc"


#--- delete OLD files
mkdir -p /root/org.src /root/src /tb2/build-devomd/$RELNAME-all
find -L /root/src -type f -iname "*deb" -delete
find -L /tb2/build-devomd/$RELNAME-all -type f -iname "*deb" -delete


# some job at foreground: build & istall base packages
#-------------------------------------------
doback_bash /tb2/build-devomd/dk-build-libzip.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-pcre.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-db4.sh "$alxc"

wait_build_full
check_installed_pkgs


# some job at background
#-------------------------------------------
doback_bash /tb2/build-devomd/dk-build-nutcracker.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-keydb.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-lua-resty-lrucache.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-lua-resty-core.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-sshfs-fuse.sh "$alxc"


# some job at foreground, wait first
#-------------------------------------------
wait_build_full
doback_bash /tb2/build-devomd/dk-build-nginx.sh "$alxc"
doback_bash /tb2/build-devomd/dk-build-php8.sh "$alxc"


# wait all background jobs
#-------------------------------------------
wait_build_full


# check if any fails
#-------------------------------------------
# dpkg-buildpackage: info: binary-only upload (no source included)
check_build_log


#--- delete unneeded files
find -L /root/src -maxdepth 3 -type f -iname "*udeb" -delete
find -L /root/src -maxdepth 3 -type f -iname "*dbgsym*deb" -delete


#--- delete old debs
mkdir -p /tb2/build-devomd/$RELNAME-all
rm -rf /tb2/build-devomd/$RELNAME-all/*deb


#--- COPY to $RELNAME-all
printf "\n\n\n-- copying files to /tb2/build-devomd/$RELNAME-all/ \n\n"

for afile in $(find -L /root/src -type f -name "*deb" | sort -u | sort); do
	printf "\n $afile "
	cp $afile /tb2/build-devomd/$RELNAME-all/ -f
done
printf "\n\n"

NUMDEBS=$(find -L /root/src -type f -name "*deb" | wc -l)
printf "\n NUMDEBS= $NUMDEBS \n\n"

# debs nums
numLUA=$(find   /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "lua"   | wc -l)
numNGINX=$(find -L /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nginx" | wc -l)
numPHPA=$(find  /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php"   | wc -l)
numPHP8=$(find  /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "php8"  | wc -l)
numKEYDB=$(find -L /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "keydb" | wc -l)
numNUTC=$(find  /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "nutcr" | wc -l)
numLZIP=$(find  /tb2/build-devomd/$RELNAME-all -iname "*deb" | grep -v "dbg\|udeb" | grep "zip"   | wc -l)

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

for afile in $(find -L /root/src -type f -name "*dsc" | sort -u | sort); do
	printf "\n $afile "
	cat $afile | grep -i vcs | awk '{print $NF}' | sort -u >>/tmp/all.git
done
cat /tmp/all.git | grep "http" | sort -u | sort >/root/all.git


# rebuild the repo
#-------------------------------------------
# #--- nohup ssh devomd "nohup /bin/bash /tb2/build-devomd/xrepo-rebuild.sh >/dev/null 2>&1 &" >/dev/null 2>&1 &
# printf "\n\n\n === rebuild the repo \n"
# /bin/bash /tb2/build-devomd/xrepo-rebuild.sh -h "$alxc"  >/dev/null 2>&1


printf "\n\n --- done \n\n\n"
