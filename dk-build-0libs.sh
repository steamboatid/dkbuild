#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"
export DPKG_COLORS="always"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

# java libs
export JAVA_HOME=/usr/lib/jvm/default-java/
export JAVA_INCLUDE_DIR=/usr/lib/jvm/default-java/include


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


source ~/.bashrc





wait_jobs(){
	numo=0
	numz=0
	while :; do
		# jobs -r
		numa=$(jobs -r | wc -l)
		if [[ $numz -gt 3 ]]; then
			break
		elif [[ $numa -lt 1 ]]; then
			numz=$(( $numz + 1 ))
			printf "."
		elif [[ $numa -ne $numo ]]; then
			numo=$numa
			printf " $numa"
		else
			printf "."
		fi

		sleep 3
	done

	# wait
	wait
}

wait_backs_wpatt(){
	patt="$1"

	bname=$(basename $0)
	printf "\n\n --- wait for all background process...  [$bname] [$patt] "

	numo=0
	numz=0
	while :; do
		numa=$(jobs -r | grep -iv "find\|chmod\|chown" | grep "${patt}" | wc -l)
		if [[ $numz -gt 3 ]]; then
			break
		elif [[ $numa -lt 1 ]]; then
			numz=$(( $numz + 1 ))
			printf "."
		elif [[ $numa -ne $numo ]]; then
			numo=$numa
			printf " $numa"
		else
			printf "."
		fi

		sleep 3
	done

	wait
	printf "\n --- ${blue}wait finished...${end} \n\n\n"
}

wait_backs_nopatt(){
	patt="$1"

	bname=$(basename $0)
	printf "\n\n --- wait for all background process...  [$bname] [$patt] "

	numo=0
	numz=0
	while :; do
		numa=$(jobs -r | grep -iv "find\|chmod\|chown" | wc -l)
		if [[ $numz -gt 3 ]]; then
			break
		elif [[ $numa -lt 1 ]]; then
			numz=$(( $numz + 1 ))
			printf "."
		elif [[ $numa -ne $numo ]]; then
			numo=$numa
			printf " $numa"
		else
			printf "."
		fi

		sleep 3
	done

	wait
	printf "\n --- ${blue}wait finished...${end} \n\n\n"
}

fill_up_apt_cache(){
	printf "\n --- fill_up_apt_cache "

	mkdir -p /var/cache/apt/archives/partial/
	chown -Rf _apt:root /var/cache/apt/archives/
	chmod -Rf 700 /var/cache/apt/archives/partial/

	procs=$(( $(nproc)*8 ))
	nums=0
	for afile in $(find -L /tb2/tmp/cachedebs -type f -iname "*.deb" -mtime -1 | head -n 100); do
		while :; do
			nums=$(ps auxw | grep -v grep | grep rsync | grep deb | wc -l)
			if [[ $nums -lt $procs ]]; then break; fi
			sleep 3
			printf ".$nums"
		done

		rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
		"$afile" /var/cache/apt/archives/ >/dev/null 2>&1 &
	done

	wait_backs_wpatt "rsync"
	chown -Rf _apt:root /var/cache/apt/archives/
	chmod -Rf 700 /var/cache/apt/archives/partial/
}

save_clean_apt_cache(){
	printf "\n --- save & clean_apt_cache \n"
	save_local_debs

	apt autoclean >/dev/null 2>&1
	apt clean >/dev/null 2>&1
}



install_aptfast(){
cat << EOT >/etc/apt/sources.list.d/apt-fast.list
deb http://ppa.launchpad.net/apt-fast/stable/ubuntu bionic main
EOT
	apt-key adv --keyserver keyserver.ubuntu.com \
	--recv-keys A2166B8DE8BDC3367D1901C11EE2FF37CA8DA16B \
		2>&1 | grep --color "processed"

	apt update \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	DEBIAN_FRONTEND=noninteractive apt install -fy apt-fast \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	echo debconf apt-fast/maxdownloads string 16 | debconf-set-selections
	echo debconf apt-fast/dlflag boolean true | debconf-set-selections
	echo debconf apt-fast/aptmanager string apt-get | debconf-set-selections
}


