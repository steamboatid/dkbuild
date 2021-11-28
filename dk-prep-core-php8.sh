#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

export PHPV_DEFAULT="php8.0"
export PHPV="${1:-$PHPV_DEFAULT}"
export PHPVNUM=$(echo $PHPV | sed 's/php//g')


source /tb2/build/dk-build-0libs.sh


# print php version
#-------------------------------------------
printf "\n\n --- php version: ${yel}$PHPV${end} [$PHPVNUM] \n\n"


# purge pendings
purge_pending_installs

# PHP8.x, source via default + git
#-------------------------------------------
aptold install -fy --fix-broken
# apt-cache search libmagickwand  2>&1 | awk '{print $1}' | grep dev | xargs aptold install -y


aptold install -fy pkg-config build-essential autoconf bison re2c meson \
libxml2-dev libsqlite3-dev curl make gcc devscripts debhelper dh-apache2 apache2-dev libc-client-dev \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -fy libwebp-dev \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"
aptold install -fy libwebp-dev libwebp6 libgd-dev \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"
aptold install -fy libgd-dev libgd3 \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"


aptold install -fy --no-install-recommends  --allow-downgrades \
$PHPV \
$PHPV $PHPV-apcu $PHPV-ast $PHPV-bcmath $PHPV-bz2 $PHPV-cli $PHPV-common \
$PHPV-curl $PHPV-dba $PHPV-dev $PHPV-enchant $PHPV-fpm $PHPV-gd $PHPV-gmp \
$PHPV-igbinary $PHPV-imagick $PHPV-imap $PHPV-interbase \
$PHPV-intl $PHPV-ldap $PHPV-mbstring $PHPV-memcached $PHPV-msgpack \
$PHPV-mysql $PHPV-odbc $PHPV-opcache $PHPV-pgsql $PHPV-pspell $PHPV-raphf \
$PHPV-readline $PHPV-redis $PHPV-snmp $PHPV-soap $PHPV-sqlite3 $PHPV-sybase \
$PHPV-tidy $PHPV-xml $PHPV-xsl $PHPV-zip \
$PHPV \
$PHPV-cli $PHPV-fpm $PHPV-common $PHPV-curl $PHPV-fpm $PHPV-gd \
$PHPV-bcmath $PHPV-bz2 $PHPV-gmp $PHPV-ldap $PHPV-mbstring $PHPV-mysql \
$PHPV-opcache $PHPV-readline $PHPV-soap $PHPV-tidy $PHPV-xdebug $PHPV-xml $PHPV-xsl $PHPV-zip \
php-memcached php-redis php-igbinary php-msgpack php-apcu \
pkg-php-tools libdistro-info-perl php-all-dev \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -my php-http php-raphf \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

apt-cache search libsnmp | grep -iv "perl\|dbg\|pyth" | cut -d" " -f1 | \
	xargs aptold install -fy \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -fy --no-install-recommends  --allow-downgrades \
devscripts build-essential lintian debhelper git git-extras wget axel dh-make dh-php ccache \
aspell aspell-en chrpath default-libmysqlclient-dev dictionaries-common emacsen-common firebird-dev firebird3.0-common firebird3.0-common-doc flex freetds-common \
freetds-dev libapparmor-dev libargon2-dev libaspell-dev libaspell15 libblkid-dev libbsd-dev libbz2-dev libct4 libcurl4-openssl-dev libdb-dev libdb5.3-dev libedit-dev \
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
libapparmor-dev libapr1-dev libargon2-dev libbz2-dev libc-client-dev libdb-dev libedit-dev libenchant-dev libevent-dev libexpat1-dev libffi-dev libfreetype6-dev \
libgcrypt20-dev libglib2.0-dev libgmp3-dev libicu-dev libjpeg-dev libjpeg*dev libkrb5-dev libldap2-dev liblmdb-dev libmagic-dev libmhash-dev libnss-myhostname libonig-dev \
libpam0g-dev libpcre2-dev libpng-dev libpq-dev libpspell-dev libqdbm-dev libsasl2-dev libsnmp-dev libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libtidy-dev libtool \
libwrap0-dev libxml2-dev libxmltok1-dev libxslt1-dev libzip-dev locales-all netbase netcat-openbsd re2c systemtap-sdt-dev tzdata unixodbc-dev zlib1g-dev \
libxml2-dev libpcre3-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libxpm-dev libfreetype6-dev libmysqlclient-dev postgresql-server-dev-all \
libgmp-dev libsasl2-dev libmhash-dev unixodbc-dev freetds-dev libpspell-dev libsnmp-dev libtidy-dev libxslt1-dev libmcrypt-dev \
libpng*dev libdb5*-dev libfreetype*dev libxft*dev libgdchart-gd2-xpm-dev freetds-dev libldb-dev libldap2-dev \
libdb5*dev libdb4*dev libdn*dev libidn*dev libomp-dev meson \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

