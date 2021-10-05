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


# find php8.0 folder
BNAME=$(basename $(find /root/src/php8 -mindepth 1 -maxdepth 1 -type d -name "php8.0*"))
BASE="/root/src/php8/$BNAME"
BORG="/root/org.src/php8/$BNAME"
mkdir -p $BASE
cd $BASE



prepare_source() {

	get_update_new_github "php/pecl-networking-gearman" "/root/org.src/git-gearman"
	get_update_new_github "m6w6/ext-http" "/root/org.src/git-http"

	rm -rf /root/org.src/git-raph
	get_update_new_github "m6w6/ext-raphf" "/root/org.src/git-raphf"
	ln -sf /root/org.src/git-raphf/php_raphf.h /root/org.src/git-raphf/src/php_raphf.h
	ln -sf /root/org.src/git-raphf/src/php_raphf_api.c /root/org.src/git-raphf/php_raphf_api.c
	ln -sf /root/org.src/git-raphf/src/php_raphf_api.h /root/org.src/git-raphf/php_raphf_api.h
	rm -rf /root/org.src/git-raphf/src/php_raphf_test.c

	get_update_new_github "steamboatid/phpredis" "/root/org.src/git-redis"

	# https://github.com/krakjoe/parallel
	# get_update_new_github "krakjoe/parallel" "/root/org.src/git-parallel"

	# https://github.com/rosmanov/pecl-eio
	# get_update_new_github "rosmanov/pecl-eio" "/root/org.src/git-eio"

	# https://bitbucket.org/osmanov/pecl-ev.git
	# get_update_new_bitbucket "osmanov/pecl-ev.git" "/root/org.src/git-ev"


	printf "\n-- rsync PHP CORE \n"
	mkdir -p $BASE
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	$BORG/ $BASE/

	printf "\n-- rsync gearman \n"
	mkdir -p $BASE/ext/gearman/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-gearman/ $BASE/ext/gearman/

	printf "\n-- rsync http \n"
	mkdir -p $BASE/ext/http/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-http/ $BASE/ext/http/

	printf "\n-- rsync raphf \n"
	rm -rf /root/org.src/git-raph
	mkdir -p $BASE/ext/raphf/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-raphf/ $BASE/ext/raphf/

	printf "\n-- rsync redis \n"
	mkdir -p $BASE/ext/redis/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-redis/ $BASE/ext/redis/

	# printf "\n-- rsync parallel \n"
	# mkdir -p $BASE/ext/parallel/
	# rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	# --delete --exclude '.git' \
	# /root/org.src/git-parallel/ $BASE/ext/parallel/

	# printf "\n-- rsync eio \n"
	# mkdir -p $BASE/ext/eio/
	# rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	# --delete --exclude '.git' \
	# /root/org.src/git-eio/ $BASE/ext/eio/

	# printf "\n-- rsync ev \n"
	# mkdir -p $BASE/ext/ev/
	# rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	# --delete --exclude '.git' \
	# /root/org.src/git-ev/ $BASE/ext/ev/
	# exit 0;


	aptold install -fy \
	libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
	libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
	libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
	pkg-config build-essential autoconf bison re2c libxml2-dev libsqlite3-dev freetds-dev \
	libmagickwand-dev libmagickwand-6*dev libgraphicsmagick1-dev libmagickcore-6-arch-config \
	libmsgpack-dev libmsgpackc2 \
		2>&1 | grep --color=auto "Depends"

	ln -sf /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/

}


get_mod_sources_deb() {
	PREVDIR=$PWD
	mkdir -p /root/org.src/php8
	cd /root/org.src/php8
	chown -Rf _apt.root /var/lib/update-notifier/package-data-downloads/partial/ /var/cache/apt/archives/partial/
	chmod -Rf 700  /var/lib/update-notifier/package-data-downloads/partial/ /var/cache/apt/archives/partial/

	allmods=(mcrypt vips uuid gearman apcu imagick raphf http msgpack igbinary memcached redis)
	modpkgs=$(apt-cache search php | grep -v "php7\|php5\|php8.1" | \
grep "mcrypt\|vips\|uuid\|gearman\|apcu\|imagick\|raphf\|http\|msgpack\|igbinary\|memcached\|redis" |\
cut -d" " -f1 | tr "\n" " ")
	echo "${modpkgs}" | xargs aptold install -fy    2>&1 | grep "Depends"
	echo "${modpkgs}" | xargs aptold build-dep -fy  2>&1 | grep "Depends"
	echo "${modpkgs}" | xargs aptold source -y      2>&1 | grep "Depends"

	cd $PREVDIR
}