# aptold create and check (version17)
#-------------------------------------------
create_aptold(){
	echo \
'#!/bin/bash
# version17

save_local_debs(){
	mkdir -p /tb2/tmp/cachedebs/
	if [ -e /var/cache/apt/archives ]; then
		find -L /var/cache/apt/archives/ -type f -iname "*.deb" -exec touch {} \;  \
			>/dev/null 2>&1 &

		DNUMS=$(find -L /var/cache/apt/archives/ -type f -iname "*.deb" | wc -l)
		if [[ $DNUMS -gt 0 ]]; then
			rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
			/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/ \
			>/dev/null 2>&1 &
		fi
	fi

	find /tb2/tmp/cachedebs -type f -mtime +1 -delete >/dev/null 2>&1 &
}

chown -Rf _apt:root /var/cache/apt/archives/partial/
chmod -Rf 700 /var/cache/apt/archives/partial/

str="$*"
exs=0
if [[ $str == *"du "* ]]; then exs=1; fi
if [[ $str == *"fydu"* ]]; then exs=1; fi
if [[ $str == *"yfdu"* ]]; then exs=1; fi
if [[ $str == *"dufy"* ]]; then exs=1; fi
if [[ $str == *"duyf"* ]]; then exs=1; fi
# printf "\n $str \n$exs \n"

if [[ $exs -lt 1 ]]; then
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" -du \
		2>&1 | grep -iv "stable cli"
fi

save_local_debs &
apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" \
	2>&1 | grep -iv "stable cli"

'>/usr/local/sbin/aptold
}



# aptnew create and check (version17)
#-------------------------------------------
create_aptnew(){
	echo \
'#!/bin/bash
# version17

save_local_debs(){
	mkdir -p /tb2/tmp/cachedebs/
	if [ -e /var/cache/apt/archives ]; then
		find -L /var/cache/apt/archives/ -type f -iname "*.deb" -exec touch {} \; \
		>/dev/null 2>&1 &

		DNUMS=$(find -L /var/cache/apt/archives/ -type f -iname "*.deb" | wc -l)
		if [[ $DNUMS -gt 0 ]]; then
			rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
			/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/ \
			>/dev/null 2>&1 &
		fi
	fi

	find /tb2/tmp/cachedebs -type f -mtime +1 -delete >/dev/null 2>&1 &
}

chown -Rf _apt:root /var/cache/apt/archives/partial/
chmod -Rf 700 /var/cache/apt/archives/partial/

str="$*"
exs=0
if [[ $str == *"du "* ]]; then exs=1; fi
if [[ $str == *"fydu"* ]]; then exs=1; fi
if [[ $str == *"yfdu"* ]]; then exs=1; fi
if [[ $str == *"dufy"* ]]; then exs=1; fi
if [[ $str == *"duyf"* ]]; then exs=1; fi
# printf "\n $str \n$exs \n"

if [[ $exs -lt 1 ]]; then
	apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@" -du \
		2>&1 | grep -iv "stable cli"
fi

save_local_debs &
apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@" \
	2>&1 | grep -iv "stable cli"

'>/usr/local/sbin/aptnew
}




# reset default build flags
#-------------------------------------------
reset_build_flags(){
	unused="-Wno-error -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-unused-const-variable"
	# libsld="-ldl -lstdc++ -lm -lresolv -lpthread"
	# libsld="-largon2 -lresolv -lcrypt -lrt -lstdc++ -lutil -lrt -lm -ldl  -lxml2 -lgssapi_krb5 -lkrb5 -lk5crypto -lcom_err -lssl -lcrypto -lpcre2-8 -lz -lsodium -largon2"

	echo \
"
STRIP CFLAGS   -O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic
STRIP CPPFLAGS -O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic
STRIP CXXFLAGS -O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic
STRIP LDFLAGS  -O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic

PREPEND CFLAGS   -O3 ${libsld} ${unused}
PREPEND CPPFLAGS -O3 -lstdc++
PREPEND CXXFLAGS -O3 ${libsld}
">/etc/dpkg/buildflags.conf

	# cat /etc/dpkg/buildflags.conf; exit 0;

# PREPEND LDFLAGS  -Wl,-lm -Wl,-ldl -Wl,-lstdc++ -Wl,-lresolv
# PREPEND LDFLAGS -ldl -lstdc++ -lm -lresolv
# PREPEND LDFLAGS -Wl,-lm -Wl,-ldl -Wl,-lstdc++ -Wl,-lpthread
}

