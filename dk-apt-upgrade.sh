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


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm




# recheck ip
#-------------------------------------------
islxc=$(cat /proc/1/environ | sed -r 's/container/\ncontainer/g; s/^\n//g' | \
grep -a 'container=lxc' | wc -l)
if [[ $islxc -gt 0 ]]; then
	systemctl daemon-reload
	systemctl daemon-reexec

	if [[ $(grep "buster" /etc/apt/sources.list | wc -l) -gt 0 ]]; then
		rm -rf /etc/resolvconf/run; /etc/init.d/resolvconf restart

		get_dhcp_ip "eth0"

		rm -rf /etc/resolvconf/run; /etc/init.d/resolvconf restart

		if [[ ! -e /etc/resolv.conf ]]; then
			cat << EOT > /etc/resolv.conf
nameserver 192.168.0.1
nameserver 192.168.1.1
nameserver 192.168.8.1
nameserver 192.168.88.1

nameserver 1.1.1.1
nameserver 8.8.8.8
EOT
			/etc/init.d/resolvconf restart
		fi
	else
		systemctl enable systemd-resolved.service
		systemctl restart systemd-resolved.service
		# systemd-resolve --status

		get_dhcp_ip "eth0"

		if [[ ! -e /etc/resolv.conf ]]; then
			cat << EOT > /etc/resolv.conf
nameserver 192.168.0.1
nameserver 192.168.1.1
nameserver 192.168.8.1
nameserver 192.168.88.1

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
/bin/bash /tb2/build-devomd/dk-config-gen.sh


apt update 2>&1 >/dev/null
apt install -fy systemd-timesyncd 2>&1 >/dev/null



systemctl daemon-reload; \
systemctl daemon-reexec; \
systemctl restart systemd-resolved.service; \
systemctl restart systemd-timesyncd.service; \
killall -9 apt; sleep 1; killall -9 apt; \
killall -9 apt; sleep 1; killall -9 apt


find -L /var/lib/apt/lists/ -type f -delete; \
find -L /var/cache/apt/ -type f -delete; \
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


# aptold install -o Dpkg::Options::="--force-overwrite" -fy db4.8* libdb4*
# aptold install -o Dpkg::Options::="--force-overwrite" -fy \
# db4.8-util libdb4.8 libdb4.8-dev \
# libdb4.8++ libdb4.8++-dev \
# 	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"


dpkg -l | grep db4.8 | grep omd | awk '{print $2}' | xargs apt remove -fy

apt-cache search db4.8 | grep -v "cil\|gcj" | \
	awk '{print $1}' | \
	xargs aptold install -o Dpkg::Options::="--force-overwrite" -fy
