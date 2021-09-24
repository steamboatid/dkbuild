#!/bin/bash


BASE="/root/src/php8/php8.0-8.0.10"
cd $BASE

rm -rf configure* build debian


printf "\ncopy from ~/org.src \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/ /root/src/php8/


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



# echo \
# "

# # common_EXTENSIONS += mcrypt vips uuid gearman apcu imagick raphf http msgpack igbinary memcached redis dba
# common_EXTENSIONS += mcrypt vips uuid gearman

# mcrypt_config = --with-mcrypt=shared,/usr
# uuid_config = --with-uuid=shared,/usr
# vips_config = --with-vips=shared,/usr
# gearman_config = --with-gearman=shared,/usr

# common_EXTENSIONS += dba opcache
# dba_config = --disable-dba

# opcache_config = --enable-opcache --enable-opcache-file --enable-huge-code-pages

# export pdo_PRIORITY
# export common_EXTENSIONS

# ">>$BASE/debian/rules.d/ext-common.mk

# cat $BASE/debian/rules.d/ext-common.mk
# rm -rf $BASE/debian/rules.d/ext-dba.mk


# speacial for dba
mkdir -p /opt/dba
ln -sf /usr/include /opt/dba/include
ln -sf /usr/lib /opt/dba/lib


# debian/rules mods
sed -i -r "s/apache2 phpdbg embed fpm cgi cli/fpm cli/g" debian/rules
sed -i -r "s/amd64 i386 arm64/amd64/g" debian/rules
sed -i -r "s/\-pedantic//g" debian/rules
# sed -i -r "s/\.\/buildconf --force/autoreconf --force --install --verbose\n  \.\/buildconf --force/g" debian/rules
# sed -i -r "s///g" debian/rules

# configure.ac. mods
# echo \
# "m4_include([/usr/share/aclocal/libtool.m4])
# m4_include([/usr/share/aclocal/ltoptions.m4])
# m4_include([/usr/share/aclocal/ltsugar.m4])
# m4_include([/usr/share/aclocal/ltversion.m4])
# m4_include([/usr/share/aclocal/lt~obsolete.m4])
# ">build/aclocal.m4
# echo \
# "m4_include([build/aclocal.m4])
# AC_CONFIG_MACRO_DIRS([m4])

# ">extras-m4
# sed -i '/m4_include(\[build\/ax_check/e cat extras-m4' configure.ac

dh clean
fakeroot debian/rules clean

# autoreconf --force --install --verbose
# libtoolize && aclocal && autoconf
# if ! dh_auto_configure; then printf "\n\n\n--- dh_auto_configure failed \n\n\n"; exit 0; fi
# if ! dh binary; then printf "\n\n\n--- dh build failed \n\n\n"; exit 0; fi

types=(apache2 phpdbg embed cgi dev)
for atype in "${types[@]}"; do
	printf "\ndelete debian/php-$atype*"
	rm -rf debian/php-$atype*
done
rm -rf debian/libphp-embed* debian/libapache2-mod*
printf "\n\n"

bash /tb2/build/dk-build-full.sh
# make -j6
