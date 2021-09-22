#!/bin/bash


BASE="/root/src/git-php"
cd $BASE

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

copy_extra_mods() {
	mods=(mcrypt vips uuid gearman apcu imagick raphf http msgpack igbinary memcached)
	# singles=(memcached)

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

	printf "\n---copy redis \n"
	dst_dir="$BASE/ext/redis"
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
	/root/org.src/php8/git-phpredis $dst_dir
}

>debops
for afile in $(find /root/src/php8/php8.0-8.0.10/debian/rules.d -type f | grep -v "prepare"); do
	cat $afile | grep "with\|enable" | sed -r "s/\://g" | sed -r "s/\+//g" | sed -r "s/\s+/ /g" |\
	sed -r "s/\\\//g" | sed "s/^\s//g" | sed -r "s/(.*)_config = //g" | \
	sed -r "s/\=shared\,/\=/g" | sed -r "s/\=shared//g" >> debops
done
cat debops | tr "\n" " " | sed -r "s/\s+/ /g" | sed -r "s/ / \\\ \n/g" > debops.tmp
mv debops.tmp debops
# cat debops
# exit 0;


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

# copy extra mods
copy_extra_mods

echo \
"--with-gearman=/usr \
--with-mcrypt=/usr \
--with-uuid=/usr \
--with-vips=/usr \
--enable-raphf=/usr \
--enable-apcu=/usr \
--enable-igbinary=/usr \
--with-imagick=/usr \
--enable-memcached=/usr \
--with-libmemcached-dir=/usr \
--enable-memcached-session \
--enable-memcached-igbinary \
--enable-memcached-json \
--enable-memcached-msgpack \
--with-msgpack=/usr \
--with-http=/usr \
">moreops

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
--with-pspell \
--with-readline \
--enable-sockets \
--with-sodium \
--enable-soap --with-libxml \
\
--enable-posix \
--disable-debug \
--disable-phpdbg \
--disable-rpath \
--enable-calendar \
--enable-ctype \
--enable-dom \
--enable-exif \
--enable-fileinfo \
--enable-filter \
--enable-ftp \
--with-openssl --with-openssl-dir=/usr \
--enable-hash \
--enable-inotify \
--enable-phar \
--enable-session \
--enable-shmop \
--enable-sockets \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-xml \
--localstatedir=/var \
--mandir=/usr/share/man \
\
--with-external-pcre \
--with-ffi \
--with-gettext \
--with-layout=GNU \
--with-libxml \
--with-mhash \
--with-password-argon2 \
--with-pear \
--with-pic \
--with-sodium \
--with-system-tzdata \
--with-zlib-dir=/usr \
--with-zlib \
--enable-tokenizer \
--with-iconv \
\
--enable-zts --enable-rtld-now --enable-sigchild --enable-werror --with-gnu-ld \
--enable-opcache --enable-opcache-jit --enable-opcache-file --enable-huge-code-pages \
\
$(cat debops) \
$(cat moreops) \
\
2>&1 | tee dkconf.log


bads=$(cat dkconf.log | grep -iv "warning" | grep -i "mcrypt\|vips\|uuid\|gearman" | wc -l)
if [[ $bads -lt 1 ]]; then
	printf "\n\n configure failed \n\n"
	exit 0;
fi
bads=$(cat dkconf.log | grep -iv "warning" | grep -i "apcu\|imagick\|raphf\|http\|msgpack\|igbinary\|memcached\|redis" | wc -l)
if [[ $bads -lt 1 ]]; then
	printf "\n\n configure failed \n\n"
	exit 0;
fi
bads=$(cat dkconf.log | grep -iv "warning" | grep -i "redis" | wc -l)
if [[ $bads -lt 1 ]]; then
	printf "\n\n configure failed \n\n"
	exit 0;
fi
cat dkconf.log | grep -iv "warning" | grep -i --color "mcrypt\|vips\|uuid\|gearman"
cat dkconf.log | grep -iv "warning" | grep -i --color "apcu\|imagick\|raphf\|http\|msgpack\|igbinary\|memcached\|redis"
exit 0;


if [[ $(tail -n30 dkconf.log | grep "Thank you for using PHP" | wc -l) -gt 0 ]]; then
	printf "\n\n configure OK \n\n"
	printf "\n\n$doconf \n\n"
else
	printf "\n\n configure failed \n\n"
	printf "\n\n$doconf \n\n"
	exit 0;
fi



sleep 0.1
sed -i "s/\-g//g" Makefile
sed -i "s/-O2/-O3/g" Makefile
sed -i "s/noeneration-date/no-generation-date/g" Makefile

find /root/src/git-php/ -type d -name ".libs" -exec rm -rf {} \;  >/dev/null
find /root/src/git-php/ -type d -name ".libs" -exec rm -rf {} \;  >/dev/null


printf "\n\n exec make \n"
make -j6 | tee dkbuild.log
oknum=$(tail dkbuild.log | grep "Build complete" | wc -l)
if [[ $oknum -gt 0 ]]; then
	printf "\n\n make OK \n\n"
else
	printf "\n\n make failed \n\n"
	printf "\n\n$doconf \n\n"
	exit 0;
fi


sapi/cli/php -m