copy_extra_mods() {
	mods=(mcrypt vips uuid apcu imagick msgpack igbinary memcached)

	finds=$(find /root/org.src/php8 -mindepth 2 -maxdepth 2 -type d | grep -v "debian\|\.pc\|bc" | sed -r "s/\s/\n/g" | sort)

	for adir in "${mods[@]}"; do
		adir=$(basename $adir)
		nums=$(printf "$finds" | grep $adir | wc -l)
		printf "\n nums=$nums  $adir "

		dst_dir="$BASE/ext/$adir"

		if [[ $nums -eq 1 ]]; then
			ori_dir=$(printf "$finds" | grep $adir | head -n1)
		elif [[ $nums -gt 1 ]]; then
			ori_dir=$(printf "$finds" | grep $adir | tail -n1)
		fi

		printf "\n copy from $ori_dir --to-- $dst_dir \n\n"
		cp $ori_dir $dst_dir -Rfa
	done
}



printf "\n db4_install "
db4_install

printf "\n prepare_source "
prepare_source

printf "\n get_mod_sources_deb "
get_mod_sources_deb

printf "\n copy_extra_mods "
copy_extra_mods


# igbinary
#
# igbinary_config = --enable-igbinary=shared \
# 	--enable-memcached-igbinary \
# 	--enable-redis-igbinary
#  \
#	--with-msgpack --enable-memcached-msgpack


# memcached_config = --enable-memcached=shared \
# 	--with-libmemcached-dir=/usr \
# 	--enable-memcached-session \
# 	--enable-memcached-json

# iconv_config = --enable-iconv=shared


echo \
"ext_PACKAGES      += common
common_DESCRIPTION := documentation, examples and common

common_EXTENSIONS  := calendar ctype exif fileinfo ffi ftp gettext pdo phar posix \
shmop sockets sysvmsg sysvsem sysvshm tokenizer \
gearman mcrypt uuid vips imagick apcu \
redis

calendar_config = --enable-calendar=shared
ctype_config = --enable-ctype=shared
exif_config = --enable-exif=shared
fileinfo_config = --enable-fileinfo=shared
ffi_config = --with-ffi=shared
ftp_config = --enable-ftp=shared --with-openssl-dir=/usr
gettext_config = --with-gettext=shared,/usr
pdo_config = --enable-pdo=shared
pdo_PRIORITY := 10
phar_config = --enable-phar=shared
posix_config = --enable-posix=shared
shmop_config = --enable-shmop=shared
sockets_config = --enable-sockets=shared
sysvmsg_config = --enable-sysvmsg=shared
sysvsem_config = --enable-sysvsem=shared
sysvshm_config = --enable-sysvshm=shared
tokenizer_config = --enable-tokenizer=shared

gearman_config = --with-gearman=shared
mcrypt_config = --with-mcrypt=shared
uuid_config = --with-uuid=shared
vips_config = --with-vips=shared
imagick_config = --with-imagick=shared
apcu_config = --enable-apcu=shared

redis_config = --enable-redis=shared \
	--enable-redis-zstd \
	--with-liblz4=/usr \
	--with-liblzf=/usr \
	--enable-redis-lz4 \
	--with-msgpack --enable-redis-msgpack

export pdo_PRIORITY
export common_EXTENSIONS
export common_DESCRIPTION

">debian/rules.d/ext-common.mk


# echo \
# "ext_PACKAGES   += allmods
# allmods_DESCRIPTION := all modules for PHP
# allmods_EXTENSIONS  := allmods
# allmods_config = --with-gearman=shared \
# 	--with-mcrypt=shared \
# 	--with-uuid=shared \
# 	--with-vips=shared \
# 	--with-imagick=shared \
# 	--enable-apcu=shared \
# \
# 	--with-msgpack=shared \
# 	--enable-raphf=shared \
# 	--with-iconv=shared \
# \
# 	--enable-redis=shared \
# 	--enable-redis-zstd \
# 	--with-liblz4=/usr \
# 	--with-liblzf=/usr \
# 	--enable-redis-lz4 \
# 	--enable-redis-msgpack \
# \
# 	--enable-memcached=shared \
# 	--with-libmemcached-dir \
# 	--enable-memcached-session \
# 	--enable-memcached-json
# \
# 	--with-http=shared

# export allmods_EXTENSIONS
# export allmods_DESCRIPTION
# ">debian/rules.d/ext-allmods.mk


# if [[ $(grep "allmods" debian/control | wc -l) -lt 1 ]]; then
# 	echo \
# "

# Package: php8.0-allmods
# Architecture: any
# Depends: ucf,
#          \${misc:Depends},
#          \${php:Depends},
#          \${shlibs:Depends}
# Pre-Depends: \${misc:Pre-Depends}
# Built-Using: \${php:Built-Using}
# Description: All modules for PHP
#  This package provides the all modules for PHP.
# ">>debian/control
# fi


