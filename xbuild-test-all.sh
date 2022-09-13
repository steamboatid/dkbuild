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

printf "\n\n --- apt upgrade \n"
lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-apt-upgrade.sh
lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-apt-upgrade.sh
lxc-attach -n wor -- /bin/bash /tb2/build-devomd/dk-apt-upgrade.sh
sleep 1

printf "\n\n --- prep-all \n"
lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-all.sh   2>&1 | \
	tee /var/log/dkbuild/dk-bus-prep.log >/dev/null 2>&1 &
lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-all.sh   2>&1 | \
	tee /var/log/dkbuild/dk-eye-prep.log >/dev/null 2>&1 &
lxc-attach -n wor -- /bin/bash /tb2/build-devomd/dk-prep-all.sh   2>&1 | \
	tee /var/log/dkbuild/dk-wor-prep.log >/dev/null 2>&1 &
wait
sleep 1


printf "\n\n --- build-all \n"
lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-build-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-bus-build.log >/dev/null 2>&1 &
lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-eye-build.log >/dev/null 2>&1 &
lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-wor-build.log >/dev/null 2>&1 &
wait
sleep 1


printf "\n\n --- xrepo-rebuild \n"
/bin/bash /tb2/build-devomd/xrepo-rebuild.sh  2>&1 | tee /var/log/dkbuild/dk-devomd-repo-rebuild.log
sleep 1
printf "\n\n --- clear nginx cache \n"
/bin/bash /root/clear-nginx-cache.sh


printf "\n\n --- test-all \n"
/bin/bash $MYDIR/xtest-all.sh
wait

printf "\n\n done. \n\n"
