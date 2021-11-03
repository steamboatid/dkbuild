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
	aptold install -y eatmydata lsb-release nano rsync \
		2>&1 | grep -iv "newest" | grep --color=auto "Depends"


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
"deb [trusted=yes] http://repo.aisits.id/phideb ${RELNAME} main
#deb-src [trusted=yes] http://repo.aisits.id/phideb ${RELNAME} main
">/etc/apt/sources.list.d/phideb.list

	>/etc/apt/sources.list.d/nginx-ppa-devel.list
	>/etc/apt/sources.list.d/nginx-devel-aisits.list
	>/etc/apt/sources.list.d/php-aisits.list
	>/etc/apt/sources.list.d/php-sury.list
	>/etc/apt/sources.list.d/keydb-ppa.list


	cd `mktemp -d`
	aptold update
	dpkg --configure -a
	aptold install -y locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
	gnupg2 apt-utils tzdata curl \
		2>&1 | grep -iv "newest" | grep --color=auto "Depends"
	echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen
	apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys | grep -iv "not changed"
	aptold update; aptold full-upgrade -fy

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
aptold autoclean; aptold clean; aptold update
aptold full-upgrade --auto-remove --purge -fy


# purge packages
cd `mktemp -d`; \
apt purge -fy nginx* php* keydb* nutc* fuse* libfuse* sshfs* lua* db4* | grep -iv "not installed"; \
apt purge -fy nginx* php* keydb* nutc* fuse* libfuse* sshfs* lua* db4* | grep -iv "not installed"
exit 0


# special steps for keydb only
cd `mktemp -d`; \
rm -rf /etc/keydb /etc/systemd /lib/systemd/system/keydb*; \
systemctl daemon-reload; aptold purge --auto-remove --purge  -fy keydb*; \
aptold update; aptnew full-upgrade --auto-remove --purge -fy; \
aptnew install --reinstall -fy keydb-server keydb-tools; \
netstat -nlpat | grep --color keydb-server


# cd `mktemp -d`; \
# aptold purge --auto-remove --purge \
# php* nginx* libnginx* lua-resty* keydb-server keydb-tools nutcracker -fy

# rm -rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb \
# /etc/keydb /etc/nutcracker /etc/php /etc/nginx \
# /lib/systemd/system/keydb* /etc/init.d/keydb* \
# /lib/systemd/system/nutcracker* /etc/init.d/nutcracker* \
# /lib/systemd/system/nginx* /etc/init.d/nginx* \
# /lib/systemd/system/php* /etc/init.d/php*

# short install
aptnew install --no-install-recommends --fix-missing --reinstall -fy \
libzip4 nutcracker keydb-server keydb-tools nginx-extras php8.0-fpm php8.0-cli php8.0-zip; \
aptnew install -y; \
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

[[ -e /usr/lib/x86_64-linux-gnu/libzip.so ]] && \
	ln -s /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/x86_64-linux-gnu/libzip.so.4

[[ -f /usr/share/nginx/modules-available/mod-http-lua.conf ]] && \
	sed -i -r "s/^load/\#load/g" /usr/share/nginx/modules-available/mod-http-lua.conf

# workaround for keydb-server
if [[ $(dpkg -l | grep "^ii" | grep "keydb\-server" | wc -l) -lt 1 ]]; then
	rm -rf /var/lib/dpkg/info/keydb-server.*
	dpkg --configure -a
	aptold install -fy
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
cat /tmp/pkg-php2.txt | xargs aptnew install -y --no-install-recommends --fix-missing

# install all
apt-cache search php8.0 | grep -v "apache\|debug\|dbg\|cgi\|embed\|gmagick\|yac\|-dev" |\
cut -d" " -f1 | tr "\n" " " | xargs aptnew install -y --no-install-recommends

# fix arginfo on uploadprogress
if [ -e /etc/php/8.0/mods-available/uploadprogress.ini ]; then
	sed -i "s/^extension/\; extension/g" /etc/php/8.0/mods-available/uploadprogress.ini
fi

printf "\n\naptnew install -y "
cat /tmp/pkg-php2.txt
printf "\n\n"

# check PHP install
php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
NUMEXT=$(php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
if [[ $NUMEXT -lt 8 ]]; then
	printf "\n--- ${red}php ext:NOT OK ${end}\n"
else
	printf "\n--- ${blu}php ext: OK ${end}\n"
fi

# check php version
printf "\n--- Output of ${yel}php -v${end} \n"
php -v

# restart using rc
[ -x /etc/init.d/nutcracker ] && /etc/init.d/nutcracker restart
[ -x /etc/init.d/nginx ] && /etc/init.d/nginx restart
[ -x /etc/init.d/keydb-server ] && /etc/init.d/keydb-server restart
[ -x /etc/init.d/php8.0-fpm ] && mkdir -p /run/php && /etc/init.d/php8.0-fpm restart

# check netstat
printf "\n--- Output of ${yel}netstat${end} \n"
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

# check netstat
printf "\n--- Output of ${yel}ps${end} \n"
ps -e -o command | grep -v "grep\|pool\|worker" | sort -u | grep --color "nginx\|keydb\|nutcracker\|php"

# check php custom
NUMNON=$(dpkg -l | grep "^ii" | grep php8 | grep -v aisits | wc -l)
NUMCUS=$(dpkg -l | grep "^ii" | grep php8 | grep aisits | wc -l)
printf "\n\n--- PHP packages: ${yel}default=$NUMNON  ${blu}CUSTOM=$NUMCUS ${end}\n"
