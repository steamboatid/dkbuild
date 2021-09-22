#!/bin/bash

BASE="/root/src/php8/php8.0-8.0.10"
cd $BASE

make clean
./buildconf -f

> ./tails.org
./configure --help | grep -v "PKGS\|ARG\|dbg\|debug\|embed\|Werror\|FEATURE\|TYPE" | \
sed -r "s/\s+/ /g" | sed -r "s/^\s//g" | cut -d" " -f1 | grep "\-\-enable\-" >> ./tails.org

./configure --help | grep -v "EXTENSION\|PKGS\|ARG\|dbg\|debug\|embed\|Werror\|FEATURE\|TYPE\|odbc\|oci\|USER\|GRP\|config\|NAME" | \
sed -r "s/\s+/ /g" | sed -r "s/^\s//g" | cut -d" " -f1 | grep "\-\-with\-" | sed -r "s/\[\=DIR\]/\=\/usr/g" |\
sed -r "s/\[\=FILE\]//g" | sed -r "s/\=DIR//g" | sed -r "s/\[\=SOCKPATH\]//g" |\
sed -r "s/\[\=PATH\]//g" >> ./tails.org

./configure --help | grep -v "PKGS\|ARG\|dbg\|debug\|embed\|Werror\|FEATURE\|TYPE" | \
sed -r "s/\s+/ /g" | sed -r "s/^\s//g" | cut -d" " -f1 | \
grep -iv "pdo\|ipv6\|short\-tags\|all" | \
grep "\-\-disable\-" | sed -r "s/disable\-/enable\-/g" >> ./tails.org

cat ./tails.org | grep -iv "malloc\|gcov\|valgrin\|fuzzer\|setsize\|qdbm\|dba\|dbm\|db2\|pdo\|odbc\|with\-db\|sap\|tca\|lmdb\|ada" |\
grep -iv "with\-mm\|sanitize\|phpdbg\|lzf\|static\|lz\|protocol\|coverage" > ./tails.new

echo " --with-avif --with-libxml --with-fpm-systemd " >> ./tails.new
echo " --with-apxs2=/usr/bin/apxs2 " >> ./tails.new
# echo " --with-mysqlnd=/usr/bin/mysql_config " >> ./tails.new

echo \
"--enable-posix
--enable-pdo=/usr
--with-pdo-odbc=shared,unixODBC,/usr
--with-unixODBC=shared,/usr
--disable-cgi
--disable-debug
--disable-dtrace
--disable-phpdbg
--disable-rpath
--enable-calendar
--enable-ctype
--enable-dom
--enable-exif
--enable-fileinfo
--enable-filter
--enable-ftp --with-openssl-dir=/usr
--enable-hash
--enable-inotify
--enable-phar
--enable-session
--enable-shmop
--enable-sockets
--enable-static
--enable-sysvmsg
--enable-sysvsem
--enable-sysvshm
--enable-tokenizer
--enable-xml
--localstatedir=/var
--mandir=/usr/share/man
--with-external-pcre
--with-ffi
--with-gettext
--with-layout=GNU
--with-libxml
--with-mhash
--with-openssl
--with-password-argon2
--with-pear
--with-pic
--with-sodium
--with-system-tzdata
--with-zlib-dir
--with-zlib
">./heads.org


cat ./tails.new >> ./heads.org
mv ./heads.org ./tails.new

cat ./tails.new | sort -u | sort > ./tails.uniq
mv ./tails.uniq ./tails.new


doconf="./configure "
for aline in $(cat ./tails.new); do
	/bin/true
	# printf " $aline \\ \n"
	if [[ $aline == *"with-"* ]] && [[ $aline != *"usr"* ]] && [[ $aline != *"/"* ]] && \
	[[ $aline != *"shared"* ]] && \
	[[ $aline != *"mysql"* ]] && [[ $aline != *"imap"* ]]; then
		# printf "\n $aline"; exit 0;
		aline="${aline}=/usr"
	fi
	doconf="${doconf} $aline "
done

doconf=$(printf "$doconf" | sed -r "s/imap\=\/usr/imap=\/usr\/lib/g")
# doconf="LDFLAGS='-L/usr/local/lib/ -liconv' ${doconf}"


make clean
eval $doconf 2>&1 | tee dkconf.log

if [[ $(tail -n30 dkconf.log | grep "Thank you for using PHP" | wc -l) -gt 0 ]]; then
	printf "\n\n configure OK \n\n"
	printf "\n\n$doconf \n\n"
else
	printf "\n\n configure failed \n\n"
	printf "\n\n$doconf \n\n"
	exit 0;
fi


# singles=(mcrypt vips uuid gearman apc imagick raphf http msgpack igbinary memcached imap)
# for adir in "${singles[@]}"; do
# 	printf "\n=== $adir \t"
# 	printf "$doconf" | tr " " "\n" | sort | grep --color -i "$adir"
# done


if [[ $(make -j6 | tee dkbuild.log) -lt 1 ]]; then
	printf "\n\n make OK \n\n"
else
	printf "\n\n make failed \n\n"
	printf "\n\n$doconf \n\n"
	exit 0;
fi