apt-cache search libdb | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
xargs aptold install -fy  --no-install-recommends  --allow-downgrades \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"
apt-cache search db5 | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
xargs aptold install -fy  --no-install-recommends  --allow-downgrades \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -fy --no-install-recommends  --allow-downgrades \
default-jdk libx11-dev xorg-dev libcurl4-openssl-dev \
mandoc apache2-dev dh-apache2 libdb-dev \
liblz4-dev lz4 liblz4-* libdirectfb-dev liblzf-dev liblzf-dev \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev libssl-dev libxml2-dev \
libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
php-dev libc6-dev libticonv-dev libiconv-hook-dev \
libghc-iconv-dev libiconv-hook-dev libc-bin \
libqdbm* libgdbm* libxqdbm* libxmlrpc-c*dev xmlrpc-api-utils \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -fy --no-install-recommends  --allow-downgrades \
apache2-dev autotools-dev *clang*dev default-libmysqlclient-dev devscripts dpkg-dev \
firebird-dev freetds-dev libapparmor-dev libapr1-dev libargon2-dev libatomic-ops-dev \
libavif*dev libavif-dev libb64-dev libboost1.67-dev libboost-atomic1.67-dev \
libboost-chrono1.67-dev libboost-date-time1.67-dev libboost-date-time-dev \
libboost-serialization1.67-dev libboost-system1.67-dev libboost-system-dev \
libboost-thread1.67-dev libboost-thread-dev libbz2-dev libc6-dev libc-client*-dev \
libc-client-dev lib*clang*dev libclang*dev libclang-dev libconsole-bridge-dev \
libcurl4-openssl-dev libdb*dev libdb5*dev libdb5*-dev libdb*dev libdb-dev \
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
libroscpp-core-dev librust-memmap-dev libsasl2-dev libsnmp-dev libsodium-dev \
libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libticonv-dev \
libtidy-dev libtiff-dev libwebp-dev libwrap0-dev libx11-dev libxft*dev libxml2-dev \
libxml-light-ocaml-dev libxmlrpc-c++8-dev libxmlrpc-core-c3-dev libxmlrpc-epi-dev \
libxmlrpc-light-ocaml-dev libxmlrpcpp-dev libxmltok1-dev libxpm-dev libxslt1-dev \
libyaml-dev libzip-dev libzip-ocaml-dev libzstd*dev libzstd-dev lua-geoip-dev \
lua-ldap-dev lua-zlib-dev php-all-dev \
php-dev php-igbinary-all-dev php-memcached-all-dev \
postgresql-server-dev-* postgresql-server-dev-all slapi-dev \
systemtap-sdt-dev tcl-dev unixodbc-dev uuid-dev xorg-dev \
zlib1g*dev zlib1g-dev \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold install -fy \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
pkg-config build-essential autoconf bison re2c libxml2-dev libsqlite3-dev freetds-dev \
libmagickwand-dev libmagickwand-6*dev libgraphicsmagick1-dev libmagickcore-6-arch-config \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"


aptold build-dep -fy $PHPV php-defaults \
$PHPV-cli $PHPV-fpm $PHPV-common $PHPV-curl $PHPV-fpm $PHPV-gd \
$PHPV-bcmath $PHPV-bz2 $PHPV-gmp $PHPV-ldap $PHPV-mbstring $PHPV-mysql \
$PHPV-opcache $PHPV-readline $PHPV-soap $PHPV-tidy $PHPV-xdebug $PHPV-xml $PHPV-xsl $PHPV-zip \
php-memcached php-redis php-igbinary php-msgpack php-apcu \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

aptold build-dep -fy php-http php-raphf \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends\|$"

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/$PHPV /root/src/$PHPV
rm -rf /root/src/$PHPV/*deb

#--- fetch default source package
#-------------------------------------------
cd /root/org.src/$PHPV

pkgs=(php-defaults \
$PHPV $PHPV-apcu $PHPV-ast $PHPV-bcmath $PHPV-bz2 $PHPV-cli $PHPV-common \
$PHPV-curl $PHPV-dba $PHPV-dev $PHPV-enchant $PHPV-fpm $PHPV-gd $PHPV-gmp \
$PHPV-igbinary $PHPV-imagick $PHPV-imap $PHPV-interbase \
$PHPV-intl $PHPV-ldap $PHPV-mbstring $PHPV-memcached $PHPV-msgpack \
$PHPV-mysql $PHPV-odbc $PHPV-opcache $PHPV-pgsql $PHPV-pspell \
$PHPV-raphf $PHPV-readline $PHPV-redis $PHPV-snmp $PHPV-soap \
$PHPV-sqlite3 $PHPV-sybase $PHPV-tidy $PHPV-xdebug $PHPV-xml \
$PHPV-xsl $PHPV-zip \
php-memcached php-redis php-igbinary php-msgpack php-apcu \
$PHPV-http php-http php-raphf)

for apkg in "${pkgs[@]}"; do
	printf "\n\n --- apt source: ${yel}$apkg ${end} \n"
	aptold source -my $apkg
done

#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: ${yel}$PHPV ${end}\n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/$PHPV/ /root/src/$PHPV/



#--- wait
#-------------------------------------------
bname=$(basename $0)
printf "\n\n --- wait for all background process...  [$bname] "
while :; do
	nums=$(jobs -r | grep -iv "find\|chmod\|chown" | wc -l)
	printf ".$nums "
	if [[ $nums -lt 1 ]]; then break; fi
	sleep 1
done

wait
printf "\n\n --- wait finished... \n\n\n"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: ${yel}$PHPV ${end}\n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/$PHPV/ /root/src/$PHPV/




#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends\|$"

find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;