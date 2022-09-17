#!/bin/bash

#
# this script will delete ALL non-essential packages
#

source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm

apt purge --auto-remove --purge \
build-essential bison re2c \
libxml2-dev libsqlite3-dev make gcc devscripts debhelper dh-apache2 apache2-dev libc-client-dev \
libwebp-dev libwebp-dev libwebp6 libgd-dev libgd-dev libgd3 \
build-essential lintian debhelper git git-extras axel dh-make dh-php  \
aspell aspell-en chrpath default-libmysqlclient-dev dictionaries-common \
emacsen-common firebird-dev firebird3.0-common firebird3.0-common-doc flex freetds-common \
freetds-dev libapparmor-dev libargon2-dev libaspell-dev libaspell15 libblkid-dev libbsd-dev libbz2-dev libct4 libcurl4-openssl-dev libdb-dev libdb5.3-dev libedit-dev \
libenchant-dev libenchant1c2a libevent-* libevent-dev libfbclient2 libffi-dev \
libgcrypt20-dev libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgmp-dev libgmp3-dev libgmpxx4ldbl libgpg-error-dev libhunspell-1.7-0 libib-util \
libkrb5-dev liblmdb-dev libltdl-dev libltdl7 libmagic-dev libmariadb-dev libmariadb-dev-compat libmhash-dev libmhash2 libmount-dev libncurses-dev libnss-myhostname \
libodbc1 libonig-dev libonig5 libpci-dev libpcre2-32-0 libpcre2-dev libpq-dev libpq5 libpspell-dev libqdbm-dev libqdbm14 libsasl2-dev libselinux1-dev \
libsensors4-dev libsepol1-dev libsnmp-base libsnmp-dev libsnmp* libsodium-dev libsodium23 libsybdb5 libsystemd-dev libtext-iconv-perl libtidy-dev libtidy5deb1 \
libtommath1 libudev-dev libwrap0-dev libxmltok1 libxmltok1-dev libxslt1-dev libzip-dev libzip4 locales-all netcat-openbsd odbcinst odbcinst1debian2 python3-distutils \
python3-lib2to3 systemtap-sdt-dev unixodbc-dev libfl-dev \
bison libbison-dev libc-client2007e libc-client2007e-dev libpam0g-dev libsqlite3-dev libwebpdemux2 mlock re2c \
libgd-dev libgd3 libwebp6 libgd-dev \
libmemcached*dev zlib1g-dev \
apache2-dev autoconf automake bison chrpath debhelper default-libmysqlclient-dev libmysqlclient-dev dh-apache2 dpkg-dev firebird-dev flex freetds-dev \
libapparmor-dev libapr1-dev libargon2-dev libbz2-dev libc-client-dev libdb-dev libedit-dev libenchant-dev libevent-dev libexpat1-dev libffi-dev libfreetype6-dev \
libgcrypt20-dev libglib2.0-dev libgmp3-dev libicu-dev libjpeg-dev libjpeg*dev libkrb5-dev libldap2-dev liblmdb-dev libmagic-dev libmhash-dev libnss-myhostname libonig-dev \
libpam0g-dev libpcre2-dev libpng-dev libpq-dev libpspell-dev libqdbm-dev libsasl2-dev libsnmp-dev libsodium-dev libsqlite3-dev libssl-dev libsystemd-dev libtidy-dev libtool \
libwrap0-dev libxml2-dev libxmltok1-dev libxslt1-dev libzip-dev locales-all netcat-openbsd re2c systemtap-sdt-dev unixodbc-dev zlib1g-dev \
libxml2-dev libpcre3-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libxpm-dev libfreetype6-dev libmysqlclient-dev postgresql-server-dev-all \
libgmp-dev libsasl2-dev libmhash-dev unixodbc-dev freetds-dev libpspell-dev libsnmp-dev libtidy-dev libxslt1-dev libmcrypt-dev \
libpng*dev libdb5*-dev libfreetype*dev libxft*dev libgdchart-gd2-xpm-dev freetds-dev libldb-dev libldap2-dev \
libdb5*dev libdb4*dev libdn*dev libidn*dev libomp-dev mono* \
build-essential nasm autotools-dev autoconf libjemalloc-dev tcl tcl-dev uuid-dev libcurl4-openssl-dev \
build-essential fakeroot devscripts libyaml-dev libyaml* doxygen nutcracker \
liblzma*dev zlib1g*dev bzip2 libzip-dev libzip-dev icu* zstd argon* idn*


apt purge --auto-remove --purge \
php* nginx* keydb* nutc* libzip* \
clang* cmake* cpp gcc mysql* maria* geoip* *spell *pdf jpeg* png* qt* \
libsmb* libxml* libboost* libclang* libcpp* libldap* libqt* lib*perl libx11*

apt purge --auto-remove --purge *-dev
apt purge --auto-remove --purge *dbg

apt purge --auto-remove --purge php* nginx* keydb* nutc* *java pdf* java* *jre* \
*dbg font* *font golang* lua* gir* xz-utils xxd xorriso whois wdiff vlan \
vim-runtime vim usbutils unzip unrar-free traceroute tcpdump vim* shtool \
sharutils screen saidar runit-helper rsync rkhunter rename d-shlibs \
chkrootkit ca-certificates bsdmainutils bsdextrautils tmux