prepare_build_flags(){
	unused="-Wno-error -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-unused-const-variable"
	# libsld="-ldl -lstdc++ -lm -lresolv"
	# libsld="-largon2 -lresolv -lcrypt -lrt -lstdc++ -lutil -lrt -lm -ldl  -lxml2 -lgssapi_krb5 -lkrb5 -lk5crypto -lcom_err -lssl -lcrypto -lpcre2-8 -lz -lsodium -largon2"

	CFLAGS=$(dpkg-buildflags --get CFLAGS)
	printf " ${CFLAGS} ${libsld} ${unused} " | \
	sed -r "s/ \-pedantic-\errors//g" | sed -r "s/ \-Wpedantic//g" | sed -r "s/ \-pedantic//g" |\
	sed -r "s/ \-Wextra / /g" | sed -r "s/ \-Wall / /g" | sed -r "s/ \-Werror / /g" | \
	sed -r "s/\s+/ /g" | sed -r "s/^\s//g" > /tmp/flags
	CFLAGS=$(cat /tmp/flags)
	rm -rf /tmp/flags.new /tmp/flags
	# printf "\n${CFLAGS}"; exit 0;

	export CFLAGS
	export EXTRA_CFLAGS=$CFLAGS
	export DEB_CFLAGS_SET=$CFLAGS

	LD=gcc
	# LDFLAGS="-Wl,-lm -Wl,-ldl -Wl,-lstdc++ -Wl,-lpthread ${CFLAGS} ${LDFLAGS}"
	LDFLAGS="${CFLAGS} ${LDFLAGS}"
	export LDFLAGS
	# export LIBS=$LDFLAGS
	# export LDLIBS=$LDFLAGS
	# export LIBFLAGS=$LDFLAGS
	export EXTRA_LDFLAGS=$LDFLAGS
	export DEB_LDFLAGS_SET=$LDFLAGS

	AR=gcc-ar
	RANLIB=gcc-ranlib

	export DEB_CFLAGS_STRIP="-O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic"
	export DEB_LDFLAGS_STRIP="-O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic"
	export DEB_CXXFLAGS_STRIP="-O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic"
	export DEB_CPPFLAGS_STRIP="-O2 -pedantic -Wall -Werror -Wextra -Wpedantic -pedantic-errors -pedantic"

	export DEB_DH_SHLIBDEPS_ARGS_ALL="--warnings=0 --dpkg-shlibdeps-params=--ignore-missing-info --warnings=0"


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
	app="$1"
	printf "\n\n exec back: "$app" \n"
	/usr/bin/nohup /bin/bash "$app" >/dev/null 2>&1 &
	sleep 1
}


# check if any fails
#-------------------------------------------
check_build_log(){
	printf "\n\n---check dkbuild.log \n"
	export TOTFAIL=0
	export TOTLOG=0
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
		TOTLOG=$(( $TOTLOG + 1 ))
	done
	sleep 0.1

	if [[ ${TOTFAIL} -gt 0 ]]; then
		printf "\n\n\n\t TOTAL FAILS = $TOTFAIL\n\n"
		exit $TOTFAIL; # exit as error
	fi
	printf "\n\n TOTAL LOGS = ${yel}$TOTLOG ${end} \n"

	PHPLOGS=$(find /root/src/php -maxdepth 2 -iname "dkbuild.log" | wc -l)
	PHPDIRS=0
	for adir in $(find /root/src/php -mindepth 1 -maxdepth 1 -type d | sort -n); do
		if [[ $(find $adir -maxdepth 1 -type f -iname "dkbuild.log" | wc -l) -lt 1 ]]; then
			printf "\n --- no dkbuild.log: $adir "
		fi
		PHPDIRS=$(( $PHPDIRS + 1 ))
	done
	printf "\n\n PHP LOGS = ${yel}$PHPLOGS${end} --  PHP DIRS = ${yel}$PHPDIRS${end} \n"

	printf "\n\n"
}


chown_apt(){
	mkdir -p /var/cache/apt/archives/partial/
	chown -Rf _apt:root /var/cache/apt/
	chmod -Rf 700 /var/cache/apt/archives/partial/ /var/cache/apt/archives/ \
		/var/cache/apt/
}

global_git_config(){
	mkdir -p ~/.git
	rm -rf ~/.gitconfig.lock
	git config  --global pull.ff only  >/dev/null 2>&1
}

