#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"
export UCF_FORCE_CONFFMISS=1

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

export PHPVERS=("php8.2" "php8.1")
export PHPGREP="php8.2\|php8.1"


source /tb2/build-devomd/dk-build-1libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm
delete_apt_lock


# delete phideb
delete_phideb


# purge pendings
purge_pending_installs

# delete old php source
find -L /root/org.src/php -maxdepth 2 -name "php5*-5*" | xargs rm -rf
find -L /root/org.src/php -maxdepth 2 -name "php7*-7*" | xargs rm -rf
find -L /root/org.src/php -maxdepth 2 -name "php8*-8*" | xargs rm -rf

# remove php first -- fresh install
MISS=0
for apv in "${PHPVERS[@]}"; do
	vnum=$(echo $apv | sed 's/php//')

	# fpm conf
	anum=$(find /etc/php/$vnum/fpm -type f -iname "*.conf" | wc -l)
	if [[ $anum -lt 2 ]]; then MISS=$((MISS+1)); fi

	# cli php.ini
	anum=$(find /etc/php/$vnum/cli -type f -iname "php.ini" | wc -l)
	if [[ $anum -lt 1 ]]; then MISS=$((MISS+1)); fi

	# cli php.ini
	anum=$(find /etc/php/$vnum/fpm -type f -iname "php.ini" | wc -l)
	if [[ $anum -lt 1 ]]; then MISS=$((MISS+1)); fi
done

if [[ $MISS -gt 0 ]]; then
	rm -rf /etc/php /usr/share/php; \
	apt purge -fy apache* php*
fi


# remove libdb5
apt install -fy
apt purge -fy libdb5*dev libdb++-dev libdb-dev libdb5.3-tcl
dpkg -l | grep db4.8 | grep omd | awk '{print $2}' | xargs apt remove -fy
apt-cache search db4.8 | grep -v "cil\|gcj" | \
	awk '{print $1}' | \
	xargs aptold install -o Dpkg::Options::="--force-overwrite" -fy


# list of package source
#-------------------------------------------
[[ -e /tmp/php-pkgs.txt ]] && touch /tmp/php-pkgs.txt || >/tmp/php-pkgs.txt


# install libboost
/bin/bash /tb2/build-devomd/dk-prep-libboost.sh

# apt autoremove --auto-remove --purge -fy \
#  2>&1 | grep --color "upgraded"



# PHP8.x, source via default + git
#-------------------------------------------
aptnew install -fy --fix-broken
# apt-cache search libmagickwand  2>&1 | awk '{print $1}' | grep dev | xargs aptnew install -y

aptnew install -fy --install-suggests \
pkg-config build-essential autoconf bison re2c meson \
libxml2-dev libsqlite3-dev curl make gcc devscripts debhelper dh-apache2 apache2-dev libc-client-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

aptnew install -fy libwebp-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"
aptnew install -fy libwebp-dev libwebp6 libgd-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"
aptnew install -fy libgd-dev libgd3 \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"


aptold install -fy
for apv in "${PHPVERS[@]}"; do
	aptnew install $apv $apv-cli $apv-cgi $apv-fpm $apv-common -my --reinstall \
	--install-recommends  --allow-downgrades --allow-change-held-packages \
  -o Dpkg::Options::="--force-overwrite"

	apt-cache search $apv | awk '{print $1}' | \
	grep -iv 'dbg\|apache\|embed\|yac\|gmagick' | \
	xargs aptnew install -my \
	--no-install-recommends  --allow-downgrades --allow-change-held-packages \
	-o Dpkg::Options::="--force-overwrite"
done


