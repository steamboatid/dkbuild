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



# read command parameter
#-------------------------------------------
# while getopts d:y:a: flag
while getopts a: flag
do
	case "${flag}" in
		a) alxc=${OPTARG};;
	esac
done

if [ -z "${alxc}" ]; then
	printf "\n --- Usage: $0 ${red}-a <lxc_container_name>${end} "
	exit
fi

printf "\n ---  stop: $alxc "
lxc-stop -kn $alxc
sleep 0.1

printf "\n --- start: $alxc "
lxc-start -qn $alxc
sleep 0.5


ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1 | wc -l)
ip6=$(/sbin/ip -o -6 addr list eth0 | awk '{print $4}' | cut -d/ -f1 | wc -l)

if [[ $ip4 -lt 1 ]] && [[ $ip6 -lt 1 ]]; then
	printf "\n --- get IP: "
	lxc-attach -n $alxc -- dhclient eth0
	sleep 0.2
fi

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
printf "\n ---   ip4: $ip4 "

printf "\n --- preps: scripts $alxc "
lxc-attach -n $alxc -- rm -rf /usr/local/sbin/dk*sh /usr/local/sbin/x*sh /usr/local/sbin/y*sh /usr/local/sbin/z*sh
lxc-attach -n $alxc -- ln -sf /tb2/build/*sh /usr/local/sbin/
lxc-attach -n $alxc -- chmod +x /tb2/build/*sh /usr/local/sbin/* -f

printf "\n\n"
