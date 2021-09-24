#!/bin/bash
export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)




prepare_source() {

	if [ ! -e /root/org.src/git-gearman ]; then
		printf "\n\n-- update gearman git at org.src \n"
		get_update_new_git "php/pecl-networking-gearman" "/root/org.src/git-gearman"
	fi

	if [ ! -e /root/org.src/git-http ]; then
		printf "\n\n-- update pecl http git at org.src \n"
		get_update_new_git "m6w6/ext-http" "/root/org.src/git-http"
	fi

	if [ ! -e /root/org.src/git-raphf ]; then
		printf "\n\n-- update pecl raphf git at org.src \n"
		get_update_new_git "m6w6/ext-raphf" "/root/org.src/git-raphf"
	fi

	if [ ! -e /root/org.src/git-phpredis ]; then
		printf "\n\n-- update phpredis git at org.src \n"
		get_update_new_git "steamboatid/phpredis" "/root/org.src/git-phpredis"
	fi

	printf "\ncopy from ~/org.src \n"
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/php8/ /root/src/php8/

	printf "\n\n-- rsync gearman \n"
	rm -rf /root/src/php8/$BNAME/ext/gearman/
	mkdir -p /root/src/php8/$BNAME/ext/gearman/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-gearman/ /root/src/php8/$BNAME/ext/gearman/

	printf "\n\n-- rsync http \n"
	rm -rf /root/src/php8/$BNAME/ext/http/
	mkdir -p /root/src/php8/$BNAME/ext/http/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-http/ /root/src/php8/$BNAME/ext/http/

	printf "\n\n-- rsync raphf \n"
	rm -rf /root/src/php8/$BNAME/ext/raphf/
	mkdir -p /root/src/php8/$BNAME/ext/raphf/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-raphf/ /root/src/php8/$BNAME/ext/raphf/

	printf "\n\n-- rsync phpredis \n"
	rm -rf /root/src/php8/$BNAME/ext/redis/
	mkdir -p /root/src/php8/$BNAME/ext/redis/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-phpredis/ /root/src/php8/$BNAME/ext/redis/
	# exit 0;


	aptold install -fy \
	libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
	libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
	libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev
}


copy_extra_mods() {
	# mods=(mcrypt vips uuid apcu imagick msgpack igbinary memcached)
	mods=(mcrypt vips uuid imagick msgpack igbinary memcached)

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


source /tb2/build/dk-build-0libs.sh
/bin/bash /tb2/build/dk-config-gen.sh

reset_build_flags
prepare_build_flags


# find php8.0 folder
BNAME=$(basename $(find /root/src/php8 -mindepth 1 -maxdepth 1 -type d -name "php8.0*"))
BASE="/root/src/php8/$BNAME"
BORG="/root/org.src/php8/$BNAME"
cd $BASE

prepare_source



[ -e Makefile ] && make clean
./buildconf -f
# exit 0;


copy_extra_mods


# backup ext-common.mk first
if [ ! -e /tb2/tmp/ext-common.mk ]; then
	cp $BASE/debian/rules.d/ext-common.mk /tb2/tmp/ext-common.mk
fi

# copy ext-common.mk back
cp /tb2/tmp/ext-common.mk $BASE/debian/rules.d/ext-common.mk -fa



# common_EXTENSIONS += apcu
# apcu_config = --enable-apcu=shared
# apc_config = --enable-apcu=shared

echo \
"
common_EXTENSIONS += raphf http gearman
gearman_config = --with-gearman=shared
raphf_config = --enable-raphf=shared
http_config = --with-http=shared

common_EXTENSIONS += mcrypt vips uuid imagick
mcrypt_config = --with-mcrypt=shared
vips_config = --with-vips=shared
uuid_config = --with-uuid=shared
imagick_config = --with-imagick=shared

common_EXTENSIONS += igbinary
igbinary_config = --enable-igbinary=shared \
--enable-memcached-igbinary \
--enable-redis-igbinary

common_EXTENSIONS += msgpack
msgpack_config = --with-msgpack=shared \
--enable-redis-msgpack \
--enable-memcached-msgpack

common_EXTENSIONS += memcached
memcached_config = --enable-memcached=shared \
--with-libmemcached-dir=/usr \
--enable-memcached-session \
--enable-memcached-json

common_EXTENSIONS += redis
redis_config = --enable-redis=shared \
--enable-redis-zstd

dba_config = --disable-dba \
	--without-db4 \
	--without-gdbm \
	--without-qdbm \
	--without-lmdb \
	--disable-inifile \
	--disable-flatfile

">>$BASE/debian/rules.d/ext-common.mk
cat $BASE/debian/rules.d/ext-common.mk; exit 0;

# cat $BASE/debian/rules.d/ext-common.mk | sed -r "s/with-iconv\=shared/with-iconv/g" | \
# sed -r "s/\=shared\,\/usr/\=\/usr/g" | sed -r "s/\=shared//g" \
# > /tmp/ext-common.mk
# mv /tmp/ext-common.mk $BASE/debian/rules.d/ext-common.mk

# cat $BASE/debian/rules.d/ext-common.mk; exit 0;


# debian/rules mods
sed -i -r "s/apache2 phpdbg embed fpm cgi cli/fpm cli/g" debian/rules
sed -i -r "s/amd64 i386 arm64/amd64/g" debian/rules
sed -i -r "s/\-pedantic//g" debian/rules


dh clean
fakeroot debian/rules clean


types=(apache2 phpdbg embed cgi dev)
for atype in "${types[@]}"; do
	printf "\ndelete debian/php-$atype*"
	rm -rf debian/php-$atype*
done
rm -rf debian/libphp-embed* debian/libapache2-mod*
printf "\n\n"

bash /tb2/build/dk-build-full.sh

sapi/cli/php -m
