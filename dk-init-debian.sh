#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then apt update; apt install -fy lsb-release; fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh

# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



init_prep() {
	echo \
"nameserver 1.1.1.1
nameserver 8.8.8.8
"> /etc/resolv.conf
}

init_buster() {
	echo \
'deb http://repo.aisits.id/debian buster main contrib non-free
deb http://repo.aisits.id/debian-security buster/updates main contrib non-free
deb http://repo.aisits.id/debian buster-updates main contrib non-free
deb http://repo.aisits.id/debian buster-proposed-updates main contrib non-free
deb http://repo.aisits.id/debian buster-backports main contrib non-free

deb-src http://repo.aisits.id/debian buster main contrib non-free
deb-src http://repo.aisits.id/debian-security buster/updates main contrib non-free
deb-src http://repo.aisits.id/debian buster-updates main contrib non-free
deb-src http://repo.aisits.id/debian buster-proposed-updates main contrib non-free
deb-src http://repo.aisits.id/debian buster-backports main contrib non-free

deb http://repo.aisits.id/mariadb/repo/10.6/debian buster main
deb http://repo.aisits.id/zabbix/5.5/debian buster main

deb http://repo.aisits.id/mariadb-maxscale buster main
deb http://repo.aisits.id/mariadb-tools buster main
'>/etc/apt/sources.list
}

init_bullseye() {
	echo \
'deb http://repo.aisits.id/debian bullseye main contrib non-free
deb http://repo.aisits.id/debian bullseye-updates main contrib non-free
deb http://repo.aisits.id/debian bullseye-proposed-updates main contrib non-free

deb-src http://repo.aisits.id/debian bullseye main contrib non-free
deb-src http://repo.aisits.id/debian bullseye-updates main contrib non-free
deb-src http://repo.aisits.id/debian bullseye-proposed-updates main contrib non-free

deb http://repo.aisits.id/debian bullseye-backports main contrib non-free
deb-src http://repo.aisits.id/debian bullseye-backports main contrib non-free

deb http://repo.aisits.id/debian-security bullseye-security main
deb-src http://repo.aisits.id/debian-security bullseye-security main

deb http://repo.aisits.id/mariadb/repo/10.6/debian bullseye main
deb http://repo.aisits.id/zabbix/5.5/debian bullseye main
'>/etc/apt/sources.list
}

init_apt_keys() {
	echo \
'Acquire::Queue-Mode "host";
Acquire::Languages "none";
Acquire::http { Pipeline-Depth "200"; };
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
'>/etc/environment

	export PATH=$PATH:/usr/sbin
	timedatectl set-timezone Asia/Jakarta


	pkgs=(locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
	gnupg2 apt-utils tzdata curl rsync lsb-release eatmydata nano)
	install_old $pkgs && \

	echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen && dpkg-reconfigure locales &&\
	apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys 2>&1 | grep --color "processed" &&\

	apt update >/dev/null 2>&1
	aptold full-upgrade --auto-remove --purge -fy >/dev/null 2>&1
}

init_ssh() {
	pkgs=(ssh openssh-server)
	install_new $pkgs

	if [[ $(grep "^PermitRootLogin" /etc/ssh/sshd_config | wc -l) -lt 1 ]]; then
		sed -i "s/\#PermitRootLogin prohibit-password/PermitRootLogin yes\n#PermitRootLogin prohibit-password/g" /etc/ssh/sshd_config
		cat /etc/ssh/sshd_config | grep -i permitroot
		/etc/init.d/ssh restart
	fi

	if [ ! -e "$HOME/.ssh/id_rsa" ]; then
		ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""
	fi
}

init_basic_packages() {
	pkgs=(eatmydata nano rsync libterm-readline-gnu-perl apt-utils lsb-release locales net-tools dnsutils)
	install_old $pkgs
}




# main
#-------------------------------------------
init_prep

if [[ "${RELNAME}" = "buster" ]]; then
	init_buster
elif [[ "${RELNAME}" = "bullseye" ]]; then
	init_bullseye
fi
cat /etc/apt/sources.list

init_apt_keys
init_ssh
init_basic_packages