update_existing_git(){
	URL="$2"
	DST="$1"
	FURL="$3"
	BRA="$4"

	PDIR=$PWD
	mkdir -p "$DST"
	cd "$DST"
	printf "\n ---updating $DST \n"

	if git reset --hard  >/dev/null 2>&1; then
		git rm -r --cached . >/dev/null 2>&1
		git submodule update --init --recursive -f  >/dev/null 2>&1
		git fetch --all  >/dev/null 2>&1

		git pull --update-shallow --ff-only  >/dev/null 2>&1
		git pull --depth=1 --ff-only  >/dev/null 2>&1
		git pull --ff-only  >/dev/null 2>&1
	fi

	if git pull origin $(git rev-parse --abbrev-ref HEAD) --ff-only; then
		printf " --- pull OK \n"
	else
		if git pull origin $(git rev-parse --abbrev-ref HEAD) --allow-unrelated-histories; then
			printf " --- pull OK:  allow-unrelated-histories \n"
		else
			if ! git pull origin $(git rev-parse --abbrev-ref HEAD) --rebase; then
				cd ..
				rm -rf "$DST"
				printf "\n\n ${red} >>> git update at $1 is failed. please re-execute $0 again ${end} \n"
				# exit 1; # exit as error

				# recloning
				[ ! -z $BRA ] && OPS="-b $BRA" || OPS=""
				ORIGIN=$(git config --get remote.origin.url)
				printf "\n ORIGIN: $ORIGIN \n FURL:   $FURL \n DST:    $DST \n BRANCH: $BRA "

				if [ ! -z $FURL ]; then
					printf "\n Recloning: ${blu} ${FURL} ${OPS} ${end} \n\n"
					git clone "$FURL" "$OPS" "$DST"
				elif [ ! -z $ORIGIN ]; then
					ADOM=$(echo ${ORIGIN} | awk -F[/:] '{print $4}')
					printf "\n Recloning: ${blu} https://${ADOM}/${URL} ${OPS} ${end} \n\n"
					git clone "https://${ADOM}/${URL}" $OPS "$DST"
				else
					#--- failed
					printf "\n\n\n\n"
					exit 1;
				fi
			fi
		fi
	fi
	cd $PDIR
	printf "\n\n"
}

# get_update_new_github $url $dst_dir $branch
# BRA= branch, DST= destination folder, URL= source url
get_update_new_github(){
	URL="$1"
	DST="$2"
	BRA="$3"

	if [ ! -d ${DST} ]; then
		[ ! -z $BRA ] && OPS="-b $BRA" || OPS=""
		printf "\n ---new clone to: $DST \n---from: https://github.com/${URL} $OPS $DST "
		printf "\n ---# git clone https://github.com/${URL} $OPS $DST ---\n"
		git clone "https://github.com/${URL}" $OPS "$DST"
	else
		FURL="https://github.com/${URL}"
		update_existing_git "$DST" "$URL" "$FURL" "$BRA"
	fi
}

# BRA= branch, DST= destination folder, URL= source url
get_update_new_gitlab(){
	URL="$1"
	DST="$2"
	BRA="$3"

	if [ ! -d ${DST} ]; then
		[ ! -z $BRA ] && OPS="-b $BRA" || OPS=""
		printf "\n ---new clone to: $DST \n---from: https://gitlab.com/${URL} $OPS $DST "
		printf "\n ---# git clone https://gitlab.com/${URL} $OPS $DST ---\n"
		git clone "https://gitlab.com/${URL}" $OPS "$DST"
	else
		FURL="https://gitlab.com/${URL}"
		update_existing_git "$DST" "$URL" "$FURL" "$BRA"
	fi
}

# BRA= branch, DST= destination folder, URL= source url
get_update_new_bitbucket(){
	URL="$1"
	DST="$2"
	BRA="$3"

	if [ ! -d ${DST} ]; then
		[ ! -z $BRA ] && OPS="-b $BRA" || OPS=""
		printf "\n ---new clone to: $DST \n---from: https://bitbucket.org/${URL} $OPS $DST "
		printf "\n ---# git clone https://bitbucket.org/${URL} $OPS $DST ---\n"
		git clone "https://bitbucket.org/${URL}" $OPS "$DST"
	else
		FURL="https://bitbucket.org/${URL}"
		update_existing_git "$DST" "$URL" "$FURL" "$BRA"
	fi
}

# BRA= branch, DST= destination folder, URL= source url
get_update_new_salsa(){
	URL="$1"
	DST="$2"
	BRA="$3"

	if [ ! -d ${DST} ]; then
		[ ! -z $BRA ] && OPS="-b $BRA" || OPS=""
		printf "\n ---new clone to: $DST \n---from: https://salsa.debian.org/${URL} $OPS $DST "
		printf "\n ---# git clone https://salsa.debian.org/${URL} $OPS $DST ---\n"
		git clone "https://salsa.debian.org/${URL}" $OPS "$DST"
	else
		FURL="https://salsa.debian.org/${URL}"
		update_existing_git "$DST" "$URL" "$FURL" "$BRA"
	fi
}

