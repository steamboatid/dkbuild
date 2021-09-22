#!/bin/bash

BASE="/root/src/php8/php8.0-8.0.10"
cd $BASE

rm -rf ext/odbc* ext/pdo* ext/dba*

make clean
dh clean
fakeroot debian/rules clean
find . -name ".libs" -exec rm -rf {} \;

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
rm -rf ./tails.org

echo " --with-avif --with-libxml --with-fpm-systemd " >> ./tails.new
echo " --with-apxs2=/usr/bin/apxs2 " >> ./tails.new
# echo " --with-mysqlnd=/usr/bin/mysql_config " >> ./tails.new

echo \
"--enable-posix=shared
--enable-pdo=/usr
--with-pdo-odbc=shared,unixODBC,/usr
--with-unixODBC=shared,/usr
--disable-debug
--disable-phpdbg
--disable-rpath
--enable-calendar=shared,/usr
--enable-ctype=shared,/usr
--enable-dom
--enable-exif=shared,/usr
--enable-fileinfo=shared,/usr
--enable-filter=shared,/usr
--enable-ftp=shared,/usr
--with-openssl=shared,/usr --with-openssl-dir=/usr
--enable-hash=shared,/usr
--enable-inotify=shared,/usr
--enable-phar=shared,/usr
--enable-session=shared,/usr
--enable-shmop=shared,/usr
--enable-sockets=shared,/usr
--enable-sysvmsg=shared,/usr
--enable-sysvsem=shared,/usr
--enable-sysvshm=shared,/usr
--enable-tokenizer=shared,/usr
--enable-xml=shared,/usr
--localstatedir=/var
--mandir=/usr/share/man
--with-external-pcre
--with-ffi=shared,/usr
--with-gettext=shared,/usr
--with-layout=GNU
--with-libxml=shared,/usr
--with-mhash=shared,/usr
--with-password-argon2=shared,/usr
--with-pear=shared,/usr
--with-pic=shared,/usr
--with-sodium=shared,/usr
--with-system-tzdata=shared,/usr
--with-zlib-dir=/usr
--with-zlib=shared,/usr
">./heads.org


cat ./tails.new >> ./heads.org
mv ./heads.org ./tails.new

cat ./tails.new | sort -u | sort > ./tails.uniq
mv ./tails.uniq ./tails.new

cat ./tails.new | grep -iv "rpath\|static\|cgi\|odbc\|pdo\|dba\|db4\|db3\|db2\|db1" > ./tails.tmp
mv ./tails.tmp ./tails.new
# exit 0;


doconf="./configure "
for aline in $(cat ./tails.new); do
	/bin/true
	# printf " $aline \\ \n"
	if [[ $aline == *"with-"* ]] && [[ $aline != *"usr"* ]] && [[ $aline != *"/"* ]] && \
	[[ $aline != *"shared"* ]] && \
	[[ $aline != *"mysql"* ]] && [[ $aline != *"imap"* ]]; then
		# printf "\n $aline"; exit 0;
		aline="${aline}=shared,/usr"
	fi
	doconf="${doconf} $aline "
done

doconf=$(printf "$doconf" | sed -r "s/imap\=\/usr/imap=\/usr\/lib/g")
# doconf="LDFLAGS='-L/usr/local/lib/ -liconv' ${doconf}"

doconf=$(printf "$doconf" | tr " " "\n" | grep -v "magick\|msgpack\|igbinary\|redis\|memcached\|raph\|http" | \
sed '/^$/d' | tr "\n" " ")
# printf "$doconf \n\n"; exit 0;

doconf=$(printf "$doconf" | tr " " "\n" | sed '/^$/d' | head -n 300 | tr "\n" " ")
# printf "$doconf \n\n"; exit 0;


make clean
dh clean
fakeroot debian/rules clean
find . -name ".libs" -exec rm -rf {} \;

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

sed -i "s/\-g//g" Makefile
sed -i "s/-O2/-O3/g" Makefile

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
