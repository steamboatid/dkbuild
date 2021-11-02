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


# global config
global_git_config  &

# chown apt
chown_apt

# fix keydb perm
fix_keydb_permission_problem

# purge pendings
purge_pending_installs

# delete unpacked folders
mkdir -p /root/org.src /root/src
find /root/org.src -mindepth 2 -maxdepth 2 -type d -exec rm -rf {} \;
find /root/src -mindepth 2 -maxdepth 2 -type d -exec rm -rf {} \;

# prepare basic need: apt configs, sources list, etc
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh
/bin/bash /tb2/build/dk-prep-basic.sh
/bin/bash /tb2/build/dk-prep-net.sh
/bin/bash /tb2/build/dk-prep-gits.sh


# NGINX, source via git
#-------------------------------------------
aptold update
aptold full-upgrade --fix-missing -fy
aptold install -fy   --no-install-recommends \
devscripts build-essential lintian debhelper git git-extras wget axel \
diffutils patch patchutils quilt git dgit \
curl make gcc libpcre3 libpcre3-dev libpcre++-dev zlib1g-dev libbz2-dev libxslt1-dev libxml2-dev \
libgeoip-dev libgoogle-perftools-dev libperl-dev libssl-dev libcurl4-openssl-dev libgd-dev libgeoip-dev libssl-dev libpcre++-dev libxslt1-dev \
gcc libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev  libgd-dev google-perftools libgoogle-perftools-dev libperl-dev \
libatomic-ops-dev libgeoip1 libgeoip-dev libperl-dev \
libmaxminddb-dev libexpat-dev libldap2-dev libedit-dev openssl clang \
libpcre3 build-essential libpcre3 libpcre3-dev zlib1g-dev \
webp libwebp-dev libgeoip-dev lua-geoip-dev \
libluajit*dev luajit \
webp libwebp-dev libgeoip-dev lua-geoip-dev libsodium-dev

aptold build-dep -fydu nginx lua-resty-core lua-resty-lrucache libpcre3 libsodium-dev
aptold install -fydu --fix-broken  --allow-downgrades --allow-change-held-packages
save_local_debs


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/nginx /root/src/nginx \
/root/org.src/lua-resty-lrucache /root/src/lua-resty-lrucache \
/root/org.src/lua-resty-core /root/src/lua-resty-core