fix_keydb_permission_problem(){
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

delete_apt_lock(){
	find /var/lib/apt/lists/ -type f -delete; \
	find /var/cache/apt/ -type f -delete; \
	rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
	/etc/apt/preferences.d/00-revert-stable \
	/var/cache/debconf/ /var/lib/apt/lists/* \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
	mkdir -p /root/.local/share/nano/ /root/.config/procps/
}

purge_pending_installs(){
	dpkg -l | grep -v "^ii" | grep "^i" | sed -r "s/\s+/ /g" | cut -d" " -f2 > /tmp/pendings

	# install it all
	cat /tmp/pendings | tr "\n" " "| xargs apt purge -fy
	for apkg in $(cat /tmp/pendings); do apt purge -fy $apkg; done
}

# pkgs = array
install_old(){
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

# pkgs = array
install_new(){
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


save_local_debs(){
	mkdir -p /tb2/tmp/cachedebs/
	if [ -e /var/cache/apt/archives ]; then
		find -L /var/cache/apt/archives/ -type f -iname "*.deb" -exec touch {} \; \
		>/dev/null 2>&1 &

		DNUMS=$(find -L /var/cache/apt/archives/ -type f -iname "*.deb" | wc -l)
		if [[ $DNUMS -gt 0 ]]; then
			rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
			/var/cache/apt/archives/*deb /tb2/tmp/cachedebs/ \
			>/dev/null 2>&1 &
		fi
	fi
}


alter_berkeley_dbh(){
	if [ ! -e /usr/include ]; then
		apt-cache search db5 | grep -i "berkeley" | cut -d" " -f1 | grep -v "dbg\|sym" | xargs aptold install -fy
	fi

	cp /usr/include/db.h /usr/include/db.h.bak
	cp -f /usr/include/db.h /tmp/db.h
	sed -i -r "s/\s+/ /g" /tmp/db.h
	sed -i -r "s/5.3/4.8/g" /tmp/db.h
	sed -i -r "s/^\#define DB_VERSION_MAJOR [0-9]/#define DB_VERSION_MAJOR 4/g" /tmp/db.h
	sed -i -r "s/^\#define DB_VERSION_MINOR [0-9]/#define DB_VERSION_MINOR 8/g" /tmp/db.h
	mv /tmp/db.h /usr/include/db.h

	# cat /usr/include/db.h | grep "DB_VERSION"; exit 0;
	# cat /tmp/db.h | grep "DB_VERSION"; exit 0;
}

fetch_url(){
	URL="$1"
	BNAME=$(basename "$URL")
	curl -sS -fkL "$URL" > "$BNAME"
	wget -kc "$URL"
}

fix_usr_lib_symlinks(){
	PREV=$PWD
	cd /usr/lib

	NUMS=$(find /usr/lib/x86_64-linux-gnu -maxdepth 1 -type f -iname "*.so" | wc -l)
	printf "\n\n --- /usr/lib/x86_64-linux-gnu/*.so lib files= $NUMS \n"

	for afile in $(find /usr/lib/x86_64-linux-gnu -maxdepth 1 -type f -iname "*.so"); do
		printf "."
		BFILE=$(basename $afile)
		FINUM=$(find /usr/lib -iname "${BFILE}" | wc -l)
		if [[ $FINUM -lt 1 ]]; then
			printf "\n $afile"
			ln -s $afile .
		fi
	done
	printf "\n\n"

	cd $PREV
}

db4_install(){
	DB4NUM=$(dpkg -l | grep libdb4.8 | grep "^ii" | wc -l)
	if [[ $DB4NUM -lt 1 ]]; then
		apt purge -fy libdb5*dev libdb++-dev libdb-dev libdb5.3-tcl  >/dev/null
		apt purge -fy libdb5*dev libdb++-dev libdb-dev libdb5.3-tcl  >/dev/null

		if [ -d /tb2/build/$RELNAME-db4 ]; then
			cd /tb2/build/$RELNAME-db4
			dpkg -i --force-all *deb
		fi
	fi
}


wait_by_average_load(){
	LOOPLOAD=0
	LASTLOAD=0
	while :; do
		AVGL=$(cat /proc/loadavg | cut -d" " -f1 | cut -d"." -f1)
		AVGL=$(( $AVGL + 1))
		CORE=$(( `nproc` ))
		if [[ $AVGL -lt $CORE ]]; then break; fi

		if [[ $AVGL -ne $LASTLOAD ]]; then
			[[ $LOOPLOAD -lt 1 ]] && printf "\n --- average load checking: "
			printf " $AVGL"
		else
			printf "."
		fi
		LASTLOAD=$AVGL
		LOOPLOAD=$(( $LOOPLOAD + 1 ))
		sleep 3
	done
	[[ $LOOPLOAD -gt 2 ]] && printf "\n last load: $AVGL \n"
}

delete_phideb(){
	phideb=0
	if [[ -e /etc/apt/sources.list.d/phideb.list ]]; then
		rm -rf /etc/apt/sources.list.d/phideb.list
		phideb=1
	fi
	if [[ $(grep -i phideb /etc/apt/sources.list.d/* -l | wc -l) -gt 0 ]]; then
		grep -i phideb /etc/apt/sources.list.d/* -l | xargs rm -rf
		phideb=2
	fi
	if [[ $phideb -gt 0 ]]; then
		apt update
	fi
}

get_package_file(){
	URL="$1"
	DST="$2"

	DOGET=0
	if [[ ! -e "${DST}" ]]; then
		DOGET=1
	elif [[ ! -s "${DST}" ]]; then
		DOGET=1
	elif [[ $(find "${DST}" -mtime +1 | wc -l) -gt 0 ]]; then
		DOGET=1
	fi

	if [[ $DOGET -gt 0 ]]; then
		curl -A "Aptly/1.0" -Ss -L "$URL" > "$DST"
	fi
}

get_package_file_gz(){
	URL="$1"
	DST="$2"
	AGZ="$3"

	get_package_file "$URL" "$AGZ"
	DST="$2"
	AGZ="$3"

	if [[ -s "${AGZ}" ]]; then
		# ls -la "$AGZ"
		# printf "\n\n --- gzip -cdk $AGZ > $DST \n\n"
		gzip -cdk "$AGZ" > "$DST"
	fi
}

stop_services(){
	for ainit in $(find /etc/init.d/ -type f | grep "fpm\|nginx\|keydb\|nutc"); do
		/bin/bash $ainit stop
	done
}


apt_source_build_dep_from_file(){
	afile="$1"
	agroup="$2"

	# pick_file
	pfile="/tmp/$agroup-picks.txt"

	if [[ -s "$afile" ]]; then
		tfile=$(mktemp)
		cat $afile | grep -iv "horde\|php5\|php7\|embed\|apache\|dbg\|sym\|dh-php\|\-http" | \
			sort -u | sort > $tfile

		cat $tfile | xargs aptold build-dep -fy -qq
		cat $tfile | xargs aptold source -my -qq  2>&1 |\
			grep -iv "use\|git\|latest"

		rm -rf $tfile
	fi
}




init_dkbuild(){
	# global config
	global_git_config  &

	# chown apt
	chown_apt &

	# restart
	systemctl daemon-reload

	if [[ $(grep "buster" /etc/apt/sources.list | wc -l) -gt 0 ]]; then
		rm -rf /etc/resolvconf/run
		/etc/init.d/resolvconf restart
		
		/sbin/dhclient -4 -v -i -pf /run/dhclient.eth0.pid \
		-lf /var/lib/dhcp/dhclient.eth0.leases \
		-I -df /var/lib/dhcp/dhclient6.eth0.leases eth0
	else
		systemctl enable systemd-resolved.service
		systemctl restart systemd-resolved.service
		systemd-resolve --status
	fi

	systemctl enable systemd-timesyncd.service   >/dev/null 2>&1
	systemctl restart systemd-timesyncd.service  >/dev/null 2>&1 &
}


#--- automatically call init
init_dkbuild >/dev/null 2>&1 &


#--- update aptold
if [ ! -e /usr/local/sbin/aptold ]; then
	create_aptold
elif [[ $(grep "version17" /usr/local/sbin/aptold | wc -l) -lt 1 ]]; then
	create_aptold
fi
chmod +x /usr/local/sbin/aptold


#--- update aptnew
if [ ! -e /usr/local/sbin/aptnew ]; then
	create_aptnew
elif [[ $(grep "version17" /usr/local/sbin/aptnew | wc -l) -lt 1 ]]; then
	create_aptnew
fi
chmod +x /usr/local/sbin/aptnew
