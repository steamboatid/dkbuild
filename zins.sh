#!/bin/bash

source ~/.bashrc

cd `mktemp -d`; apt remove php* -fy

cd /tb2/build/$RELNAME-all; \
find /tb2/build/$RELNAME-all -name "php*deb" | sort -u | \
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|smbclient\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "_all\|apcu\|bcmath\|bz2\|cli\|common\|curl\|fpm\|gd\|gmp\|http\|igbinary\|imagick\|ldap\|mbstring\|memcached\|msgpack\|mysql\|opcache\|raphf\|readline\|redis\|soap\|tidy\|xdebug\|xml\|xsl\|zip" \
> /tmp/pkg-php.txt

cat /tmp/pkg-php.txt | tr "\n" " " | xargs dpkg -i || dpkg --configure -a || \
apt install -fy --fix-broken --fix-missing --allow-downgrades --allow-change-held-packages


find /tb2/build/$RELNAME-all -name "php*deb" | sort -u | \
grep -v "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|smbclient\|ldap\|sybase\|interbase\|yac\|xcache" |\
grep "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" \
> /tmp/pkg-php2.txt

cat /tmp/pkg-php2.txt | tr "\n" " " | xargs dpkg -i || dpkg --configure -a || \
apt install -fy --fix-broken --fix-missing --allow-downgrades --allow-change-held-packages

php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
NUMEXT=$(php8.0 -m | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
if [[ $NUMEXT -lt 8 ]]; then printf "\n\n\t php ext:NOT OK\n\n"; else printf "\n\n\t php ext: OK\n\n"; fi