rm -rf /root/src/nginx/*deb \
/root/src/lua-resty-lrucache/*deb \
/root/src/lua-resty-core/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/nginx" "/root/org.src/nginx/git-nginx"
get_update_new_github "steamboatid/lua-resty-lrucache" "/root/org.src/lua-resty-lrucache/git-lua-resty-lrucache"
get_update_new_github "steamboatid/lua-resty-core" "/root/org.src/lua-resty-core/git-lua-resty-core"

mkdir -p /root/org.src/pcre /root/src/pcre
cd /root/org.src/pcre
chown_apt
apt source -y libpcre3


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src pcre \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/pcre/ /root/src/pcre/

#-- nginx source bug, nchan
rm -rf /root/src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan


# PHP8, source via default + git
#-------------------------------------------
aptold install -fy --fix-broken
# apt-cache search libmagickwand  2>&1 | awk '{print $1}' | grep dev | xargs aptold install -y


aptold install -fy pkg-config build-essential autoconf bison re2c \
libxml2-dev libsqlite3-dev curl make gcc devscripts debhelper dh-apache2 apache2-dev libc-client-dev \
	2>&1 | grep --color=auto "Depends"

aptold install -fy libwebp-dev \
	2>&1 | grep --color=auto "Depends"
aptold install -fy libwebp-dev libwebp6 libgd-dev \
	2>&1 | grep --color=auto "Depends"
aptold install -fy libgd-dev libgd3 \
	2>&1 | grep --color=auto "Depends"


aptold install -fy --no-install-recommends  --allow-downgrades \
php8.0 \
php8.0 php8.0-apcu php8.0-ast php8.0-bcmath php8.0-bz2 php8.0-cli php8.0-common \
php8.0-curl php8.0-dba php8.0-dev php8.0-enchant php8.0-fpm php8.0-gd php8.0-gmp \
php8.0-http php8.0-igbinary php8.0-imagick php8.0-imap php8.0-interbase \
php8.0-intl php8.0-ldap php8.0-mbstring php8.0-memcached php8.0-msgpack \
php8.0-mysql php8.0-odbc php8.0-opcache php8.0-pgsql php8.0-pspell php8.0-raphf \
php8.0-readline php8.0-redis php8.0-snmp php8.0-soap php8.0-sqlite3 php8.0-sybase \
php8.0-tidy php8.0-xml php8.0-xsl php8.0-zip \
php8.0 \
php8.0-cli php8.0-fpm php8.0-common php8.0-curl php8.0-fpm php8.0-gd \
php8.0-bcmath php8.0-bz2 php8.0-gmp php8.0-ldap php8.0-mbstring php8.0-mysql \
php8.0-opcache php8.0-readline php8.0-soap php8.0-tidy php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip \
php-memcached php-redis php-igbinary php-msgpack php-http php-raphf php-apcu \
pkg-php-tools libdistro-info-perl php-all-dev \
	2>&1 | grep --color=auto "Depends"

aptold install -fy --no-install-recommends  --allow-downgrades \
devscripts build-essential lintian debhelper git git-extras wget axel dh-make dh-php ccache \
aspell aspell-en chrpath default-libmysqlclient-dev dictionaries-common emacsen-common firebird-dev firebird3.0-common firebird3.0-common-doc flex freetds-common \
freetds-dev libapparmor-dev libargon2-dev libaspell-dev libaspell15 libblkid-dev libbsd-dev libbz2-dev libct4 libcurl4-openssl-dev libdb-dev libdb5.3-dev libedit-dev \
libenchant-dev libenchant1c2a libevent-* libevent-dev libfbclient2 libffi-dev \
libgcrypt20-dev libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgmp-dev libgmp3-dev libgmpxx4ldbl libgpg-error-dev libhunspell-1.7-0 libib-util \
libkrb5-dev liblmdb-dev libltdl-dev libltdl7 libmagic-dev libmariadb-dev libmariadb-dev-compat libmhash-dev libmhash2 libmount-dev libncurses-dev libnss-myhostname \
libodbc1 libonig-dev libonig5 libpci-dev libpcre2-32-0 libpcre2-dev libpq-dev libpq5 libpspell-dev libqdbm-dev libqdbm14 libsasl2-dev libselinux1-dev \
libsensors4-dev libsepol1-dev libsnmp-base libsnmp-dev libsnmp40 libsodium-dev libsodium23 libsybdb5 libsystemd-dev libtext-iconv-perl libtidy-dev libtidy5deb1 \
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
libdb5*dev libdb4*dev libdn*dev libidn*dev libomp-dev \
	2>&1 | grep --color=auto "Depends"

apt-cache search libdb | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
xargs aptold install -fy  --no-install-recommends  --allow-downgrades \
	2>&1 | grep --color=auto "Depends"
apt-cache search db5 | grep -v 4.8 | grep -i berkeley | awk '{print $1}' | \
xargs aptold install -fy  --no-install-recommends  --allow-downgrades \
	2>&1 | grep --color=auto "Depends"

aptold install -fy --no-install-recommends  --allow-downgrades \
default-jdk libx11-dev xorg-dev libcurl4-openssl-dev \
mandoc apache2-dev dh-apache2 libdb-dev \
liblz4-dev lz4 liblz4-* libdirectfb-dev liblzf-dev liblzf-dev
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev libssl-dev libxml2-dev \
libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
php-dev libc6-dev libticonv-dev libiconv-hook-dev \
libghc-iconv-dev libiconv-hook-dev libc-bin \
libqdbm* libgdbm* libxqdbm* libxmlrpc-c*dev xmlrpc-api-utils \
	2>&1 | grep --color=auto "Depends"

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
	2>&1 | grep --color=auto "Depends"

aptold install -fy \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
pkg-config build-essential autoconf bison re2c libxml2-dev libsqlite3-dev freetds-dev \
libmagickwand-dev libmagickwand-6*dev libgraphicsmagick1-dev libmagickcore-6-arch-config \
	2>&1 | grep --color=auto "Depends"


aptold build-dep -fy php8.0 php-defaults \
php8.0-cli php8.0-fpm php8.0-common php8.0-curl php8.0-fpm php8.0-gd \
php8.0-bcmath php8.0-bz2 php8.0-gmp php8.0-ldap php8.0-mbstring php8.0-mysql \
php8.0-opcache php8.0-readline php8.0-soap php8.0-tidy php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip \
php-memcached php-redis php-igbinary php-msgpack php-http php-raphf php-apcu \
	2>&1 | grep --color=auto "Depends"

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/php8 /root/src/php8
rm -rf /root/src/php8/*deb

#--- fetch default source package
#-------------------------------------------
chown_apt
cd /root/org.src/php8
apt source -y php-defaults \
php8.0 php8.0-apcu php8.0-ast php8.0-bcmath php8.0-bz2 php8.0-cli php8.0-common \
php8.0-curl php8.0-dba php8.0-dev php8.0-enchant php8.0-fpm php8.0-gd php8.0-gmp \
php8.0-http php8.0-igbinary php8.0-imagick php8.0-imap php8.0-interbase \
php8.0-intl php8.0-ldap php8.0-mbstring php8.0-memcached php8.0-msgpack \
php8.0-mysql php8.0-odbc php8.0-opcache php8.0-pgsql php8.0-pspell \
php8.0-raphf php8.0-readline php8.0-redis php8.0-snmp php8.0-soap \
php8.0-sqlite3 php8.0-sybase php8.0-tidy php8.0-xdebug php8.0-xml \
php8.0-xsl php8.0-zip \
php-memcached php-redis php-igbinary php-msgpack php-http php-raphf php-apcu


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src php8 \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/ /root/src/php8/

#--- update phpredis from git
#-------------------------------------------
get_update_new_github "steamboatid/phpredis" "/root/org.src/php8/git-phpredis"



# KEYDB, source via git
#-------------------------------------------
killall -9 keydb-server 2>&1 >/dev/null
aptold install -fy build-essential nasm autotools-dev autoconf libjemalloc-dev tcl tcl-dev uuid-dev libcurl4-openssl-dev
aptold build-dep -fy keydb-server keydb-tools
aptold install -fy keydb-server keydb-tools

# fix keyd perm
fix_keydb_permission_problem

killall -9 keydb-server 2>&1 >/dev/null; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1
KEYCHECK=$(keydb-server /etc/keydb/keydb.conf --loglevel verbose --daemonize yes 2>&1 | grep -i "loaded" | wc -l)
if [[ $KEYCHECK -gt 0 ]]; then
	printf "\n\n keydb: OK \n\n"
else
	printf "\n\n keydb: FAILED \n\n"
fi

killall -9 keydb-server 2>&1 >/dev/null
aptold install -y


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/keydb /root/src/keydb
rm -rf /root/src/keydb/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/keydb" "/root/org.src/keydb/git-keydb"



# NUTCRACKER, source via git
#-------------------------------------------
aptold install -fy build-essential fakeroot devscripts libyaml-dev libyaml-0* doxygen nutcracker
aptold build-dep -fy nutcracker

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/nutcracker /root/src/nutcracker
rm -rf /root/src/nutcracker/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/nutcracker" "/root/org.src/nutcracker/git-nutcracker"



# libzip, source via git
#-------------------------------------------
aptold install -fy build-essential fakeroot devscripts liblzma*dev zlib1g*dev bzip2 libzip-dev libzip-dev
aptold build-dep -fy libzip4

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/libzip /root/src/libzip
rm -rf /root/src/libzip/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/libzip" "/root/org.src/libzip/git-libzip"


#--- wait
#-------------------------------------------
printf "\n\n wait for all background process... \n"
wait
printf "\n\n wait finished... \n\n\n"



#--- final delete all *deb
#-------------------------------------------
find /root/src -type f -iname "*.deb" -delete

#--- final rsync org.src to src {WITHOUT delete}
#--- sync to src
#-------------------------------------------
printf "\n-- sync to src ALL \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
--exclude ".git" \
/root/org.src/ /root/src/


#--- last
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;