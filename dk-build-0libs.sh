#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


# bash colors
export red=$'\e[1;31m'
export grn=$'\e[1;32m'
export green=$'\e[1;32m'
export yel=$'\e[1;33m'
export blu=$'\e[1;34m'
export blue=$'\e[1;34m'
export mag=$'\e[1;35m'
export magenta=$'\e[1;35m'
export cyn=$'\e[1;36m'
export cyan=$'\e[1;36m'
export end=$'\e[0m'



# aptold create and check (version3)
#-------------------------------------------
create_aptold() {
	echo \
'#!/bin/bash
# version3

save_local_debs() {
	mkdir -p /tb2/tmp/cachedebs/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/
}

str="$*"
exs=0
if [[ $str == *"du "* ]]; then exs=1; fi
if [[ $str == *"fydu"* ]]; then exs=1; fi
if [[ $str == *"yfdu"* ]]; then exs=1; fi
if [[ $str == *"dufy"* ]]; then exs=1; fi
if [[ $str == *"duyf"* ]]; then exs=1; fi
# printf "\n $str \n$exs \n"

if [[ $exs -lt 1 ]]; then
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" -du
	save_local_debs
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
else
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
	save_local_debs
fi
'>/usr/local/sbin/aptold
}

if [ ! -e /usr/local/sbin/aptold ]; then
	create_aptold
elif [[ $(grep "version3" /usr/local/sbin/aptold | wc -l) -lt 1 ]]; then
	create_aptold
fi
chmod +x /usr/local/sbin/aptold



# aptnew create and check (version3)
#-------------------------------------------
create_aptnew() {
	echo \
'#!/bin/bash
# version3

save_local_debs() {
	mkdir -p /tb2/tmp/cachedebs/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/
}

str="$*"
exs=0
if [[ $str == *"du "* ]]; then exs=1; fi
if [[ $str == *"fydu"* ]]; then exs=1; fi
if [[ $str == *"yfdu"* ]]; then exs=1; fi
if [[ $str == *"dufy"* ]]; then exs=1; fi
if [[ $str == *"duyf"* ]]; then exs=1; fi
# printf "\n $str \n$exs \n"

if [[ $exs -lt 1 ]]; then
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@" -du
	save_local_debs
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
else
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
	save_local_debs
fi
'>/usr/local/sbin/aptnew
}

if [ ! -e /usr/local/sbin/aptnew ]; then
	create_aptnew
elif [[ $(grep "version3" /usr/local/sbin/aptnew | wc -l) -lt 1 ]]; then
	create_aptnew
fi
chmod +x /usr/local/sbin/aptnew




# reset default build flags
#-------------------------------------------
reset_build_flags() {
	echo \
"STRIP CFLAGS -O2 -g -pedantic
STRIP CPPFLAGS -O2 -g -pedantic
STRIP CXXFLAGS -O2 -g -pedantic
STRIP LDFLAGS -O2 -g -pedantic

PREPEND CFLAGS -O3
PREPEND CPPFLAGS -O3
PREPEND CXXFLAGS -O3
PREPEND LDFLAGS -Wl,-s
">/etc/dpkg/buildflags.conf
}

prepare_build_flags() {
	AAA=`dpkg-buildflags --get CFLAGS`
	GO2="-g -O2"
	OPT3="-O3"
	AAA="${AAA/$GO2/$OPT3}"
	GO2="-O2"
	OPT3="-O3"
	CFLAGS="${AAA/$GO2/$OPT3}"
	export CFLAGS
	export EXTRA_CFLAGS=$CFLAGS
	export DEB_CFLAGS_SET=$CFLAGS

	LD=gcc
	LDFLAGS="-Wl,-s ${CFLAGS} ${LDFLAGS}"
	export LDFLAGS
	export EXTRA_LDFLAGS=$LDFLAGS
	export DEB_LDFLAGS_SET=$LDFLAGS

	AR=gcc-ar
	RANLIB=gcc-ranlib
	echo $CFLAGS
	echo $LDFLAGS

	dpkg-buildflags --get CFLAGS
	dpkg-buildflags --get LDFLAGS

	export DEB_CFLAGS_STRIP="-g -O2"
	export DEB_LDFLAGS_STRIP="-g -O2"


	alias cd="cd -P"
	export CCACHE_SLOPPINESS=include_file_mtime
	export CC="/usr/bin/ccache /usr/bin/gcc"

	mkdir -p /tb2/tmp/ccache /root/.ccache
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	/root/.ccache/ /tb2/tmp/ccache/
	export CCACHE_BASEDIR="/tb2/tmp/ccache"
}


# exec bash script at back
#-------------------------------------------
doback_bash(){
	/usr/bin/nohup /bin/bash $1 >/dev/null 2>&1 &
	printf "\n\n exec back: $1 \n\n\n"
	sleep 1
}


