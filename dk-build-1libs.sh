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


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm


fix_php_pecl_http(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r '0,/^php-pecl-http/{s/^php-pecl-http/php-http/}' debian/changelog
	sed -i -r 's/pecl-http\.so/http\.so/' debian/php-http.pecl

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.33~/dh-php \(>= 4~/' debian/control

	sed -i -r 's/^Source\: php\-pecl\-http/Source\: php\-http/' debian/control.in
	sed -i -r 's/^Provides\: php\-pecl\-http/Provides\: php\-http/' debian/control.in
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/dh-php \(>= 0.33~/dh-php \(>= 4~/' debian/control.in

	cd "$odir"
}

fix_php_lz4(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	# sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules

	cd "$odir"
}

fix_php_ps(){
	odir=$PWD
	adir="$1"

	cd /tmp; \
	rm -rf ps-1.4.4.tgz; \
	wget -c wget https://pecl.php.net/get/ps-1.4.4.tgz; \
	tar xvzf ps-1.4.4.tgz

	cd "$adir"
	[[ -e ps-1.4.1 ]] && mv ps-1.4.1 old.ps-1.4.1
	cp /tmp/ps-1.4.4 . -Rfa

	cp debian/control debian/control.in
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/<min>4.3.10/<min>8.1.0/' package.xml
	sed -i -r 's/<release>1.4.1/<release>1.4.4/' package.xml

	cd "$odir"
}

fix_php_pinba(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	sed -i -r 's/<min>4.4.8/<min>8.1.0/' package.xml

	cd "$odir"
}

fix_php_phalcon3(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	cp debian/control debian/control.in

	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 3.1~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules

	cd "$odir"
}

fix_php_imagick(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	if [[ -e package.xml ]]; then
		phpver=$(cat package.xml | grep "<php>" -A1 | tail -n1 | sed -r 's/\s+//g' | sed 's/<\/min>//g')
		cp package.xml package.xml.bak -f
		sed -i -r "s/${phpver}/<min>8.1.0/" package.xml
	fi

	cd "$odir"
}

fix_php_pecl_package_xml(){
	odir=$PWD
	adir="$1"
	cd "$adir"

	if [[ $adir == *"php"* ]] && [[ -e package.xml ]]; then
		phpverall=$(cat package.xml | grep "<php>" -A1 | tail -n1 | sed -r 's/\s+//g' | sed 's/<\/min>//g')
		phpmajor=$(echo $phpverall | sed 's/<min>//' | cut -d'.' -f1)
		phpmajor=$(( phpmajor ))

		if [[ $phpmajor -lt 8 ]]; then
			cp package.xml package.xml.old -f
			sed -i -r "s/${phpverall}/<min>8.1.0/" package.xml
		fi
	fi

	cd "$odir"
}

fix_debian_controls(){
	bdir="$1"
	odir=$PWD
	cd "$bdir"

	# copy if not exists
	[[ ! -e debian/control.in ]] && cp debian/control debian/control.in

	files=('debian/control.in' 'debian/control')
	for afile in "${files[@]}"; do
		# if [[ ! -e $afile ]]; then continue; fi

		if [[ $(grep "Package\:.*all-dev" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package: php.*-all-dev/ {exit} {print}' "$afile" > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 8.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package: php8.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 7.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package: php7.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 5.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package: php5.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		dhphp_num=$(cat "$afile" | grep "dh\-php \(.*\)" | wc -l)
		# printf "\n\n $dhphp_num \n"
		if [[ $dhphp_num -gt 0 ]]; then
			sed -i -r 's/dh\-php \(>= .*\~?\)/dh\-php \(>= 4\~)/g' $afile
		fi
	done

	cd "$odir"
}

delete_bad_php_ext(){
	find -L /root/org.src/php -maxdepth 1 -type d -iname "*xmlrpc*" | xargs rm -rf
	find -L /root/org.src/php -maxdepth 1 -type f -iname "*xmlrpc*" | xargs rm -rf
	find -L /root/src/php -maxdepth 1 -type d -iname "*xmlrpc*" | xargs rm -rf
	find -L /root/src/php -maxdepth 1 -type f -iname "*xmlrpc*" | xargs rm -rf

	http_v3=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-3*" | wc -l)
	http_v4=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-4*" | wc -l)
	if [[ $http_v3 -gt 0 ]] && [[ $http_v4 -gt 0 ]]; then
		find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*http-3*" | xargs rm -rf
	fi

	ps_141=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.1*" | wc -l)
	ps_144=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.4*" | wc -l)
	if [[ $ps_141 -gt 0 ]] && [[ ps_144 -gt 0 ]]; then
		find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*-ps-1.4.1*" | xargs rm -rf
	fi

	pinba_110=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.0*" | wc -l)
	pinba_112=$(find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.2*" | wc -l)
	if [[ $pinba_110 -gt 0 ]] && [[ $pinba_112 -gt 0 ]]; then
		find -L /root/src/php -maxdepth 1 -mindepth 1 -type d -iname "*pinba-1.1.0*" | xargs rm -rf
	fi
}


#--- mark as manual installed,
# for nginx, php, redis, keydb, memcached
# 5.6  7.0  7.1  7.2  7.3  7.4  8.2
#-------------------------------------------
limit_php8x_only(){
	rm -rf /etc/php/5.6 /etc/php/7.0 /etc/php/7.1 /etc/php/7.2 /etc/php/7.3 \
	/etc/php/8.2 \
	/usr/share/php/5.6 /usr/share/php/7.0 /usr/share/php/7.1 \
	/usr/share/php/7.2 /usr/share/php/7.3 /usr/share/php/8.2 \
	/usr/share/php5* /usr/share/php7* /usr/share/php8.2*

	apt-cache search php | grep "all-dev" | awk '{print $1}' | \
	xargs apt remove -fy --allow-change-held-packages

	apt remove -fy --allow-change-held-packages \
	php5* php7.0* php7.1* php7.2* php7.3* php8.2* \
	php-propro php-propro-dev php-all-dev php-sodium

	apt-mark hold php*

	dpkg -l | grep "PHP\|nginx\|memcache\|keydb\|redis\|db4" | \
	awk '{print $2}' | tr "\n" " " | xargs apt-mark manual \
		>/dev/null 2>&1

	apt-mark manual libssl1.1 libssl3 libssl-dev libffi7 libffi8 libffi-dev \
		>/dev/null 2>&1

	rm -rf /root/src/git-raphf/src/php_raphf.h
	rm -rf /root/org.src/git-raphf/src/php_raphf.h
}


fix_package_57_xml(){
	odir=$PWD

	xmlfixes=0

	find /root/org.src/php/ -maxdepth 3 -type f -iname "package-7.xml" |\
	while read afile; do
		pdir=$(dirname $afile)
		p7file="$pdir/package-7.xml"

		if [[ -e $p7file ]]; then
			pfile="$pdir/package.xml"
			if [[ -e $pfile ]]; then
				rm -rf "$p7file"
			else
				mv "$p7file" "$pfile"
			fi
		fi

		xmlfixes=$(( xmlfixes+1 ))
	done

	find /root/org.src/php/ -maxdepth 3 -type f -iname "package-5.xml" |\
	while read afile; do
		pdir=$(dirname $afile)
		p5file="$pdir/package-5.xml"

		if [[ -e $p5file ]]; then
			pfile="$pdir/package.xml"
			if [[ -e $pfile ]]; then
				rm -rf "$p5file"
			else
				mv "$p5file" "$pfile"
			fi
		fi

		xmlfixes=$(( xmlfixes+1 ))
	done


	find /root/org.src/php/ -maxdepth 3 -type f -iname "package.xml" |\
	while read afile; do
		pdir=$(dirname $afile)
		fix_php_pecl_package_xml "$pdir"
	done

	cd "$odir"
}
