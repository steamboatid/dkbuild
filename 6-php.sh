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

printf "\n-- rsync PHP CORE \n"
mkdir -p $BASE
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
--delete --exclude '.git' \
$BORG/ $BASE/



prepare_source() {

	printf "\n-- rsync PHP CORE \n"
	mkdir -p $BASE
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	$BORG/ $BASE/

	gitmods=( gearman http raphf redis parallel dbase mathstats sync lzf )
	for amod in "${gitmods[@]}"; do
		printf "\n-- rsync $amod \n"
		mkdir -p $BASE/ext/$amod/
		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		--delete --exclude '.git' \
		/root/org.src/git-$amod/ $BASE/ext/$amod/
	done

	amod="tensor"
	printf "\n-- rsync $amod \n"
	mkdir -p $BASE/ext/$amod/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-$amod/ext/ $BASE/ext/$amod/

	# printf "\n-- rsync eio \n"
	# mkdir -p $BASE/ext/eio/
	# rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	# --delete --exclude '.git' \
	# /root/org.src/git-eio/ $BASE/ext/eio/

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
cd $BASE


# iconv_config = --with-iconv=shared
# raphf_config = --enable-raphf=shared

# http_config = --with-http=shared \
# 	--enable-raphf=shared \
# 	--with-iconv=shared \
# 	--without-http-shared-deps
# --without-http-shared-deps \

# memcached_config = --with-memcached=shared \
# --with-libmemcached-dir=/usr \
# --enable-memcached-session \
# --enable-memcached-json

# igbinary  memcached
# igbinary_config = --enable-igbinary=shared
# --enable-igbinary=shared --enable-redis-igbinary \
# --with-msgpack=shared --enable-memcached-msgpack \

# memcached_config = --with-memcached \
# --with-libmemcached-dir=/usr \
# --enable-memcached-session \
# --enable-memcached-json \
# --enable-shared=memcached,msgpack --disable-option-checking


# msgpack redis
# msgpack_config = --with-msgpack=shared

# redis_config = --enable-redis=shared \
# --enable-redis-zstd \
# --with-liblz4=/usr \
# --with-liblzf=/usr \
# --enable-redis-lz4 \
# --with-msgpack=shared --enable-redis-msgpack \
# --enable-shared=redis,msgpack --disable-option-checking

#  igbinary
# igbinary_config = --enable-igbinary=shared


# http 
# iconv_config = --with-iconv=shared
# raphf_config = --enable-raphf=shared
# http_config = --with-http=shared \
# --enable-raphf \
# --with-iconv \
# --without-http-shared-deps \
# --enable-shared=http --disable-option-checking


commonlist="gearman mcrypt uuid vips imagick apcu msgpack dbase stats iconv lzf"
commonconf="gearman_config = --with-gearman=shared
mcrypt_config = --with-mcrypt=shared
uuid_config = --with-uuid=shared
vips_config = --with-vips=shared
imagick_config = --with-imagick=shared
apcu_config = --enable-apcu=shared
iconv_config = --with-iconv=shared
msgpack_config = --with-msgpack=shared
dbase_config = --enable-dbase=shared
stats_config = --enable-stats=shared
lzf_config = --enable-lzf
"

extlist="parallel sync tensor"
extconf="parallel_config = --enable-zts --enable-parallel=shared
sync_config = --enable-zts --enable-sync=shared
tensor_config--enable-tensor
"

echo \
"ext_PACKAGES      += common
common_DESCRIPTION := documentation, examples and common

common_EXTENSIONS  := calendar ctype exif fileinfo ffi ftp gettext pdo phar posix \
shmop sockets sysvmsg sysvsem sysvshm tokenizer \
${commonlist}

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

${commonconf}

export pdo_PRIORITY
export common_EXTENSIONS
export common_DESCRIPTION

">debian/rules.d/ext-common.mk


if [[ $(grep "-extramods" debian/control | wc -l) -lt 1 ]]; then
	echo \
"

Package: php8.0-extramods
Architecture: any
Depends: ucf,
         \${misc:Depends},
         \${php:Depends},
         \${shlibs:Depends}
Pre-Depends: \${misc:Pre-Depends}
Built-Using: \${php:Built-Using}
Description: Extra modules for PHP.
">>debian/control

	echo \
"ext_PACKAGES      += extramods
extramods_DESCRIPTION := extra modules
extramods_EXTENSIONS  := ${extlist}

${extconf}

export extramods_EXTENSIONS
export extramods_DESCRIPTION
">debian/rules.d/ext-extramods.mk
fi


# --enable-memcached --with-libmemcached-dir=\/usr --enable-memcached-session --enable-memcached-json \
# --enable-memcached-msgpack \
# --enable-shared=http,raphf,iconv,memcached,redis,msgpack,gearman,mcrypt,uuid,vips,imagick,apcu \

# static build
#---------------------------------------------------
DKCONF="DK_CONFIG \:\= --with-http=shared --enable-raphf --with-iconv --without-http-shared-deps \
--disable-option-checking --enable-shared=http \n\n"
sed -i -r "s/^COMMON_CONFIG/${DKCONF} \nCOMMON_CONFIG/g" debian/rules
sed -i -r "s/PCRE_JIT\)/PCRE_JIT\) \\$\(DK_CONFIG\)/g" debian/rules
# printf "\n\n $DKCONF \n"


# echo \
# "#!/bin/bash
# adir=\$1
# phpapi=\$(cat debian/phpapi)

# cd \$adir
# pwd
# phpize >/dev/null 2>&1 && ./configure >/dev/null 2>&1 && make -iks >/dev/null 2>&1
# mkdir -p .libs build
# cp modules/* .libs/ -fav
# cp modules/* build/ -fav

# mkdir -p ../../debian/tmp
# cp modules/* ../../debian/tmp/ -fav

# mkdir -p ../../debian/tmp/usr/lib/php/\$phpapi/
# cp modules/*.so ../../debian/tmp/usr/lib/php/\$phpapi/ -fav
# ">doext.sh

# echo \
# "#!/bin/bash
# printf \"\n\n\n\n \"
# for adir in \$(find ext -mindepth 1 -maxdepth 1 -type d | sort); do
# printf \"\n \$adir \"
# bash doext.sh \$adir >/dev/null 2>&1 &
# sleep 0.3
# done
# printf \"\n\n\n\n \"
# ">dkext.sh

# DKPREPEXT="prepext\:\n\
# 	\/bin\/bash \.\/dkext\.sh \n\n"
# sed -i -r "s/^prepared\: /$DKPREPEXT \nprepared\: prepext /g" debian/rules
# sed -i -r "s/^override_dh_auto_install\:/override_dh_auto_install\: prepext /g" debian/rules
# sed -i -r "s/^override_dh_auto_build-arch\:/override_dh_auto_build-arch\: prepext /g" debian/rules
# sed -i -r "s/PHONY\: prepared/PHONY\: prepext prepared/g" debian/rules
# cat debian/rules | grep "prepared"; cat debian/rules | grep "prepext";
# cat debian/rules; exit 0;


# disable all dh_shlibdeps warnings
#---------------------------------------------------
if [[ $(grep "override_dh_shlibdeps" debian/rules | wc -l) -lt 1 ]]; then
	DKSHLIBDEPS="override_dh_shlibdeps\: \n\
		dh_shlibdeps --  --warnings=0 --ignore-missing-info \n\n"
	sed -i -r "s/\.PHONY/${DKSHLIBDEPS} \n\.PHONY/g" debian/rules
fi

# sed -i -r "s/PHP_ADD_EXTENSION_DEP\(\[http\], \[raphf\]/dnl PHP_ADD_EXTENSION_DEP\(\[http\], \[raphf\]/g" ext/http/config9.m4
# sed -i -r "s/(.*)(true)\)/\1false\)/g" ext/http/config9.m4
# cat ext/http/config9.m4; exit 0


# activate zts and parallel extension
#---------------------------------------------------
DKCLICONF="--enable-zts --enable-parallel=shared --enable-sync=shared"
sed -i -r "s/export cli_config \= /export cli_config = ${DKCLICONF} /g" debian/rules


# continue on missing
#---------------------------------------------------
sed -i -r "s/dh_install \-\-fail-missing/dh_install/g" debian/rules
# sed -i -r "s/disable\-static/enable\-static/g" debian/rules
# sed -i -r "s/make -f/make -f -B -i -k/" debian/rules
sed -i -r "s/^\#\$\(info/\$\(info/" debian/rules


# fix raphf bug
#---------------------------------------------------
ln -sf $BASE/ext/raphf/php_raphf.h $BASE/ext/raphf/src/php_raphf.h
ln -sf $BASE/ext/raphf/src/php_raphf_api.c $BASE/ext/raphf/php_raphf_api.c
ln -sf $BASE/ext/raphf/src/php_raphf_api.h $BASE/ext/raphf/php_raphf_api.h
rm -rf $BASE/ext/raphf/src/php_raphf_test.c
# ls -la $BASE/ext/raphf/src; exit 0;


# avoid warning
#---------------------------------------------------
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
	if [ -d ext-build ]; then
		cd ext-build
		make
		cd ..
	fi

	tail -n30 dkbuild.log
	cat dkbuild.log | grep -i "cannot "
fi