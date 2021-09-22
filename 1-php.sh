#!/bin/bash

printf "\ncopy from ~/org.src \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/ /root/src/php8/


BASE="/root/src/php8/php8.0-8.0.10"
cd $BASE


singles=(mcrypt vips uuid gearman apcu imagick raphf http msgpack igbinary memcached)
# singles=(memcached)

finds=$(find /root/src/php8 -mindepth 2 -maxdepth 2 -type d | grep -v "debian\|\.pc\|bc" | sed -r "s/\s/\n/g" | sort)

for adir in "${singles[@]}"; do
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


if [ ! -e /root/org.src/php8/git-phpredis ]; then
	/bin/bash /tb2/build/dk-prep-gits.sh
fi

printf "\n---copy redis \n"
dst_dir="$BASE/ext/redis"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/git-phpredis /root/src/php8/git-phpredis
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/git-phpredis $dst_dir
# cp /root/src/php8/git-phpredis $dst_dir -Rfa
exit 0;

printf "\n\n"

./buildconf -f
./configure --help | sort | grep --color -i "mcrypt\|vips\|uuid\|gearman\|apcu\|imagick\|raphf\|http\|msgpack\|igbinary\|memcached\|redis" |\
grep -v "https\:" | sed -r "s/\s+/ /g" | sed -r "s/^\s//g" | cut -d" " -f1 > extras-conf


# backup first
if [ ! -e /tb2/tmp/ext-common.mk ]; then
	cp $BASE/debian/rules.d/ext-common.mk /tb2/tmp/ext-common.mk
fi

# copy back
cp /tb2/tmp/ext-common.mk $BASE/debian/rules.d/ext-common.mk -fa


# --enable-redis-lz4 \
# --enable-redis-lzf \

# dba_config = --enable-dba=shared,/opt/dba \
# 	--with-db4=/opt/dba \
# 	--without-gdbm \
# 	--with-qdbm=/usr \
# 	--with-lmdb=/usr \
# 	--enable-inifile \
# 	--enable-flatfile

# raph_config = --enable-raphf=shared,/usr

# http_config = --with-http=shared,/usr \
# 	--with-http-libbrotli-dir=/usr \
# 	--with-http-libcurl-dir=/usr \
# 	--with-http-libevent-dir=/usr \
# 	--with-http-libicu-dir=/usr \
# 	--with-http-libidn2-dir=/usr \
# 	--with-http-libidn-dir=/usr \
# 	--with-http-libidnkit2-dir=/usr \
# 	--with-http-libidnkit-dir=/usr \
# 	--with-http-zlib-dir=/usr



echo \
"

# common_EXTENSIONS += mcrypt vips uuid gearman apcu imagick raphf http msgpack igbinary memcached redis dba
common_EXTENSIONS += mcrypt vips uuid gearman apcu imagick msgpack igbinary memcached redis

igbinary_config = --enable-igbinary=shared,/usr \
	--enable-memcached-igbinary \
	--enable-redis-igbinary

msgpack_config = --with-msgpack=shared,/usr \
	--enable-redis-msgpack \
	--enable-memcached-msgpack

memcached_config = --enable-memcached=shared,/usr \
	--enable-memcached-json \
	--enable-memcached-session \
	--with-libmemcached-dir=/usr

redis_config = --enable-redis=shared,/usr \
	--enable-redis-zstd \
	--enable-redis-session

imagick_config = --with-imagick=shared,/usr

apcu_config = --enable-apcu=shared,/usr \
	--enable-apcu-mmap \
	--enable-apcu-rwlocks \
	--enable-redis-json \
	--enable-apcu-clear-signal \
	--enable-apcu-spinlocks

mcrypt_config = --with-mcrypt=shared,/usr
uuid_config = --with-uuid=shared,/usr
vips_config = --with-vips=shared,/usr
gearman_config = --with-gearman=shared,/usr

common_EXTENSIONS += dba
dba_config = --disable-dba


">>$BASE/debian/rules.d/ext-common.mk

cat $BASE/debian/rules.d/ext-common.mk
rm -rf $BASE/debian/rules.d/ext-dba.mk


# speacial for dba
mkdir -p /opt/dba
ln -sf /usr/include /opt/dba/include
ln -sf /usr/lib /opt/dba/lib


# debian/rules mods
sed -i -r "s/apache2 phpdbg embed fpm cgi cli/fpm cli/g" debian/rules
sed -i -r "s/amd64 i386 arm64/amd64/g" debian/rules
sed -i -r "s/\.\/buildconf --force/autoreconf --force --install --verbose\n  \.\/buildconf --force/g" debian/rules
# sed -i -r "s///g" debian/rules

dh clean
autoreconf --force --install --verbose
libtoolize && aclocal && autoconf
if ! dh_auto_configure; then printf "\n\n\n--- dh_auto_configure failed \n\n\n"; exit 0; fi
if ! dh build; then printf "\n\n\n--- dh build failed \n\n\n"; exit 0; fi
