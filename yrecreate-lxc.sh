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
while getopts l:r: flag
do
	case "${flag}" in
		r) arel=${OPTARG};;
		l) alxc=${OPTARG};;
	esac
done

if [[ -z "${alxc}" ]] || [[ -z "${arel}" ]]; then
	printf "\n --- Usage:   $0 ${blue}-l <a_LXC_name> -r <debian_release>${end} "
	printf "\n --- Example: $0 ${blue}-l teye -r bullseye${end} "
	printf "\n\n"
	exit 1
fi


mkdir -p /root/lxc-conf
cp /var/lib/lxc/$alxc/config /root/lxc-conf/$alxc.config -fv

lxc-destroy -fsn $alxc

# actual create
lxc-create -n $alxc -t download \
-- --dist debian --release $arel --arch amd64 \
--force-cache --no-validate --server images.linuxcontainers.org \
--keyserver hkp://p80.pool.sks-keyservers.net:80

# copy config file back
mv /var/lib/lxc/$alxc/config /var/lib/lxc/$alxc/config.old
cp /root/lxc-conf/$alxc.config /var/lib/lxc/$alxc/config -fv

lxc-start -n $alxc
