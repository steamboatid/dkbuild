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
reset_build_flags
prepare_build_flags


get_update_new_git "php/php-src" "/root/org.src/git-php"

mkdir -p /root/src/git-php
rsync -aHAXztrv --numeric-ids --modify-window 5 --omit-dir-times \
--delete --exclude '.git' \
/root/org.src/git-php/ /root/src/git-php/


aptold install -fy \
libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev

cd /root/src/git-php

[ -e Makefile ] && make clean
./buildconf -f

./configure --enable-ftp --with-openssl --disable-cgi \
--enable-bcmath \
--enable-bcmath \
--with-curl \
--enable-exif \
--with-ffi \
--enable-ftp \
--enable-gd --with-webp --with-jpeg --with-webp --without-avif \
--with-gmp \
--with-imap --with-imap-ssl --with-kerberos \
--enable-intl \
--with-ldap \
--enable-mbstring \
--with-openssl \
--with-pdo-mysql \
--with-pdo-mysql \
--with-pspell \
--with-readline \
--enable-sockets \
--with-sodium \
--enable-soap --with-libxml \
\
--enable-posix=shared \
--disable-debug \
--disable-phpdbg \
--disable-rpath \
--enable-calendar=shared \
--enable-ctype=shared \
--enable-dom \
--enable-exif=shared \
--enable-fileinfo=shared \
--enable-filter=shared \
--enable-ftp=shared \
--with-openssl=shared --with-openssl-dir=/usr \
--enable-hash=shared \
--enable-inotify=shared \
--enable-phar=shared \
--enable-session=shared \
--enable-shmop=shared \
--enable-sockets=shared \
--enable-sysvmsg=shared \
--enable-sysvsem=shared \
--enable-sysvshm=shared \
# --enable-tokenizer=shared \
# --enable-xml=shared \
# --localstatedir=/var \
# --mandir=/usr/share/man \
# \
# --with-external-pcre \
# --with-ffi=shared \
# --with-gettext=shared \
# --with-layout=GNU \
# --with-libxml=shared \
# --with-mhash=shared \
# --with-password-argon2=shared \
# --with-pear=shared \
# --with-pic=shared \
# --with-sodium=shared \
# --with-system-tzdata=shared \
# --with-zlib-dir=/usr \
# --with-zlib=shared \



sleep 0.1
sed -i "s/\-g//g" Makefile
sed -i "s/-O2/-O3/g" Makefile
sed -i "s/noeneration-date/no-generation-date/g" Makefile

make -j6