for apv in "${PHPVERS[@]}"; do
	aptnew install -my --no-install-recommends  --allow-downgrades --allow-change-held-packages \
	$apv $apv-bcmath $apv-bz2 $apv-cli $apv-common \
	$apv-curl $apv-dba $apv-dev $apv-enchant $apv-fpm $apv-gd $apv-gmp \
	$apv-imap $apv-interbase $apv-intl $apv-ldap $apv-mbstring $apv-mysql \
	$apv-odbc $apv-opcache $apv-pgsql $apv-pspell $apv-readline \
	$apv-snmp $apv-soap $apv-sqlite3 $apv-sybase $apv-tidy \
	$apv-xml $apv-xsl $apv-zip \
		2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | \
		grep --color=auto "Depends\|$"

	aptnew install -my --no-install-recommends  --allow-downgrades --allow-change-held-packages \
	$apv-apcu $apv-ast $apv-imagick $apv-igbinary $apv-msgpack \
	$apv-memcached $apv-redis $apv-xdebug \
		2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | \
		grep --color=auto "Depends\|$"

	aptnew install -my --no-install-recommends  --allow-downgrades --allow-change-held-packages \
	$apv-raphf \
		2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | \
		grep --color=auto "Depends\|$"
done


aptnew install -my --no-install-recommends  --allow-downgrades \
php-apcu php-ast php-imagick php-igbinary php-msgpack \
php-memcached php-redis php-xdebug \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | \
	grep --color=auto "Depends\|$"

aptnew install -my php-http php-raphf php-propro \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | \
	grep --color=auto "Depends\|$"

apt-cache search php | grep http | grep -i pecl | \
	cut -d" " -f1 | xargs aptnew install -fy | grep --color=auto "Depends\|$"

apt-cache search libsnmp | grep -iv "perl\|dbg\|pyth" | cut -d" " -f1 | \
	xargs aptnew install -fy \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

aptnew install -fy --no-install-recommends  --allow-downgrades \
devscripts build-essential lintian debhelper git git-extras wget axel dh-make dh-php ccache \
aspell aspell-en chrpath default-libmysqlclient-dev dictionaries-common emacsen-common firebird-dev firebird3.0-common firebird3.0-common-doc flex freetds-common \
freetds-dev libapparmor-dev libargon2-dev libaspell-dev libaspell15 libblkid-dev libbsd-dev libbz2-dev libct4 libcurl4-openssl-dev libedit-dev \
libenchant-dev libenchant1c2a libevent-* libevent-dev libfbclient2 libffi-dev \
libgcrypt20-dev libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgmp-dev libgmp3-dev libgmpxx4ldbl libgpg-error-dev libhunspell-1.7-0 libib-util \
libkrb5-dev liblmdb-dev libltdl-dev libltdl7 libmagic-dev libmariadb-dev libmariadb-dev-compat libmhash-dev libmhash2 libmount-dev libncurses-dev libnss-myhostname \
libodbc1 libonig-dev libonig5 libpci-dev libpcre2-32-0 libpcre2-dev libpq-dev libpq5 libpspell-dev libqdbm-dev libqdbm14 libsasl2-dev libselinux1-dev \
libsensors4-dev libsepol1-dev libsnmp-base libsnmp-dev libsodium-dev libsodium23 libsybdb5 libsystemd-dev libtext-iconv-perl libtidy-dev libtidy5deb1 \
libtommath1 libudev-dev libwrap0-dev libxmltok1 libxmltok1-dev libxslt1-dev libzip-dev libzip4 locales-all netcat-openbsd odbcinst odbcinst1debian2 python3-distutils \
python3-lib2to3 systemtap-sdt-dev unixodbc-dev libfl-dev \
bison libbison-dev libc-client2007e libc-client2007e-dev libpam0g-dev libsqlite3-dev libwebpdemux2 mlock re2c \
libgd-dev libgd3 libwebp6 libgd-dev \
libmemcached*dev zlib1g-dev \
apache2-dev autoconf automake bison chrpath debhelper default-libmysqlclient-dev libmysqlclient-dev dh-apache2 dpkg-dev firebird-dev flex freetds-dev \
libapparmor-dev libapr1-dev libargon2-dev libbz2-dev libc-client-dev libedit-dev libenchant-dev libevent-dev libexpat1-dev libffi-dev libfreetype6-dev \
libgcrypt20-dev libglib2.0-dev libgmp3-dev libicu-dev libjpeg-dev libjpeg*dev libkrb5-dev libldap2-dev liblmdb-dev libmagic-dev libmhash-dev libnss-myhostname libonig-dev \
libpam0g-dev libpcre2-dev libpng-dev libpq-dev libpspell-dev libqdbm-dev libsasl2-dev libsnmp-dev libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libtidy-dev libtool \
libwrap0-dev libxml2-dev libxmltok1-dev libxslt1-dev libzip-dev locales-all netbase netcat-openbsd re2c systemtap-sdt-dev tzdata unixodbc-dev zlib1g-dev \
libxml2-dev libpcre3-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libxpm-dev libfreetype6-dev libmysqlclient-dev postgresql-server-dev-all \
libgmp-dev libsasl2-dev libmhash-dev unixodbc-dev freetds-dev libpspell-dev libsnmp-dev libtidy-dev libxslt1-dev libmcrypt-dev \
libpng*dev libfreetype*dev libxft*dev libgdchart-gd2-xpm-dev freetds-dev libldb-dev libldap2-dev \
libdb4*dev libdn*dev libidn*dev libomp-dev meson \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

