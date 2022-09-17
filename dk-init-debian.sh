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
fix_relname_bookworm
fix_apt_bookworm




# gen config
#-------------------------------------------
/bin/bash /tb2/build-devomd/dk-config-gen.sh


# fill /var/cache/apt/archives/
#-------------------------------------------
# get_local_debs >/dev/null 2>&1 &



reset_apt(){
	systemctl daemon-reload; \
	systemctl daemon-reexec; \
	systemctl restart systemd-resolved.service; \
	systemctl restart systemd-timesyncd.service; \
	killall -9 apt; sleep 1; killall -9 apt; \
	killall -9 apt; sleep 1; killall -9 apt; \
	find -L /var/lib/apt/lists/ -type f -delete; \
	find -L /var/cache/apt/ -type f -delete; \
	rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
	/etc/apt/preferences.d/00-revert-stable \
	/var/cache/debconf/ /var/lib/apt/lists/* \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
	mkdir -p /root/.local/share/nano/ /root/.config/procps/; \
	dpkg --configure -a; \
	apt autoclean; apt clean; apt update --allow-unauthenticated


	apt full-upgrade -fydu --auto-remove --purge --fix-missing \
		-o Dpkg::Options::="--force-overwrite"

	apt update; \
	apt full-upgrade -fy --auto-remove --purge --fix-missing \
		-o Dpkg::Options::="--force-overwrite"
}


init_resolver() {
	if [ -f /etc/init.d/resolvconf ] && [ -f /etc/resolvconf/resolv.conf.d/head ]; then
		echo \
"nameserver 10.0.2.1
nameserver 10.0.3.1

nameserver 192.168.0.1
nameserver 192.168.1.1
nameserver 192.168.8.1
nameserver 192.168.88.1

nameserver 1.1.1.1
nameserver 8.8.8.8
"> /etc/resolvconf/resolv.conf.d/head

		chmod +x /etc/init.d/resolvconf
		/etc/init.d/resolvconf restart
	fi

	if [ -f /etc/resolv.conf ]; then
		echo \
"nameserver 10.0.2.1
nameserver 10.0.3.1

nameserver 192.168.0.1
nameserver 192.168.1.1
nameserver 192.168.8.1
nameserver 192.168.88.1

nameserver 1.1.1.1
nameserver 8.8.8.8
"> /etc/resolv.conf
	fi

	if [[ -f /etc/systemd/resolved.conf ]]; then
		sed -i "s/\#DNS=/DNS=10.0.2.1 10.0.3.1 192.168.0.1 192.168.1.1 192.168.8.1 192.168.88.1/g" /etc/systemd/resolved.conf
		sed -i "s/\#FallbackDNS=/FallbackDNS=1.1.1.1 8.8.8.8/g" /etc/systemd/resolved.conf
		sed -i "s/\#Cache=yes/Cache=yes/g" /etc/systemd/resolved.conf
		# cat /etc/systemd/resolved.conf | grep "DNS="

		systemctl enable systemd-resolved.service
		systemctl restart systemd-resolved.service
		# systemd-resolve --status
	fi
}

init_buster() {
	echo \
'deb http://deb.debian.org/debian buster main contrib non-free
deb http://deb.debian.org/debian-security buster/updates main contrib non-free
deb http://deb.debian.org/debian buster-updates main contrib non-free
deb http://deb.debian.org/debian buster-proposed-updates main contrib non-free
deb http://deb.debian.org/debian buster-backports main contrib non-free

deb-src http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian-security buster/updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-proposed-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-backports main contrib non-free
'>/etc/apt/sources.list
}

init_bullseye() {
	echo \
'deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free

deb-src http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free

deb http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian-security bullseye-security main
'>/etc/apt/sources.list
}

init_bookworm() {
	echo \
'deb http://deb.debian.org/debian bookworm main contrib non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free
deb http://deb.debian.org/debian bookworm-proposed-updates main contrib non-free

deb-src http://deb.debian.org/debian bookworm main contrib non-free
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian bookworm-proposed-updates main contrib non-free

deb http://deb.debian.org/debian-security bookworm-security main
deb-src http://deb.debian.org/debian-security bookworm-security main
'>/etc/apt/sources.list

	mkdir -p /etc/apt/sources.list.d/
	echo \
'deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free

deb-src http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-proposed-updates main contrib non-free

deb http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian-security bullseye-security main
'>/etc/apt/sources.list.d/bullseye.list
}

init_db4(){
	mkdir -p /etc/apt/sources.list.d/
	echo \
'deb https://ppa.launchpadcontent.net/sickpig/db4.8/ubuntu xenial main
deb-src https://ppa.launchpadcontent.net/sickpig/db4.8/ubuntu xenial main
'>/etc/apt/sources.list.d/db48.list
	apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 4D44E2F3A9D33F98
}

init_apt_keys() {
	echo \
'Acquire::Queue-Mode "host";
Acquire::Languages "none";
Acquire::http { Pipeline-Depth "1"; };
Acquire::https { Verify-Peer false; };
'>/etc/apt/apt.conf.d/99translations

	echo \
'APT::Get::AllowUnauthenticated "true";
Acquire::Check-Valid-Until "false";
Acquire::AllowDowngradeToInsecureRepositories "true";
Acquire::AllowInsecureRepositories "true";
APT::Ignore "gpg-pubkey";
Acquire::ForceIPv4 "true";

APT::Authentication::TrustCDROM "true";
Acquire::cdrom::mount "/media/cdrom";
Dir::Media::MountPath "/media/cdrom";

APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";

APT::Install-Recommends "false";
APT::Install-Suggests "false";

Binary::apt::APT::Keep-Downloaded-Packages "true";
APT::Keep-Downloaded-Packages "true";

Acquire::EnableSrvRecords "false";
APT::FTPArchive::AlwaysStat "false";

APT::Cache-Limit "1000000000";
'>/etc/apt/apt.conf.d/98more

	echo \
'export HISTFILESIZE=100000
export HISTSIZE=100000

#-- encodings
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
'>/etc/environment && source /etc/environment

	export PATH=$PATH:/usr/sbin
	timedatectl set-timezone Asia/Jakarta

	apkg="gnupg2 gpgv"
	if [[ "${RELNAME}" = "buster" ]]; then
		apkg="gnupg2"
	fi


	apt update; \
	pkgs=(locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
	$apkg apt-utils tzdata curl rsync lsb-release eatmydata nano)
	install_old $pkgs \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && dpkg-reconfigure locales &&\
	# apt-key adv --fetch-keys http://repo.omd.id/trusted-keys 2>&1 | grep --color "processed"

	if [[ -e /tb2/phideb/trusted-keys ]]; then
		cat /tb2/phideb/trusted-keys | gpg --dearmor > /etc/apt/trusted.gpg.d/trusted-keys.gpg
	fi

	aptold update 2>&1
	aptold full-upgrade --auto-remove --purge -fy  \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"
}

init_ssh() {
	pkgs=(ssh openssh-server)
	install_new $pkgs

	if [[ $(grep "^PermitRootLogin" /etc/ssh/sshd_config | wc -l) -lt 1 ]]; then
		sed -i -r "s/\#PermitRootLogin prohibit-password/PermitRootLogin yes\n#PermitRootLogin prohibit-password/g" /etc/ssh/sshd_config
		cat /etc/ssh/sshd_config | grep -i permitroot
		/etc/init.d/ssh restart
	fi

	if [ ! -e "$HOME/.ssh/id_rsa" ]; then
		ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""
	fi
}

init_basic_packages() {
	pkgs=(eatmydata nano rsync libterm-readline-gnu-perl apt-utils lsb-release \
	locales locales-all net-tools dnsutils \
	apt aptitude apt-utils nload zstd jq)
	install_old $pkgs
}

init_apt_proxy(){
	echo \
'Acquire {
  ftp::proxy "http://10.0.3.1:3128";
  http::proxy "http://10.0.3.1:3128";
  https::proxy "http://10.0.3.1:3128";
}'>/etc/apt/apt.conf.d/02proxy
}

init_apt_pref_php8x(){
	echo \
'Package: php5*
Pin: release *
Pin-Priority: -1

Package: php7.0*
Pin: release *
Pin-Priority: -1

Package: php7.1*
Pin: release *
Pin-Priority: -1

Package: php7.2*
Pin: release *
Pin-Priority: -1

Package: php7.3*
Pin: release *
Pin-Priority: -1
'>/etc/apt/preferences.d/dkbuild.pref
}


# main
#-------------------------------------------

# fixed ip
systemctl stop systemd-networkd
systemctl disable systemd-networkd


apt autoclean >/dev/null 2>&1; apt clean >/dev/null 2>&1
init_resolver
init_apt_proxy &
>/etc/apt/preferences.d/dkbuild.pref
# init_apt_pref_php8x &

printf "\n --- wait...\n"
wait


if [[ "${RELNAME}" = "buster" ]]; then
	init_buster
elif [[ "${RELNAME}" = "bullseye" ]]; then
	init_bullseye
elif [[ "${RELNAME}" = "bookworm" ]]; then
	init_bookworm
	fix_apt_bookworm
fi
cat /etc/apt/sources.list

reset_apt

init_db4
init_apt_keys
init_ssh
init_basic_packages

# reinstall_essential

if [[ "${RELNAME}" = "bookworm" ]]; then
	apt install -fy libssl1.1 libssl3 libssl-dev libffi7 libffi8 libffi-dev
fi

#--- saving
# save_local_debs >/dev/null 2>&1 &
