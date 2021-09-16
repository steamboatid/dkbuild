#!/bin/bash

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

doback_bash(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}

