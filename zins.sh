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




# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh



if [[ ! -e /run/done.init.dkbuild.txt ]]; then

	# tweaks
	echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io
	aptold install -y eatmydata lsb_release


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
'>/etc/environment && cat /etc/environment

	export PATH=$PATH:/usr/sbin
	timedatectl set-timezone Asia/Jakarta


	echo \
"deb [trusted=yes] http://repo.aisits.id/phideb ${RELNAME} main
#deb-src [trusted=yes] http://repo.aisits.id/phideb ${RELNAME} main
">/etc/apt/sources.list.d/phideb.list

	>/etc/apt/sources.list.d/nginx-ppa-devel.list
	>/etc/apt/sources.list.d/nginx-devel-aisits.list
	>/etc/apt/sources.list.d/php-aisits.list
	>/etc/apt/sources.list.d/php-sury.list
	>/etc/apt/sources.list.d/keydb-ppa.list


	cd `mktemp -d`; \
	apt update;\
	dpkg --configure -a; \
	aptold install -y locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
	gnupg2 apt-utils tzdata curl && \
	echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen &&\
	apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys &&\
	apt update; apt full-upgrade -fy

	echo "1" > /run/done.init.dkbuild.txt
fi


find /var/lib/apt/lists/ -type f -delete; \
find /var/cache/apt/ -type f -delete; \
rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
/etc/apt/preferences.d/00-revert-stable \
/var/cache/debconf/ /var/lib/apt/lists/* \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
mkdir -p /root/.local/share/nano/ /root/.config/procps/; \
dpkg --configure -a; \
apt autoclean; apt clean; apt update
apt full-upgrade --auto-remove --purge -fy



cd `mktemp -d`; \
apt purge --auto-remove --purge \
php* nginx* libnginx* lua-resty* keydb-server keydb-tools nutcracker -fy

rm -rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb /usr/lib/php \
/etc/keydb /etc/nutcracker /etc/php /etc/nginx \
/lib/systemd/system/keydb* /etc/init.d/keydb* \
/lib/systemd/system/nutcracker* /etc/init.d/nutcracker* \
/lib/systemd/system/nginx* /etc/init.d/nginx* \
/lib/systemd/system/php* /etc/init.d/php*

# short install
apt install --no-install-recommends --fix-missing --reinstall -fy \
libzip4 nutcracker keydb-server keydb-tools nginx-extras php8.0-fpm php8.0-cli php8.0-zip; \
apt install -y; \
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

# fix arginfo on uploadprogress
sed -i "s/^extension/\; extension/g" /etc/php/8.0/mods-available/uploadprogress.ini


# complete install NGINX
apt-cache search lua-resty | awk '{print $1}' > /tmp/pkg-nginx0.txt
apt-cache search nginx | awk '{print $1}' | sort -u | \
grep -v "nginx-light\|nginx-full\|nginx-core\|lua\|zabbix\|python\|prometheus" | \
grep "libnginx\|nginx-" >> /tmp/pkg-nginx0.txt

cat /tmp/pkg-nginx0.txt > /tmp/pkg-nginx1.txt
cat /tmp/pkg-nginx1.txt | tr "\n" " " > /tmp/pkg-nginx2.txt
cat /tmp/pkg-nginx2.txt | xargs apt install -y --no-install-recommends --fix-missing


# complete install PHP8.0
apt-cache search php8.0* | awk '{print $1}' | grep -v "apache\|embed\|php8.1" |\
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|common\|fpm\|cli" \
> /tmp/pkg-php0.txt

apt-cache search php8.0* | awk '{print $1}' | grep -v "apache\|embed\|php8.1" |\
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "bcmath\|bz2\|gmp\|mbstring\|mysql\|opcache\|readline\|xdebug\|zip" \
>> /tmp/pkg-php0.txt

cat /tmp/pkg-php0.txt > /tmp/pkg-php1.txt
cat /tmp/pkg-php1.txt | grep -v "php8.1" | tr "\n" " " > /tmp/pkg-php2.txt
cat /tmp/pkg-php2.txt | xargs apt install -y --no-install-recommends --fix-missing

# install all
apt-cache search php8.0 | grep -v "apache\|debug\|dbg\|cgi\|embed\|gmagick\|yac\|-dev" |\
cut -d" " -f1 | tr "\n" " " | xargs apt install -y --no-install-recommends

# fix arginfo on uploadprogress
sed -i "s/^extension/\; extension/g" /etc/php/8.0/mods-available/uploadprogress.ini

printf "\n\naptnew install -y "
cat /tmp/pkg-php2.txt
printf "\n\n"

# check PHP install
php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
NUMEXT=$(php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
if [[ $NUMEXT -lt 8 ]]; then printf "\n\n\t php ext:NOT OK\n\n"; else printf "\n\n\t php ext: OK\n\n"; fi
php -v


# check netstat
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

# check php custom
NUMNON=$(dpkg -l | grep "^ii" | grep php8 | grep -v aisits | wc -l)
NUMCUS=$(dpkg -l | grep "^ii" | grep php8 | grep aisits | wc -l)
printf "\n\n--- default=$NUMNON  CUSTOM=$NUMCUS \n"