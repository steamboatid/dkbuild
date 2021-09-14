#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)


clean_apt_cache() {
	find /var/lib/apt/lists/ -type f -delete; \
	find /var/cache/apt/ -type f -delete; \
	rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
	/etc/apt/preferences.d/00-revert-stable \
	/var/cache/debconf/ /var/lib/apt/lists/* \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
	mkdir -p /root/.local/share/nano/ /root/.config/procps/
	apt clean
	apt update
	dpkg --configure -a
}

remove_non_base() {
	cd `mktemp -d`; \
	apt purge --auto-remove --purge -fy \
	nginx* keydb* nutcracker* php* apache2* rsyslog* unattended-upgrades apparmor \
	anacron msttcorefonts ttf-mscorefonts-installer needrestart lua*dev lib*dev php*dev \
	xserver* xorg* x11* cups* tex* nvidia*

	rm -rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb /usr/lib/php \
	/etc/keydb /etc/nutcracker /etc/php /etc/nginx \
	/lib/systemd/system/keydb* /etc/init.d/keydb* \
	/lib/systemd/system/nutcracker* /etc/init.d/nutcracker* \
	/lib/systemd/system/nginx* /etc/init.d/nginx* \
	/lib/systemd/system/php* /etc/init.d/php*
}

reinstall_base() {
	aptcheck=$(dpkg -l | grep aptitude | wc -l)
	if [[ $aptcheck -lt 1 ]]; then apt install -fy aptitude; fi

	dpkg-query -Wf '${Package;-40}${Essential}\n' | grep yes | awk '{print $1}' > /tmp/ess
	dpkg-query -Wf '${Package;-40}${Priority}\n' | grep -E "required" | awk '{print $1}' >> /tmp/ess
	aptitude search ~E 2>&1 | awk '{print $2}' >> /tmp/ess
	aptitude search ~prequired -F"%p" >> /tmp/ess
	aptitude search ~pimportant -F"%p" >> /tmp/ess

	cat /tmp/ess | sort -u | sort | grep -v "apache2\|rsyslog\|nginx\|php\|keydb\|nutcracker"  | tr '\n' ' ' | \
	xargs apt install --reinstall --fix-missing --install-suggests \
	--fix-broken  --allow-downgrades --allow-change-held-packages -fy
}



clean_apt_cache

remove_non_base
remove_non_base

reinstall_base
