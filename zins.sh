#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

if [[ ! -e /run/done.init.dkbuild.txt ]]; then

	# tweaks
	echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io
	apt install -fy eatmydata


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
	>/etc/apt/sources.list.d/php-sury.list
	>/etc/apt/sources.list.d/php-aisits.list
	>/etc/apt/sources.list.d/keydb-ppa.list


	cd `mktemp -d`; \
	apt update;\
	dpkg --configure -a; \
	apt install -yf locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
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
apt full-upgrade --auto-remove --purge -fydu



# cd `mktemp -d`; apt remove php* nginx* libnginx* lua-resty* keydb-server keydb-tools nutcracker -fy
cd `mktemp -d`; apt remove --auto-remove --purge keydb* nutcracker* -fy
rm -rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb

apt install --auto-remove --purge -fy keydb-server keydb-tools

# cd `mktemp -d`; \
# systemctl stop redis-server; systemctl disable redis-server; systemctl mask redis-server; \
# systemctl daemon-reload; apt remove -y redis-server
# mkdir -p /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
# chown keydb.keydb -Rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
# find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type d -exec chmod 775 {} \; ; \
# find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type f -exec chmod 664 {} \;
# sed -i "s/^bind 127.0.0.1 \:\:1/\#-- bind 127.0.0.1 \:\:1\nbind 127.0.0.1/g" /etc/keydb/keydb.conf
# # sed -i "s/^logfile \/var/#--logfile \/var/g" /etc/keydb/keydb.conf

# killall -9 keydb-server; \
# systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1; \
# systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1
# KEYCHECK=$(keydb-server /etc/keydb/keydb.conf --loglevel verbose 2>&1 | grep -i "loaded" | wc -l)
# if [[ $KEYCHECK -gt 0 ]]; then
# 	printf "\n\n keydb: OK \n\n"
# else
# 	printf "\n\n keydb: FAILED \n\n"
# fi

apt install -fy
exit 0;


apt-cache search lua-resty | awk '{print $1}' > /tmp/pkg-nginx0.txt
apt-cache search nginx | awk '{print $1}' | sort -u | \
grep -v "nginx-light\|nginx-full\|nginx-core\|lua\|zabbix\|python\|prometheus" | \
grep "libnginx\|nginx-" >> /tmp/pkg-nginx0.txt

cat /tmp/pkg-nginx0.txt > /tmp/pkg-nginx1.txt
cat /tmp/pkg-nginx1.txt | tr "\n" " " > /tmp/pkg-nginx2.txt
cat /tmp/pkg-nginx2.txt | xargs apt install -fy


apt-cache search php8.0* | awk '{print $1}' | grep -v "apache\|embed" |\
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|common\|fpm\|cli" \
> /tmp/pkg-php0.txt

apt-cache search php8.0* | awk '{print $1}' | grep -v "apache\|embed" |\
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "bcmath\|bz2\|gmp\|mbstring\|mysql\|opcache\|readline\|xdebug\|zip" \
>> /tmp/pkg-php0.txt

cat /tmp/pkg-php0.txt > /tmp/pkg-php1.txt
cat /tmp/pkg-php1.txt | tr "\n" " " > /tmp/pkg-php2.txt
cat /tmp/pkg-php2.txt | xargs apt install -fy

printf "\n\napt install -fy "
cat /tmp/pkg-php2.txt
printf "\n\n"

php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
NUMEXT=$(php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
if [[ $NUMEXT -lt 8 ]]; then printf "\n\n\t php ext:NOT OK\n\n"; else printf "\n\n\t php ext: OK\n\n"; fi


# apt install -yf   --no-install-recommends --auto-remove --purge \
# php8.0-cli php8.0-fpm php8.0-common php8.0-curl php8.0-fpm php8.0-gd \
# php8.0-bcmath php8.0-bz2 php8.0-gmp php8.0-ldap php8.0-mbstring php8.0-mysql \
# php8.0-opcache php8.0-readline php8.0-soap php8.0-tidy php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip \
# php-memcached php-redis php-igbinary php-msgpack php-http php-raphf \
# autoconf curl dh-make dh-php gcc ghostscript gifsicle imagemagick jpegoptim keydb-server keydb-tools make \
# mariadb-client \
# mcrypt memcached optipng pdftk pkg-config pkg-php-tools pngquant qpdf wkhtmltopdf xfonts-75dpi xvfb zlib1g-dev