# sed -i -r "s/iconv\=shared/iconv/g" debian/rules.d/ext-common.mk



# sed -i -r "s/apache2 phpdbg embed fpm cgi cli/cli/g" debian/rules
# sed -i -r "s/\-\-fail\-missing//g" debian/rules
# sed -i -r "s/prepare\-fpm\-pools//g" debian/rules
# sed -i -r "s/disable\-static/enable\-static/g" debian/rules
# sed -i -r "s/make -f/make -f -B -i -k/" debian/rules

# cp /tb2/build/dk-php-control $BASE/debian/control -Rfav
# cat $BASE/debian/control | grep --color=auto more
# # exit 0;

# rm -rf $BASE/debian/libapache2-* $BASE/debian/libphp* $BASE/debian/php-cgi*  $BASE/debian/php-fpm* \
#  $BASE/debian/php-phpdbg* $BASE/debian/rules.d/prepare-fpm-pools.mk

# rm -rf $BASE/ext/http

# --enable-memcached --with-libmemcached-dir=/usr --enable-memcached-session --enable-memcached-json
# --enable-memcached-msgpack

DKCONF="DK_CONFIG \:\= --with-http --enable-raphf --with-iconv \
--with-msgpack --enable-redis-msgpack \
--enable-memcached --with-libmemcached-dir=/usr --enable-memcached-session --enable-memcached-json \
\n\n"

printf "\n\n $DKCONF \n"
sed -i -r "s/^COMMON_CONFIG/${DKCONF} \nCOMMON_CONFIG/g" debian/rules
sed -i -r "s/PCRE_JIT\)/PCRE_JIT\) \\$\(DK_CONFIG\)/g" debian/rules


# DKCLICONF="--enable-zts --enable-parallel=shared"
# sed -i -r "s/export cli_config \= /export cli_config = ${DKCLICONF} /g" debian/rules
# sed -i -r "s/export fpm_config \= /export fpm_config = ${DKCLICONF} /g" debian/rules


# cat debian/rules;
# cat debian/rules | grep "PCRE_JIT) "; exit 0;

#--- fix raphf bug
ln -sf $BASE/ext/raphf/php_raphf.h $BASE/ext/raphf/src/php_raphf.h
ln -sf $BASE/ext/raphf/src/php_raphf_api.c $BASE/ext/raphf/php_raphf_api.c
ln -sf $BASE/ext/raphf/src/php_raphf_api.h $BASE/ext/raphf/php_raphf_api.h
rm -rf $BASE/ext/raphf/src/php_raphf_test.c
# ls -la $BASE/ext/raphf/src; exit 0;

touch debian/php-cgi.NEWS
touch debian/php-fpm.NEWS
touch debian/libapache2-mod-php.NEWS


./buildconf -f



# revert backup if exists
if [ -e "debian/changelog.1" ]; then
	cp debian/changelog.1 debian/changelog
fi
# backup changelog
cp debian/changelog debian/changelog.1 -fa


# override version from source
#-------------------------------------------
if [ -e main/php_version.h ]; then
	VERSRC=$(cat main/php_version.h | grep "define PHP_VERSION " | sed -r "s/\s+/ /g" | sed "s/\"//g" | cut -d" " -f3)
	VEROVR="${VERSRC}.1"
	printf "\n\n VERSRC=$VERSRC ---> VEROVR=$VEROVR \n"
fi

VERNUM=$(basename "$PWD" | tr "-" " " | awk '{print $NF}' | cut -f1 -d"+")
VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
printf "\n\n$adir \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n"
sleep 1

if [ -e "debian/changelog" ]; then
	VERNUM=$(dpkg-parsechangelog --show-field Version | sed "s/[+~-]/ /g"| cut -f1 -d" ")
	VERNEXT=$(echo ${VERNUM} | awk -F. -v OFS=. '{$NF=$NF+20;print}')
	printf "\n by changelog \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
fi

if [ -n "$VEROVR" ]; then
	VERNEXT=$VEROVR
	printf "\n by VEROVR \n--- VERNUM= $VERNUM NEXT= $VERNEXT---\n\n\n"
fi

dch -p -b "simple rebuild $RELNAME + O3 flag (custom build debian $RELNAME $RELVER)" \
-v "$VERNEXT+$TODAY+$RELVER+$RELNAME+dk.aisits.id" -D buster -u high; \
head debian/changelog


dh clean
fakeroot debian/rules clean

./buildconf -f
/bin/bash /tb2/build/dk-build-full.sh

isok=$(tail -n100 dkbuild.log | grep -i "binary\-only" | wc -l)
if [[ $isok -gt 0 ]]; then
	exit 0;
else
	cd ext-build
	make

	cd ..; tail -n30 dkbuild.log
	cat dkbuild.log | grep -i "cannot "
fi