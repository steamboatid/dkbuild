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




# gen config, delete locks
#-------------------------------------------
delete_apt_lock
/bin/bash /tb2/build-devomd/dk-config-gen.sh



if [[ ! -e /run/done.init.dkbuild.txt ]]; then

	# tweaks
	echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io
	aptnew install -y eatmydata lsb-release nano rsync \
		2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"


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

APT::Cache-Limit "100000000";
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


	echo \
"deb [trusted=yes] http://repo.omd.my.id/phideb ${RELNAME} main
#deb-src [trusted=yes] http://repo.omd.my.id/phideb ${RELNAME} main
">/etc/apt/sources.list.d/phideb.list

	>/etc/apt/sources.list.d/nginx-ppa-devel.list
	>/etc/apt/sources.list.d/nginx-devel-omd.list
	>/etc/apt/sources.list.d/php-omd.list
	>/etc/apt/sources.list.d/php-sury.list
	>/etc/apt/sources.list.d/keydb-ppa.list


	cd `mktemp -d`
	aptnew update
	dpkg --configure -a
	aptnew install -y locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
	gnupg2 apt-utils tzdata curl \
		2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
	echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen
	apt-key adv --fetch-keys http://repo.omd.my.id/trusted-keys | grep -iv "not changed"
	aptnew update; aptnew full-upgrade -fy

	echo "1" > /run/done.init.dkbuild.txt
fi


#--- for logging
ip a
dhclient eth0


find /var/lib/apt/lists/ -type f -delete; \
find /var/cache/apt/ -type f -delete; \
rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
/etc/apt/preferences.d/00-revert-stable \
/var/cache/debconf/ /var/lib/apt/lists/* \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
mkdir -p /root/.local/share/nano/ /root/.config/procps/; \
dpkg --configure -a; \
aptnew autoclean; aptnew clean; aptnew update
aptnew full-upgrade --auto-remove --purge -fy


# purge packages
# cd `mktemp -d`; \
# apt purge -fy nginx* php* keydb* nutc* fuse* libfuse* sshfs* lua* db4* | grep -iv "not installed"; \
# apt purge -fy nginx* php* keydb* nutc* fuse* libfuse* sshfs* lua* db4* | grep -iv "not installed"

# sed -i '/keydb/d' /var/lib/dpkg/statoverride


# special steps for keydb only
# cd `mktemp -d`; \
# rm -rf /etc/keydb /etc/systemd /lib/systemd/system/keydb*; \
# systemctl daemon-reload; aptnew purge --auto-remove --purge  -fy keydb*; \
# aptnew update; aptnew full-upgrade --auto-remove --purge -fy; \
# aptnew install --reinstall -fy keydb-server keydb-tools; \
# netstat -nlpat | grep --color keydb-server

# sed -i '/keydb/d' /var/lib/dpkg/statoverride


# cd `mktemp -d`; \
# aptnew purge --auto-remove --purge \
# php* nginx* libnginx* lua-resty* keydb-server keydb-tools nutcracker -fy

# rm -rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb \
# /etc/keydb /etc/nutcracker /etc/php /etc/nginx \
# /lib/systemd/system/keydb* /etc/init.d/keydb* \
# /lib/systemd/system/nutcracker* /etc/init.d/nutcracker* \
# /lib/systemd/system/nginx* /etc/init.d/nginx* \
# /lib/systemd/system/php* /etc/init.d/php*

# short install
aptnew install  -o Dpkg::Options::="--force-overwrite" \
--no-install-recommends --fix-missing --reinstall -fy \
libzip4 libdb4.8 libgeoip1 bison flex libsodium23

aptnew install \
--no-install-recommends --fix-missing --reinstall -fy \
nutcracker keydb-server keydb-tools nginx-extras

aptnew install \
--no-install-recommends --fix-missing --reinstall -fy \
php8.0-fpm php8.0-cli php8.0-zip \
php8.1-fpm php8.1-cli php8.1-zip

aptnew install -y; \
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

sed -i '/keydb/d' /var/lib/dpkg/statoverride

if [[ -e /usr/lib/x86_64-linux-gnu/libzip.so ]]; then
	ln -s /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/x86_64-linux-gnu/libzip.so.4
elif [[ -e /usr/lib/x86_64-linux-gnu/libzip.so.5 ]]; then
	ln -s /usr/lib/x86_64-linux-gnu/libzip.so.5 /usr/lib/x86_64-linux-gnu/libzip.so.4
fi

[[ -e /usr/share/nginx/modules-available/mod-http-lua.conf ]] && \
	sed -i -r "s/^load/\#load/g" /usr/share/nginx/modules-available/mod-http-lua.conf

# workaround for keydb-server
if [[ $(dpkg -l | grep "^ii" | grep "keydb\-server" | wc -l) -lt 1 ]]; then
	rm -rf /var/lib/dpkg/info/keydb-server.*
	dpkg --configure -a
	aptnew install -fy
fi


# fix arginfo on uploadprogress
if [ -e /etc/php/8.0/mods-available/uploadprogress.ini ]; then
	sed -i "s/^extension/\; extension/g" /etc/php/8.0/mods-available/uploadprogress.ini
fi


# complete install NGINX
apt-cache search lua-resty | awk '{print $1}' > /tmp/pkg-nginx0.txt
apt-cache search nginx | awk '{print $1}' | sort -u | \
grep -v "nginx-light\|nginx-full\|nginx-core\|lua\|zabbix\|python\|prometheus" | \
grep "libnginx\|nginx-" >> /tmp/pkg-nginx0.txt

cat /tmp/pkg-nginx0.txt > /tmp/pkg-nginx1.txt
cat /tmp/pkg-nginx1.txt | tr "\n" " " > /tmp/pkg-nginx2.txt
cat /tmp/pkg-nginx2.txt | xargs aptnew install -y --no-install-recommends --fix-missing


# complete install PHP8.x
complete_php_installs() {
	phpv="$1"
	vnum="$2"
	> /tmp/pkg-php0.txt

	apt-cache search db4.8 | grep -iv "cil\|tcl\|doc" | \
	cut -d" " -f1 | xargs aptnew install -fy -o Dpkg::Options::="--force-overwrite"

	apt-cache search db4.8 | grep -iv "cil\|tcl\|doc" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv | \
	grep -iv "apache\|debug\|gmagick\|embed" | \
	grep -iv "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache\|enchant" | \
	grep "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|common\|fpm\|cli" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv | \
	grep -iv "apache\|debug\|gmagick\|embed" | \
	grep -iv "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache\|enchant" | \
	grep "bcmath\|bz2\|gmp\|mbstring\|mysql\|opcache\|readline\|xdebug\|zip" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv |\
	grep -iv "apache\|debug\|gmagick\|embed" | \
	grep -iv "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache\|enchant" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	cat /tmp/pkg-php0.txt | sort -u | sort | tr "\n" " " > /tmp/pkg-php1.txt

	cat /tmp/pkg-php1.txt | xargs aptnew install -fy \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"

	# fix arginfo on uploadprogress
	if [ -e /etc/php/$vnum/mods-available/uploadprogress.ini ]; then
		sed -i "s/^extension/\; extension/g" /etc/php/$vnum/mods-available/uploadprogress.ini
		aptnew install -fy
	fi

	printf "\n\n --- packages list: \n"
	cat /tmp/pkg-php0.txt
}

complete_php_installs "php8.0" "8.0"
complete_php_installs "php8.1" "8.1"


#--- check packages installed
/bin/bash /tb2/build-devomd/dk-install-check.sh
