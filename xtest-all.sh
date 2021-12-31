#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh



kill_current_scripts(){
	PID=$$
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

do_testing(){
	alxc="$1"

	lxc-start -qn $alxc
	lxc-attach -n $alxc -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | tee /var/log/dkbuild/dk-$alxc-init.log
	lxc-attach -n $alxc -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | tee /var/log/dkbuild/dk-$alxc-install.log
	sleep 1
}

kill_current_scripts
kill_current_scripts


mkdir -p /var/log/dkbuild

do_testing "tbus" >/dev/null 2>&1 &
do_testing "teye" >/dev/null 2>&1 &
sleep 1

printf "\n\n\n wait... "
wait_jobs
printf "\n\n\n wait... "
wait < <(jobs -p)

printf "\n\n --- clear nginx cache "
/bin/bash /root/clear-nginx-cache.sh

printf "\n\n done. \n\n"
