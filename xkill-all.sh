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
fix_relname_relver_bookworm
fix_apt_bookworm



ps auxw | grep -v grep | grep "xbuild\|xtest\|dk\-" | \
grep ".sh" | awk '{print $2}' | xargs kill -9  >/dev/null 2>&1
killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
sleep 1

ps auxw | grep -v grep | grep "xbuild\|xtest\|dk\-" | \
grep ".sh" | awk '{print $2}' | xargs kill -9  >/dev/null 2>&1
killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1

ps auxw | grep -v grep | grep "xbuild\|xtest\|dk\-"