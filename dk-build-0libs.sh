#!/bin/bash


# bash colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
blue=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'


# reset default build flags
#-------------------------------------------
reset_build_flags() {
	echo \
"STRIP CFLAGS -O2
STRIP CXXFLAGS -O2
STRIP LDFLAGS -O2

PREPEND CFLAGS -O3
PREPEND CPPFLAGS -O3 -g
PREPEND CXXFLAGS -O3
">/etc/dpkg/buildflags.conf
}


# exec bash script at back
#-------------------------------------------
doback_bash(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}

