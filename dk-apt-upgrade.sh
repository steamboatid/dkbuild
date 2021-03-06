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


source /tb2/build/dk-build-0libs.sh




# recheck ip
#-------------------------------------------
islxc=$(cat /proc/1/environ | sed -r 's/container/\ncontainer/g; s/^\n//g' | \
grep -a 'container=lxc' | wc -l)
if [[ $islxc -gt 0 ]]; then
	systemctl daemon-reload

	if [[ $(grep "buster" /etc/apt/sources.list | wc -l) -gt 0 ]]; then
		rm -rf /etc/resolvconf/run; /etc/init.d/resolvconf restart

		/sbin/dhclient -4 -v -i -pf /run/dhclient.eth0.pid \
		-lf /var/lib/dhcp/dhclient.eth0.leases \
		-I -df /var/lib/dhcp/dhclient6.eth0.leases eth0

		rm -rf /etc/resolvconf/run; /etc/init.d/resolvconf restart

		if [[ ! -e /etc/resolv.conf ]]; then
			cat << EOT > /etc/resolv.conf
nameserver 172.16.0.1
nameserver 172.16.251.1
nameserver 1.1.1.1
nameserver 8.8.8.8
EOT
			/etc/init.d/resolvconf restart
		fi
	else
		systemctl enable systemd-resolved.service
		systemctl restart systemd-resolved.service
		systemd-resolve --status

		/sbin/dhclient -4 -v -i -pf /run/dhclient.eth0.pid \
		-lf /var/lib/dhcp/dhclient.eth0.leases \
		-I -df /var/lib/dhcp/dhclient6.eth0.leases eth0
		systemctl restart systemd-resolved.service

		if [[ ! -e /etc/resolv.conf ]]; then
			cat << EOT > /etc/resolv.conf
nameserver 172.16.0.1
nameserver 172.16.251.1
nameserver 1.1.1.1
nameserver 8.8.8.8
EOT
			systemctl restart systemd-resolved.service
		fi
	fi

	sleep 0.5
	ip a
fi

# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



systemctl daemon-reload; \
systemctl restart systemd-resolved.service; \
systemctl restart systemd-timesyncd.service; \
killall -9 apt; sleep 1; killall -9 apt; \
killall -9 apt; sleep 1; killall -9 apt


find /var/lib/apt/lists/ -type f -delete; \
find /var/cache/apt/ -type f -delete; \
rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
/etc/apt/preferences.d/00-revert-stable \
/var/cache/debconf/ /var/lib/apt/lists/* \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
mkdir -p /root/.local/share/nano/ /root/.config/procps/

apt autoclean
apt clean
apt update --allow-unauthenticated

dpkg --configure -a

aptold full-upgrade --auto-remove --purge --fix-missing -fy \
  -o Dpkg::Options::="--force-overwrite"