# apt-cache search libdb | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
# xargs aptnew install -fy  --no-install-recommends  --allow-downgrades \
# 	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"
# apt-cache search db5 | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
# xargs aptnew install -fy  --no-install-recommends  --allow-downgrades \
# 	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

aptnew install -fy --no-install-recommends  --allow-downgrades \
default-jdk libx11-dev xorg-dev libcurl4-openssl-dev \
mandoc apache2-dev dh-apache2 \
liblz4-dev lz4 liblz4-* libdirectfb-dev liblzf-dev liblzf-dev \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev libssl-dev libxml2-dev \
libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
php-dev libc6-dev libticonv-dev libiconv-hook-dev \
libghc-iconv-dev libiconv-hook-dev libc-bin \
libqdbm* libgdbm* libxqdbm* libxmlrpc-c*dev xmlrpc-api-utils \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

aptnew install -fy --no-install-recommends  --allow-downgrades \
apache2-dev autotools-dev *clang*dev default-libmysqlclient-dev devscripts dpkg-dev \
firebird-dev freetds-dev libapparmor-dev libapr1-dev libargon2-dev libatomic-ops-dev \
libavif*dev libavif-dev libb64-dev \
libc-client-dev lib*clang*dev libclang*dev libclang-dev libconsole-bridge-dev \
libcurl4-openssl-dev \
libdirectfb-dev libedit-dev libenchant-dev libevent-dev libexpat1-dev \
libexpat-dev libffi-dev libfindlib-ocaml-dev libfreetype6-dev libfreetype*dev \
libgcrypt20-dev libgdchart-gd2-xpm-dev \
libgd-dev libgd-gd2-noxpm-ocaml-dev libgeoip-dev libghc-ldap-dev libghc-mmap-dev \
libglib2.0-dev libgmp3-dev libgmp-dev libgoogle-perftools-dev \
libiconv-hook-dev libicu-dev libjbig-dev libjemalloc-dev libjpeg*dev libjpeg-dev \
libkf5imap-dev libkf5ldap-dev libkrb5-dev libldap2-dev libldap-ocaml-dev libldb-dev \
liblmdb-dev libluajit-5.1-dev liblz4-dev liblzf-dev liblzma*dev libmagic-dev \
libmaxminddb-dev libmcrypt-dev libmemcached-dev libmhash-dev \
libmm-dev libmysqlclient-dev libnethttpd-ocaml-dev libocamlnet-ocaml-dev libonig-dev \
libpam0g-dev libpcre2-dev libpcre3-dev libpcre++-dev libpcre-ocaml-dev libperl-dev \
libpng*dev libpng-dev libpq-dev libpspell-dev libqdbm-dev libreadline-dev \
libsasl2-dev libsnmp-dev libsodium-dev \
libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libticonv-dev \
libtidy-dev libtiff-dev libwebp-dev libwrap0-dev libx11-dev libxft*dev libxml2-dev \
libxml-light-ocaml-dev libxmlrpc-c++8-dev libxmlrpc-core-c3-dev libxmlrpc-epi-dev \
libxmlrpc-light-ocaml-dev libxmltok1-dev libxpm-dev libxslt1-dev \
libyaml-dev libzip-dev libzip-ocaml-dev libzstd*dev libzstd-dev lua-geoip-dev \
lua-ldap-dev lua-zlib-dev php-all-dev \
php-dev php-igbinary-all-dev php-memcached-all-dev \
postgresql-server-dev-* postgresql-server-dev-all slapi-dev \
systemtap-sdt-dev tcl-dev unixodbc-dev uuid-dev xorg-dev \
zlib1g*dev zlib1g-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"


