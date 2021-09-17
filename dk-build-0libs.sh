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
"STRIP CFLAGS -O2 -g
STRIP CXXFLAGS -O2 -g
STRIP LDFLAGS -O2 -g

PREPEND CFLAGS -O3
PREPEND CPPFLAGS -O3
PREPEND CXXFLAGS -O3
PREPEND LDFLAGS -Wl,-s
">/etc/dpkg/buildflags.conf
}


# exec bash script at back
#-------------------------------------------
doback_bash(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}


# check if any fails
#-------------------------------------------
check_build_log() {
	DEPS="/tmp/dependencies.log"
	>$DEPS

	printf "\n\n"
	export TOTFAIL=0
	for alog in $(find /root/src -iname "dkbuild.log" | sort -u); do
		printf "\n check $alog \t"
		NUMFAIL=$(grep "buildpackage" ${alog} | grep failed | wc -l)
		NUMSUCC=$(grep "buildpackage" ${alog} | grep "binary-only upload" | wc -l)
		if [[ $NUMSUCC -lt 1 ]] || [[ $NUMFAIL -gt 0 ]]; then
			grep "buildpackage" ${alog} | grep failed
			TOTFAIL=$((TOTFAIL+1))
			printf " FAILS = $NUMFAIL TOTAL = $TOTFAIL "
		fi
		# printf "\n\n\n\tFAILS = $NUMFAIL --- TOTAL = $TOTFAIL \n\n"

		NUMDEPS=$(grep -i "unmet" ${alog} | grep -i "dependencies" | wc -l)
		if [[ $NUMDEPS -gt 0 ]]; then
			grep -i "unmet" ${alog} | grep -i "dependencies" >> $DEPS
		fi
	done
	sleep 0.1

	cat $DEPS | tr -d "\n" > /tmp/deps.tmp
	mv /tmp/deps.tmp $DEPS
	cat $DEPS

	if [[ ${TOTFAIL} -gt 0 ]]; then
		printf "\n\n\n\t TOTAL FAILS = $TOTFAIL\n\n"
		exit $TOTFAIL; # exit as error
	fi
	printf "\n\n"
}