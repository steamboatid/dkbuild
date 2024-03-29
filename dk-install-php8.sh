#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

export PHPVERS=("php8.2" "php8.1")
export PHPGREP="php8.2\|php8.1"


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm




# gen config, delete locks
#-------------------------------------------
delete_apt_lock
/bin/bash /tb2/build-devomd/dk-config-gen.sh



aptnew install  -o Dpkg::Options::="--force-overwrite" \
--no-install-recommends --fix-missing --reinstall -fy \
libzip4 libdb4.8 libgeoip1 bison flex libsodium23

apt-cache search php8.1 | grep -v "dbgsym" | \
grep -i "\-zip\|\-cli\|\-fpm" | awk '{print $1}' | \
xargs aptnew install -fy


# complete install PHP8.x
complete_php_installs() {
	phpv="$1"
	vnum="$2"
	> /tmp/pkg-php0.txt

	apt-cache search db4.8 | grep -iv "cil\|tcl\|doc\|dev\|dbg\|java" | \
	cut -d" " -f1 | xargs aptold install -fy -o Dpkg::Options::="--force-overwrite"

	apt-cache search db4.8 | grep -iv "cil\|tcl\|doc\|dev\|dbg\|java" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv | grep -iv "apache\|embed" | \
	grep -iv "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache\|enchant" | \
	grep "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|common\|fpm\|cli" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv | grep -iv "apache\|embed" | \
	grep -iv "cgi\|imap\|odbc\|pgsql\|dbg\|dev\|ldap\|sybase\|interbase\|yac\|xcache\|enchant" | \
	grep "bcmath\|bz2\|gmp\|mbstring\|mysql\|opcache\|readline\|xdebug\|zip" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	apt-cache search $phpv |\
	grep -iv "apache\|debug\|dbg\|cgi\|embed\|gmagick\|yac\|-dev\|enchant" | \
	cut -d" " -f1  >> /tmp/pkg-php0.txt

	cat /tmp/pkg-php0.txt | sort -u | sort | tr "\n" " " > /tmp/pkg-php1.txt

	cat /tmp/pkg-php1.txt | xargs aptnew install -fy \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"

	# fix arginfo on uploadprogress
	if [ -e /etc/php/$vnum/mods-available/uploadprogress.ini ]; then
		sed -i "s/^extension/\; extension/g" /etc/php/$vnum/mods-available/uploadprogress.ini
		aptnew install -fy
	fi

	printf "\n\n --- packages list: \n"
	cat /tmp/pkg-php0.txt
}

# complete_php_installs "php8.0" "8.0"
complete_php_installs "php8.1" "8.1"




# check PHP8.x installs
check_php_installs() {
	phpv="$1"
	eval "$phpv -m" | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis"
	NUMEXT=$(eval "$phpv -m" | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis" | wc -l)
	if [[ $NUMEXT -lt 8 ]]; then
		printf "\n --- ${red}${phpv} ext:NOT OK ${end}\n"
	else
		printf "\n --- ${blu}${phpv} ext: OK ${end}\n"
	fi

	# check php version
	printf "\n --- Output of ${yel}php -v${end} \n"
	eval "$phpv -v"
}
# check_php_installs "php8.0"
check_php_installs "php8.1"



# restart using rc
# [ -x /etc/init.d/php8.0-fpm ] && mkdir -p /run/php && /etc/init.d/php8.0-fpm restart
[ -x /etc/init.d/php8.1-fpm ] && mkdir -p /run/php && /etc/init.d/php8.1-fpm restart
# [ -x /etc/init.d/php8.2-fpm ] && mkdir -p /run/php && /etc/init.d/php8.2-fpm restart
# [ -x /etc/init.d/php8.3-fpm ] && mkdir -p /run/php && /etc/init.d/php8.3-fpm restart


# check php custom
check_php_custom() {
	phpv="$1"
	NUMNON=$(dpkg -l | grep "^ii" | grep $phpv | grep -v omd | wc -l)
	NUMCUS=$(dpkg -l | grep "^ii" | grep $phpv | grep omd | wc -l)
	printf "\n\n--- ${cyan}$phpv packages${end}: ${yel}default=$NUMNON  ${blu}CUSTOM=$NUMCUS ${end}\n"
}

# check_php_custom "php8.0"
check_php_custom "php8.1"