# check if any fails
#-------------------------------------------
check_build_log() {
	printf "\n\n---check dkbuild.log \n"
	export TOTFAIL=0
	for alog in $(find /root/src -maxdepth 3 -type f -iname "dkbuild.log" | sort -u); do
		printf " --- $alog ---\n"
		NUMFAIL=$(tail -n100 ${alog} | tr -d '\000' | grep -a "buildpackage" | grep -a "failed" | wc -l)
		NUMSUCC=$(tail -n100 ${alog} | tr -d '\000' | grep -a "buildpackage" | grep -a "binary-only upload" | wc -l)
		if [[ $NUMSUCC -lt 1 ]] && [[ $NUMFAIL -gt 0 ]]; then
			TOTFAIL=$((TOTFAIL + NUMFAIL))
			printf "\n\n check $alog --- FAILS = $NUMFAIL TOTAL = $TOTFAIL \n"
			tail -n100 ${alog} | tr -d '\000' | grep -a "buildpackage" | grep -a "failed"
			printf "\n"
		fi
	done
	sleep 0.1

	if [[ ${TOTFAIL} -gt 0 ]]; then
		printf "\n\n\n\t TOTAL FAILS = $TOTFAIL\n\n"
		exit $TOTFAIL; # exit as error
	fi
	printf "\n\n"
}


chown_apt() {
	chown -Rf _apt:root /var/cache/apt/archives/partial/
	chmod -f 700 /var/cache/apt/archives/partial/
}

update_existing_git() {
	DST=$1
	URL=$2

	cd $DST
	printf "\n---updating $PWD \n"
	git reset --hard
	git config  --global pull.ff only
	git rm -r --cached . >/dev/null 2>&1
	git submodule update --init --recursive -f
	git fetch --all

	git pull --update-shallow --ff-only
	git pull --depth=1 --ff-only
	git pull --ff-only

	if git pull origin $(git rev-parse --abbrev-ref HEAD) --ff-only; then
		printf " --- pull OK \n"
	else
		if git pull origin $(git rev-parse --abbrev-ref HEAD) --allow-unrelated-histories; then
			printf " --- pull OK:  allow-unrelated-histories \n"
		else
			if ! git pull origin $(git rev-parse --abbrev-ref HEAD) --rebase; then
				cd ..
				rm -rf $1
				printf "\n\n ${red}git update at $1 is failed. please re-execute $0 again ${end}"
				printf "\n Recloning: ${blu} https://github.com/${URL} ${end} \n\n"
				# exit 1; # exit as error

				# recloning
				git clone https://github.com/${URL} $DST
			fi
		fi
	fi
	cd ..
	printf "\n\n"
}

get_update_new_git(){
	URL=$1
	DST=$2

	if [ ! -d ${DST} ]; then
		printf "\n---new clone to: $DST \n---from: https://github.com/${URL} \n"
		git clone https://github.com/${URL} $DST
	else
		update_existing_git $DST $URL
	fi
}

fix_keydb_permission_problem() {
	# return if not installed yet
	if [ `dpkg -l | grep keydb | grep -v "^ii" | wc -l` -lt 1 ]; then return 0; fi

	killall -9 keydb-server 2>&1 >/dev/null
	>/var/log/keydb/keydb-sentinel.log
	>/var/log/keydb/keydb-server.log

	cd `mktemp -d`; \
	systemctl stop redis-server; systemctl disable redis-server; systemctl mask redis-server; \
	systemctl daemon-reload; apt remove -y redis-server
	mkdir -p /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
	chown keydb.keydb -Rf /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb; \
	find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type d -exec chmod 775 {} \; ; \
	find /var/lib/keydb /var/log/keydb /var/run/keydb /run/keydb -type f -exec chmod 664 {} \;

	# force modify config file
	if [ -e /etc/keydb/keydb.conf ]; then
		sed -i "s/^bind 127.0.0.1 \:\:1/\#-- bind 127.0.0.1 \:\:1\nbind 127.0.0.1/g" /etc/keydb/keydb.conf
		sed -i "s/^logfile \/var/#-- logfile \/var/g" /etc/keydb/keydb.conf
		sed -i "s/^dbfilename /#-- dbfilename /g" /etc/keydb/keydb.conf
		sed -i "s/^save 900 /#-- save 900 /g" /etc/keydb/keydb.conf
		sed -i "s/^save 300 /#-- save 300 /g" /etc/keydb/keydb.conf
		sed -i "s/^save 60 /#-- save 60 /g" /etc/keydb/keydb.conf
	fi

	# force modify config file
	if [ -e /etc/keydb/sentinel.conf ]; then
		sed -i "s/^logfile \/var/#-- logfile \/var/g" /etc/keydb/sentinel.conf
		sed -i "s/^dir \/var/#-- dir \/var/g" /etc/keydb/sentinel.conf
	fi
}

purge_pending_installs() {
	dpkg -l | grep -v "^ii" | grep "^i" | sed -r "s/\s+/ /g" | cut -d" " -f2 > /tmp/pendings

	# install it all
	cat /tmp/pendings | tr "\n" " "| xargs apt purge -fy
	cat /tmp/pendings | while read aline; do apt purge -fy $aline; done
}

install_old() {
	pkgs=$1
	dopkg=""
	for apkg in "${pkgs[@]}"; do
		exists=$(dpkg -l | grep "^ii" | grep "${apkg}" | wc -l)
		if [[ $exists -lt 1 ]]; then
			dopkg="${dopkg} ${apkg}"
		fi
	done
	aptold install -fy $dopkg 2>&1
}

install_new() {
	pkgs=$1
	dopkg=""
	for apkg in "${pkgs[@]}"; do
		exists=$(dpkg -l | grep "^ii" | grep "${apkg}" | wc -l)
		if [[ $exists -lt 1 ]]; then
			dopkg="${dopkg} ${apkg}"
		fi
	done
	aptnew install -fy $dopkg 2>&1
}


save_local_debs() {
	mkdir -p /tb2/tmp/cachedebs/
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/
}

