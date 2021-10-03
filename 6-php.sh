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

	if [ ! -e /root/org.src/git-redis ]; then
		printf "\n\n-- update redis git at org.src \n"
		get_update_new_git "steamboatid/phpredis" "/root/org.src/git-redis"
	fi


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
	mkdir -p $BASE/ext/raphf/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-raphf/ $BASE/ext/raphf/

	printf "\n-- rsync redis \n"
	mkdir -p $BASE/ext/redis/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--delete --exclude '.git' \
	/root/org.src/git-redis/ $BASE/ext/redis/
	# exit 0;


	aptold install -fy \
	libbz2-dev libc-client-dev libkrb5-dev libcurl4-openssl-dev libffi-dev libgmp-dev \
	libldap2-dev libonig-dev libpq-dev libpspell-dev libreadline-dev \
	libssl-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libsodium-dev libavif*dev \
	pkg-config build-essential autoconf bison re2c libxml2-dev libsqlite3-dev freetds-dev \
	libmagickwand-dev libmagickwand-6*dev libgraphicsmagick1-dev libmagickcore-6-arch-config \
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




printf "\n prepare_source "
prepare_source

printf "\n get_mod_sources_deb "
get_mod_sources_deb

printf "\n copy_extra_mods "
copy_extra_mods


echo \
"

common_EXTENSIONS  += redis memcached igbinary msgpack
caching_config      := --enable-igbinary \
	--enable-memcached-igbinary \
	--enable-redis-igbinary \
	--with-msgpack=shared \
	--enable-redis-msgpack \
	--enable-memcached-msgpack \
	--enable-memcached=shared \
	--with-libmemcached-dir \
	--enable-memcached-session \
	--enable-memcached-json \
	--enable-redis=shared \
	--enable-redis-zstd \
	--with-liblz4=/usr \
	--with-liblzf=/usr \
	--enable-redis-lz4 \
	--enable-pdo=shared,/usr
export common_EXTENSIONS
export common_DESCRIPTION
">>debian/rules.d/ext-common.mk


echo \
"

common_EXTENSIONS  += gearman mcrypt uuid vips imagick apcu raphf
moremods_config      := --with-gearman=shared \
	--with-mcrypt=shared \
	--with-uuid=shared \
	--with-vips=shared \
	--with-imagick=shared \
	--enable-apcu=shared \
	--enable-raphf=shared \
	--enable-pdo=shared,/usr
export common_EXTENSIONS
export common_DESCRIPTION
">>debian/rules.d/ext-common.mk


echo \
"">debian/rules.d/ext-httpraph.mk


# sed -i -r "s/iconv\=shared/iconv/g" debian/rules.d/ext-common.mk



# sed -i -r "s/apache2 phpdbg embed fpm cgi cli/cli/g" debian/rules
# sed -i -r "s/\-\-fail\-missing//g" debian/rules
# sed -i -r "s/prepare\-fpm\-pools//g" debian/rules

# cp /tb2/build/dk-php-control $BASE/debian/control -Rfav
# cat $BASE/debian/control | grep --color=auto more
# # exit 0;

# rm -rf $BASE/debian/libapache2-* $BASE/debian/libphp* $BASE/debian/php-cgi*  $BASE/debian/php-fpm* \
#  $BASE/debian/php-phpdbg* $BASE/debian/rules.d/prepare-fpm-pools.mk


rm -rf $BASE/ext/http
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


./buildconf -f
/bin/bash /tb2/build/dk-build-full.sh
