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

MYFILE=$(which $0)
MYDIR=$(realpath $(dirname $MYFILE))


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_bookworm
fix_apt_bookworm



kill_current_scripts(){
	PID=$1
	ps auxw | grep -v grep | grep "xbuild-test-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	sleep 0.3
	ps auxw | grep -v grep | grep "xtest-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	sleep 0.3
	ps auxw | grep -v grep | grep "dk-" | grep ".sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1

	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
	sleep 0.3
	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
}

build_ops(){
	alxc=$1
	alog="/var/log/dkbuild/dk-$1-prep.log"

	lxc-start -qn $alxc
	>$alog

	printf "\n\n --- init debian -- $alxc \n"
	lxc-attach -n $alxc -- /bin/bash /tb2/build-devomd/dk-init-debian.sh -l "$alxc" \
		2>&1 | tee -a $alog  2>&1 >/dev/null

	printf "\n\n --- apt upgrade -- $alxc \n"
	lxc-attach -n $alxc -- /bin/bash /tb2/build-devomd/dk-apt-upgrade.sh -l "$alxc" \
		2>&1 | tee -a $alog  2>&1 >/dev/null

	isfail=$(cat $alog | grep -i "fatal failed" | wc -l)
	if [[ $isfail -lt 1 ]]; then
		printf "\n\n --- prep-all -- $alxc \n"
		lxc-attach -n $alxc -- /bin/bash /tb2/build-devomd/dk-prep-all.sh -l "$alxc" \
			2>&1 | tee -a $alog  2>&1 >/dev/null
	fi

	isfail=$(cat $alog | grep -i "fatal failed" | wc -l)
	if [[ $isfail -lt 1 ]]; then
		printf "\n\n --- build-all -- $alxc \n"
		lxc-attach -n $alxc -- /bin/bash /tb2/build-devomd/dk-build-all.sh -l "$alxc" \
			2>&1 | tee -a $alog  2>&1 >/dev/null
	fi
}


reset
kill_current_scripts $$
kill_current_scripts $$

rm -rf /var/log/dkbuild
mkdir -p /var/log/dkbuild

printf "\n\n --- stop lxc \n"
lxc-stop -kqn bus
lxc-stop -kqn eye
lxc-stop -kqn wor
lxc-stop -kqn tbus
lxc-stop -kqn teye
lxc-stop -kqn twor
sleep 1

printf "\n\n --- start lxc \n"
lxc-start -qn bus
lxc-start -qn eye
lxc-start -qn wor
lxc-start -qn tbus
lxc-start -qn teye
lxc-start -qn twor
sleep 1

blog="/var/log/dkbuild/dk-prep-build-all.log"
>$blog
build_ops "bus"  2>&1 | tee -a $blog 2>&1 &
build_ops "eye"  2>&1 | tee -a $blog 2>&1 &
build_ops "wor"  2>&1 | tee -a $blog 2>&1 &

printf "\n\n"
aloop=0
while :; do
	sleep 2
	numi=$(ps axww | grep -v grep | grep "dk-" | grep ".sh" | wc -l)
	if [[ $numi -lt 1 ]]; then
		sleep 0.5
		break
	fi
	printf ".${numi} "

	# aloop=$(( aloop+1 ))
	# amod=$(expr $aloop % 15)
	# if [[ $amod -eq 1 ]]; then
	# 	ps w | grep -v grep| grep "dk-" | grep ".sh" | sed -r "s/\s+/ /g" | \
	# 	cut -d" " -f6- | sort -u
	# fi
done
wait
sleep 1

# stop if failed
isfail=$(cat $blog | grep -i "fatal failed" | wc -l)
if [[ $isfail -gt 0 ]]; then
	cat $blog
	exit 1
fi



printf "\n\n --- xrepo-rebuild \n"
/bin/bash /tb2/build-devomd/xrepo-rebuild.sh  2>&1 | tee /var/log/dkbuild/dk-devomd-repo-rebuild.log
sleep 1
printf "\n\n --- clear nginx cache \n"
/bin/bash /root/clear-nginx-cache.sh


printf "\n\n --- test-all \n"
/bin/bash $MYDIR/xtest-all.sh
wait

printf "\n\n done. \n\n"
