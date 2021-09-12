#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

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
deb-src [trusted=yes] http://repo.aisits.id/phideb ${RELNAME} main
">/etc/apt/sources.list.d/phideb.list


cd `mktemp -d`; \
apt update;\
dpkg --configure -a; \
apt install -yf locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
gnupg2 apt-utils tzdata curl && \
echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen &&\
apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys &&\
apt update; apt full-upgrade -fy



cd `mktemp -d`; apt remove php* -fy


apt install -yf   --no-install-recommends --auto-remove --purge \
php8.0-cli php8.0-fpm php8.0-common php8.0-curl php8.0-fpm php8.0-gd \
php8.0-bcmath php8.0-bz2 php8.0-gmp php8.0-ldap php8.0-mbstring php8.0-mysql \
php8.0-opcache php8.0-readline php8.0-soap php8.0-tidy php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip \
php-memcached php-redis php-igbinary php-msgpack php-http php-raphf \
autoconf curl dh-make dh-php gcc ghostscript gifsicle imagemagick jpegoptim keydb-server keydb-tools make \
mariadb-client \
mcrypt memcached optipng pdftk pkg-config pkg-php-tools pngquant qpdf wkhtmltopdf xfonts-75dpi xvfb zlib1g-dev