aptnew install -fy \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
pkg-config build-essential autoconf bison re2c libxml2-dev libsqlite3-dev freetds-dev \
libmagickwand-dev libmagickwand-6*dev libgraphicsmagick1-dev libmagickcore-6-arch-config \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"


for apv in "${PHPVERS[@]}"; do
	aptold build-dep -my \
	$apv php-defaults \
	$apv-cli $apv-fpm $apv-common $apv-curl $apv-fpm $apv-gd \
	$apv-bcmath $apv-bz2 $apv-gmp $apv-ldap $apv-mbstring $apv-mysql \
	$apv-opcache $apv-readline $apv-soap $apv-tidy $apv-xdebug $apv-xml $apv-xsl $apv-zip \
		2>&1 | grep -iv "newest\|reading \|building \|picking " | \
		grep --color=auto "Depends\|$"

	aptold build-dep -my \
	$apv-apcu $apv-ast $apv-imagick $apv-igbinary $apv-msgpack \
	$apv-memcached $apv-redis $apv-xdebug \
		2>&1 | grep -iv "newest\|reading \|building \|picking " | \
		grep --color=auto "Depends\|$"
done

aptold build-dep -my \
php-apcu php-ast php-imagick php-igbinary php-msgpack \
php-memcached php-redis php-xdebug \
	2>&1 | grep -iv "newest\|reading \|building \|picking " | \
	grep --color=auto "Depends\|$"

aptold build-dep -fy php-http php-raphf php-propro \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends\|$"

