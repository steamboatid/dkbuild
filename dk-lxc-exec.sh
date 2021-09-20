#!/bin/bash

usage() {
	echo "\n Usage: $0 -n <container_name> -d <distro_name> \n\n" 1>&2;
	exit 1;
}

while getopts d:n: flag
do
	case "${flag}" in
		d) adist=${OPTARG};;
		n) aname=${OPTARG};;
	esac
done

printf "\n Distro: $adist"
printf "\n Name:   $aname \n\n"

if [ -z "${adist}" ] || [ -z "${aname}" ]; then
  usage
fi

lxcrun () {
	acom=$1
	lxc-attach -n $aname -- sh -c "${acom}"
}


lxc-destroy -f -s -n $aname

lxc-create -n $aname -t download \
-- --dist debian --release $adist --arch amd64 \
--force-cache --no-validate --server images.linuxcontainers.org \
--keyserver hkp://p80.pool.sks-keyservers.net:80

sleep 0.5
lxc-start -n $aname

sleep 0.5
lxcrun "mkdir -p /tb2; \
echo 'nameserver 1.1.1.1' > /etc/resolv.conf; \
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; \
cat /etc/resolv.conf; \
ip a; ip r; ping 1.1.1.1 -c3; ping yahoo.com -c3; dhclient -v"

lxcrun "echo '103.94.190.3    repo.aisits.id argo' >> /etc/hosts"

lxcrun "printf '\
deb http://repo.aisits.id/debian buster main contrib non-free \n\
deb http://repo.aisits.id/debian-security buster/updates main contrib non-free \n\
deb http://repo.aisits.id/debian buster-updates main contrib non-free \n\
deb http://repo.aisits.id/debian buster-proposed-updates main contrib non-free \n\
'>/etc/apt/sources.list; \
apt update; apt install -fy locales locales-all apt-utils libterm-readline-gnu-perl; \
apt install -fy git netbase init eatmydata nano rsync libterm-readline-gnu-perl \
lsb-release net-tools dnsutils"

lxcrun "rm -rf /tb2/build; git clone https://github.com/steamboatid/dkbuild /tb2/build &&\
/bin/bash /tb2/build/dk-init-debian.sh && /bin/bash /tb2/build/zins.sh"
