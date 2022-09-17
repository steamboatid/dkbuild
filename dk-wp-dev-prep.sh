#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNUM=$(( $(lsb_release -rs) ))
if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relname_bookworm
fix_apt_bookworm
# /bin/bash /tb2/build-devomd/dk-init-debian.sh

# get PHPVER from arguments
if [[ ! -z $1 ]]; then
	PHPVER="$1"
fi

# gen config
#-------------------------------------------
/bin/bash /tb2/build-devomd/dk-config-gen.sh

filling_apt_cache() {
	patt="$1"
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
	--include="*/" --include "${patt}" --exclude "*" \
	/tb2/tmp/cachedebs/* /var/cache/apt/archives/
}

fill_apt_cache() {
	phpv="$1"

	printf "\n --- fill apt cache -- $phpv "
	mkdir -p /var/cache/apt/archives/partial/
	chown -Rf _apt:root /var/cache/apt/archives
	chmod -Rf 700 /var/cache/apt/archives/partial/

	patts=("${phpv}" "*nginx*deb" "php-*deb" "*maria*deb" "keydb*deb" "memc*deb" "*keyring*deb")
	for apatt in "${patts[@]}"; do
		if [ -z "$apatt" ]; then continue; fi
		filling_apt_cache "${apatt}" >/dev/null 2>&1 &
	done

	wait_backs_wpatt "rsync"

	chown -Rf _apt:root /var/cache/apt/archives
	chmod -Rf 700 /var/cache/apt/archives/partial/
}

install_nvm() {
	source ~/.bashrc

	if [[ ! -e /tmp/nvm-install.sh ]]; then
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh > /tmp/nvm-install.sh
	fi

	/bin/bash /tmp/nvm-install.sh
	source ~/.bashrc
}

install_node() {
	# printf "\n RELNUM = $RELNUM \n"
	nodever="12"
	if [[ $RELNUM -ge 10 ]]; then
		nodever="16"
	elif [[ $RELNUM -eq 9 ]]; then
		nodever="14"
	elif [[ $RELNUM -eq 8 ]]; then
		nodever="14"
	fi

	nvm install $nodever
	nvm use $nodever
}

install_update_npm() {
	npm update
	npm install -g npm@latest
	npm install -g npm-check-updates
	ncu -u
	npm update
	npm install
}

install_php() {
	phpv="$1"

	printf "\n --- install php -- $phpv "

	# nginx mariadb
	aptold install -fy nginx-extras mariadb-server mariadb-client \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	# fix nginx.conf
	sed -i -r "s/^\tlisten \[/\t\# listen \[/g" /etc/nginx/sites-enabled/default
	aptold install -fy


	# prepare repo list
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php-sury.list
	aptold update

	>/tmp/all-php

	# remove unused
	apt-cache search php | awk '{print $1}' | \
	grep -i "xcache\|yac\|gmagick\|phalcon\|gearman\|swoole\|uopz\|fpm" | \
	xargs apt purge --auto-remove --purge -fy \
		2>&1 | grep -iv "not installed"

	apt-cache search php | awk '{print $1}' | grep "$phpv" | \
	grep -iv "dbg\|lib\|apache\|xcache\|yac\|gmagick\|phalcon\|gearman\|swoole\|uopz\|fpm" >> /tmp/all-php

	echo "$phpv" >> /tmp/all-php
	echo "$phpv-cli" >> /tmp/all-php

	cat /tmp/all-php | xargs aptold install -fy \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	aptold full-upgrade -fy
}

install_composer() {
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"

	mv composer.phar /usr/local/sbin/composer
	chmod +x /usr/local/sbin/composer

	if [[ $(grep "composer\/vendor" ~/.bashrc | wc -l) -lt 1 ]]; then
		printf "\nexport PATH=~/.config/composer/vendor/bin/:\$PATH\n" >> ~/.bashrc
	fi



	VERNUM=$(printf "$PHPVER" | sed -r "s/php//g")
	MAJOR=$(( $(printf "$VERNUM" | cut -d"." -f1) ))
	MINOR=$(( $(printf "$VERNUM" | cut -d"." -f2) ))

	ins=true
	if [[ $MAJOR -lt 7 ]]; then
		ins=false
	elif [[ $MAJOR -eq 7 ]] && [[ $MINOR -lt 2 ]]; then
		ins=false
	fi
	printf "\n\n $VERNUM -- MAJOR=$MAJOR -- MINOR=$MINOR -- ins=$ins \n\n"

	pkgs=""
	if [[ "$ins" = true ]]; then
		pkgs="phpstan/phpstan vimeo/psalm"
	fi

	composer -W --no-interaction \
		global require \
		phpunit/phpunit \
		squizlabs/php_codesniffer \
		yoast/phpunit-polyfills \
		phpcompatibility/php-compatibility \
		phpcompatibility/phpcompatibility-wp \
		wp-coding-standards/wpcs \
		dealerdirect/phpcodesniffer-composer-installer $pkgs
}



#===========================================
#  MAIN
#===========================================
apt autoclean >/dev/null 2>&1; apt clean >/dev/null 2>&1
rm -rf .npm/

killall -9 rsync find touch  >/dev/null 2>&1
killall -9 rsync find touch  >/dev/null 2>&1


#--- mod apt sources
sed -i -r "s/^deb-src/\# deb-src/g" /etc/apt/sources.list


#--- get PHPVER from hostname
if [[ -z "$PHPVER" ]]; then
	if [[ "$HOSTNAME" == "php56" ]]; then
		PHPVER="php5.6"
	elif [[ "$HOSTNAME" == "php70" ]]; then
		PHPVER="php7.0"
	elif [[ "$HOSTNAME" == "php71" ]]; then
		PHPVER="php7.1"
	elif [[ "$HOSTNAME" == "php72" ]]; then
		PHPVER="php7.2"
	elif [[ "$HOSTNAME" == "php73" ]]; then
		PHPVER="php7.3"
	elif [[ "$HOSTNAME" == "php74" ]]; then
		PHPVER="php7.4"
	elif [[ "$HOSTNAME" == "php80" ]]; then
		PHPVER="php8.0"
	elif [[ "$HOSTNAME" == "php81" ]]; then
		PHPVER="php8.1"
	elif [[ "$HOSTNAME" == "php82" ]]; then
		PHPVER="php8.2"
	fi
fi

if [[ -z "$PHPVER" ]]; then
	printf "\n\n PHP version unknown \n\n"
	exit 0
else
	printf "\n\n --- HOST = ${green}${HOSTNAME}${end} --- PHPVER = ${cyan}${PHPVER}${end} \n\n"
fi



fill_apt_cache "${PHPVER}"
install_php "${PHPVER}"

install_nvm
install_node
install_update_npm

install_composer

npm install -g grunt-cli

printf "\n\n\n"
exit 0;