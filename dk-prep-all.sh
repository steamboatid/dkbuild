#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)


update_old_git() {
	cd $1
	printf "\n---updating $PWD \n"
	git config  --global pull.ff only
	git rm -r --cached . >/dev/null 2>&1
	git submodule update --init --recursive -f
	git fetch --all
	git pull --update-shallow --ff-only
	git pull --depth=1 --ff-only
	git pull --ff-only
	git pull --allow-unrelated-histories
	git pull origin $(git rev-parse --abbrev-ref HEAD) --ff-only
	git pull origin $(git rev-parse --abbrev-ref HEAD) --allow-unrelated-histories
	cd ..
}

get_update_new_git(){
	URL=$1
	DST=$2

	if [ ! -d ${DST} ]; then
		git clone https://github.com/${URL} $DST
	fi

	update_old_git $DST
}

fix_keydb_permission_problem() {
	# return if not installed yet
	if [ `dpkg -l | grep keydb | grep -v "^ii" | wc -l` -lt 1 ]; then return 0; fi

	cd `mktemp -d`; \
	systemctl stop redis-server; systemctl disable redis-server; systemctl mask redis-server; \
	systemctl daemon-reload; apt remove -y redis-server
	mkdir -p /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
	chown keydb.keydb -Rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
	find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type d -exec chmod 775 {} \; ; \
	find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type d -exec chmod 664 {} \;
	sed -i "s/^bind 127.0.0.1 \:\:1/\#-- bind 127.0.0.1 \:\:1\nbind 127.0.0.1/g" /etc/keydb/keydb.conf
	sed -i "s/^logfile \/var/#-- logfile \/var/g" /etc/keydb/keydb.conf
	sed -i "s/^dir \/var/#-- dir \/var/g" /etc/keydb/keydb.conf
	sed -i "s/^dbfilename /#-- dbfilename /g" /etc/keydb/keydb.conf
	sed -i "s/^save 900 /#-- save 900 /g" /etc/keydb/keydb.conf
	sed -i "s/^save 300 /#-- save 300 /g" /etc/keydb/keydb.conf
	sed -i "s/^save 60 /#-- save 60 /g" /etc/keydb/keydb.conf
}

fix_pending_installs() {
	dpkg -l | grep -v "^ii" | grep "^i" | sed -r "s/\s+/ /g" | cut -d" " -f2 > /tmp/pendings

	# install it all
	cat /tmp/pendings | tr "\n" " "| xargs apt install -fy
	cat /tmp/pendings | while read aline; do apt install -fy $aline; done
}

shopt -s expand_aliases
alias aptold='apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

# fix keydb perm
fix_keydb_permission_problem

# fix pendings
fix_pending_installs
fix_pending_installs

# prepare basic need: apt configs, sources list, etc
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh
/bin/bash /tb2/build/dk-prep-basic.sh
/bin/bash /tb2/build/dk-prep-net.sh


# NGINX, source via git
#-------------------------------------------
apt full-upgrade --fix-missing -fy
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

apt build-dep -fy nginx lua-resty-core lua-resty-lrucache libpcre3 libsodium-dev
aptold install -fy --fix-broken  --allow-downgrades --allow-change-held-packages


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/src/nginx \
/root/src/lua-resty-lrucache \
/root/src/lua-resty-core

rm -rf /root/src/nginx/*deb \
/root/src/lua-resty-lrucache/*deb \
/root/src/lua-resty-core/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_git "steamboatid/nginx" "/root/src/nginx/git-nginx"
get_update_new_git "steamboatid/lua-resty-lrucache" "/root/src/lua-resty-lrucache/git-lua-resty-lrucache"
get_update_new_git "steamboatid/lua-resty-core" "/root/src/lua-resty-core/git-lua-resty-core"

mkdir -p /root/org.src/pcre /root/src/pcre
cd /root/org.src/pcre
apt source -y libpcre3

rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
/root/org.src/pcre/* /root/src/pcre/


# PHP8, source via default + git
#-------------------------------------------
aptold install -fy --fix-broken
if [[ "${RELNAME}" == "bullseye" ]]; then
	aptold install -fy libmagickwand-7-*
else
	apt-cache search libmagickwand  2>&1 | awk '{print $1}' | grep dev | xargs apt install -fy
fi


aptold install -fy pkg-config build-essential autoconf bison re2c \
libxml2-dev libsqlite3-dev curl make gcc devscripts debhelper dh-apache2 apache2-dev libc-client-dev

aptold install -fy libwebp-dev
aptold install -fy libwebp-dev libwebp6 libgd-dev
aptold install -fy libgd-dev libgd3


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
pkg-php-tools libdistro-info-perl php-all-dev

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
libdb5*dev libdb4*dev libdn*dev libidn*dev libomp-dev


apt build-dep -fy php8.0 php-defaults \
php8.0-cli php8.0-fpm php8.0-common php8.0-curl php8.0-fpm php8.0-gd \
php8.0-bcmath php8.0-bz2 php8.0-gmp php8.0-ldap php8.0-mbstring php8.0-mysql \
php8.0-opcache php8.0-readline php8.0-soap php8.0-tidy php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip \
php-memcached php-redis php-igbinary php-msgpack php-http php-raphf php-apcu

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/php8 /root/src/php8
rm -rf /root/src/php8/*deb

#--- fetch default source package
#-------------------------------------------
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

rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
/root/org.src/php8/* /root/src/php8/

#--- update phpredis from git
#-------------------------------------------
get_update_new_git "steamboatid/phpredis" "/root/src/php8/git-phpredis"



# KEYDB, source via git
#-------------------------------------------
aptold install -fy build-essential nasm autotools-dev autoconf libjemalloc-dev tcl tcl-dev uuid-dev libcurl4-openssl-dev
apt build-dep -fy keydb-sentinel keydb-server keydb-tools
aptold install keydb-sentinel keydb-server keydb-tools

# fix keyd perm
fix_keydb_permission_problem

killall -9 keydb-server; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1
KEYCHECK=$(keydb-server /etc/keydb/keydb.conf --loglevel verbose --daemonize yes 2>&1 | grep -i "loaded" | wc -l)
if [[ $KEYCHECK -gt 0 ]]; then
	printf "\n\n keydb: OK \n\n"
else
	printf "\n\n keydb: FAILED \n\n"
fi
apt install -fy


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/src/keydb
rm -rf /root/src/keydb/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_git "steamboatid/keydb" "/root/src/keydb/git-keydb"



# NUTCRACKER, source via git
#-------------------------------------------
aptold install -fy build-essential fakeroot devscripts libyaml-dev libyaml-0* doxygen nutcracker
apt build-dep -fy nutcracker

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/src/nutcracker
rm -rf /root/src/nutcracker/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_git "steamboatid/nutcracker" "/root/src/nutcracker/git-nutcracker"
