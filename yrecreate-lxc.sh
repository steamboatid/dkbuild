#!/bin/bash


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
