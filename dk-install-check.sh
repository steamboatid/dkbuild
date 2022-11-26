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



# check PHP8.x installs
check_php_installs() {
	phpv="$1"
	eval "$phpv -m" | sort -u | grep -i --color "apcu\|http\|igbinary\|imagick\|memcached\|msgpack\|raphf\|redis\|propro"

	miss_strs=""
	miss_nums=0
	# exts=("apcu" "http" "igbinary" "imagick" "memcached" "msgpack" "raphf" "redis")
	exts=("http" "igbinary" "imagick" "memcached" "msgpack" "redis")
	for aext in "${exts[@]}"; do
		if [[ $(eval "$phpv -m" | grep -i "$aext" | wc -l) -lt 1 ]]; then
			miss_strs=" $aext \n $miss_strs"
			miss_nums=$(( $miss_nums + 1 ))
		fi
	done

	if [[ $miss_nums -lt 1 ]]; then
		printf "\n --- ${blu}${phpv} ext: OK ${end} \n"
	else
		printf "\n --- ${red}${phpv} ext:NOT OK ${end}"
		printf "\n --- missing exts: \n$miss_strs \n\n"
	fi

	# check php version
	printf "\n --- Output of ${yel}php -v${end} \n"
	eval "$phpv -v"
}
# check_php_installs "php8.0"
check_php_installs "php8.1"



# restart using rc
[ -x /etc/init.d/nutcracker ] && /etc/init.d/nutcracker restart
[ -x /etc/init.d/nginx ] && /etc/init.d/nginx restart
[ -x /etc/init.d/keydb-server ] && /etc/init.d/keydb-server restart
# [ -x /etc/init.d/php8.0-fpm ] && mkdir -p /run/php && /etc/init.d/php8.0-fpm restart
[ -x /etc/init.d/php8.1-fpm ] && mkdir -p /run/php && /etc/init.d/php8.1-fpm restart
# [ -x /etc/init.d/php8.2-fpm ] && mkdir -p /run/php && /etc/init.d/php8.2-fpm restart
# [ -x /etc/init.d/php8.3-fpm ] && mkdir -p /run/php && /etc/init.d/php8.3-fpm restart


# check netstat
printf "\n --- Output of ${yel}netstat${end} -- nginx-keydb-nutcracker-php \n"
netstat -nlpa | grep LIST | grep --color "nginx\|keydb\|nutcracker\|php"

# check netstat
printf "\n --- Output of ${yel}ps${end} -- nginx-keydb-nutcracker-php \n"
ps -e -o command | grep -iv "grep\|pool\|worker\|rsync" | sort -u | grep --color "nginx\|keydb\|nutcracker\|php"

# check php custom
check_php_custom() {
	phpv="$1"
	NUMNON=$(dpkg -l | grep "^ii" | grep $phpv | grep -iv omd | wc -l)
	NUMCUS=$(dpkg -l | grep "^ii" | grep $phpv | grep -i omd | wc -l)
	printf "\n\n--- ${cyan}$phpv packages${end}: ${yel}default=$NUMNON  ${blu}CUSTOM=$NUMCUS ${end}\n"
}

# check_php_custom "php8.0"
check_php_custom "php8.1"