apt-cache search php | grep http | grep -i pecl | \
	cut -d" " -f1 | \
	grep -iv "php-http-all-dev\|php5.6-http\|php7.0-http\|php7.1-http\|php7.2-http\|php7.3-http\|php7.4-http" | \
	grep -iv "php8.0-http\|php8.1-http\|php8.2-http" | \
	grep -iv "php8.*\-http" | \
	grep -iv "php9.*\-http" | \
	grep -iv "php.*all\-dev\|php5\|php7\.0\|php7\.1\|php7\.2\|php7\.3\|php8\.2" | \
	xargs aptold build-dep -fy | grep --color=auto "Depends\|$"


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/php /root/src/php
rm -rf /root/src/php/*deb

#--- fetch default source package
#-------------------------------------------
cd /root/org.src/php
chown_apt

for apv in "${PHPVERS[@]}"; do
	printf "\n\n ${cyn}"
	printf "\n ---------------------------------"
	printf "\n GET SOURCE: $apv"
	printf "\n ---------------------------------"
	printf "\n ${end}"
	find -L /root/org.src/php -maxdepth 2 -name "$apv-8*"
	printf "\n\n"

	aptold -qqq source -my \
	$apv $apv-cli $apv-common $apv-fpm
done
find -L /root/org.src/php -maxdepth 2 -name "php8*-8*"

for apv in "${PHPVERS[@]}"; do
	aptold -qqq source -my \
	$apv-bcmath $apv-bz2 \
	$apv-curl $apv-dba $apv-dev $apv-enchant $apv-fpm $apv-gd $apv-gmp \
	$apv-igbinary $apv-imap $apv-interbase \
	$apv-intl $apv-ldap $apv-mbstring \
	$apv-mysql $apv-odbc $apv-opcache $apv-pgsql $apv-pspell \
	$apv-readline $apv-snmp $apv-soap \
	$apv-sqlite3 $apv-sybase $apv-tidy $apv-xml \
	$apv-xsl $apv-zip

	exts=($apv-apcu $apv-ast $apv-imagick $apv-igbinary $apv-msgpack \
	$apv-memcached $apv-redis $apv-xdebug $apv-raphf $apv-http $apv-pecl-http)
	for aext in "${exts[@]}"; do
		aptold -qqq source -my $aext
	done
done

aptold -qqq source -my \
php-defaults \
php-apcu php-ast php-imagick php-igbinary php-msgpack \
php-memcached php-redis php-xdebug \
php-raphf

aptold -qqq source -my php-pecl-http
aptold -qqq source -my php-http


#--- errornous packages
cd /root/org.src/php

apt-cache search xdebug | cut -d' ' -f1 | grep php | grep -i "\-dev"  >>/tmp/php-pkgs.txt
apt-cache search redis | cut -d' ' -f1 | grep php | grep -iv "swoole" | \
grep -i "\-dev"  >>/tmp/php-pkgs.txt
apt-cache search imagick | cut -d' ' -f1 | grep php | grep -i "\-dev"  >>/tmp/php-pkgs.txt
apt-cache search ast | cut -d' ' -f1 | grep php |  grep -iv "xcache\|solr" |\
grep -i "\-dev"  >>/tmp/php-pkgs.txt
apt-cache search propro | cut -d' ' -f1 | grep php |\
grep -i "\-dev"  >>/tmp/php-pkgs.txt

chown_apt
cat /tmp/php-pkgs.txt | grep -iv "yac\|xcache\|swoole\|solr\|imagick" | \
grep -iv "php.*all\-dev\|php5\|php7\.0\|php7\.1\|php7\.2\|php7\.3\|php8\.2" | \
xargs aptnew install -fy \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"

cat /tmp/php-pkgs.txt | \
xargs aptold build-dep -fy \
grep -iv "php.*all\-dev\|php5\|php7\.0\|php7\.1\|php7\.2\|php7\.3\|php8\.2" | \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"

cat /tmp/php-pkgs.txt | \
xargs aptold source -my -qqq \
grep -iv "php.*all\-dev\|php5\|php7\.0\|php7\.1\|php7\.2\|php7\.3\|php8\.2" | \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"

# cat /tmp/php-pkgs.txt | xargs aptold build-dep -fy
# cat /tmp/php-pkgs.txt | xargs aptold source -my


#--- another errornous packages
chown_apt
apt-cache search php | cut -d' ' -f1 | grep "^php-" |\
grep -i "\-dev" | grep -iv "horde\|dbg\|sym\|embed" \
	>>/tmp/php-pkgs.txt

apt_source_build_dep_from_file "/tmp/php-pkgs.txt" "php"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: PHP \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php/ /root/src/php/
find -L /root/src/php -maxdepth 2 -name "php8*-8*"



#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n --- wait for all background process...  [$bname] "
wait_backs_nopatt; wait
printf "\n\n --- wait finished... \n\n\n"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: PHP \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/php/ /root/src/php/
find -L /root/src/php -maxdepth 2 -name "php8*-8*"




#--- last
#-------------------------------------------
# save_local_debs
aptnew install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"

find -L /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find -L /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1


#--- mark as manual installed,
# for nginx, php, redis, keydb, memcached
# 5.6  7.0  7.1  7.2  7.3  7.4  8.0
#-------------------------------------------
# limit_php8x_only
set_php81_as_default
find -L /root/org.src/php -maxdepth 2 -name "php8*-8*"


printf "\n\n\n"
exit 0;