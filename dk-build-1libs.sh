#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"
export DPKG_COLORS="always"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh


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
	sed -i -r 's/^DH_PHP_VERSIONS_OVERRIDE/\# DH_PHP_VERSIONS_OVERRIDE/' debian/rules

	cd "$odir"
}

fix_php_ps(){
	odir=$PWD
	adir="$1"

	cd /tmp;
	wget -c wget https://pecl.php.net/get/ps-1.4.4.tgz; \
	tar xvzf ps-1.4.4.tgz

	cd "$adir"
	[[ -e ps-1.4.1 ]] && mv ps-1.4.1 old.ps-1.4.1
	cp /tmp/ps-1.4.4 . -Rfa

	cp debian/control debian/control.in
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control
	sed -i -r 's/dh-php \(>= 0.12~/dh-php \(>= 4~/' debian/control.in
	sed -i -r 's/<min>4.3.10/<min>7.0.33/' package.xml
	sed -i -r 's/<release>1.4.1/<release>1.4.4/' package.xml

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

fix_debian_controls(){
	bdir="$1"
	odir=$PWD
	cd "$bdir"

	# copy if not exists
	[[ ! -e debian/control.in ]] && cp debian/control debian/control.in
	/usr/share/dh-php/gen-control

	files=('debian/control.in' 'debian/control')
	for afile in "${files[@]}"; do
		if [[ $(grep "Package\:.*all-dev" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php.*-all-dev/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 8.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php8.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 7.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php7.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		if [[ $(grep "Package\: 5.*" $afile | wc -l) -gt 0 ]]; then
			ftmp1=$(mktemp)
			awk '/Package\: php5.*/ {exit} {print}' $afile > $ftmp1
			mv $ftmp1 $afile
		fi

		dhphp_num=$(cat "$afile" | grep "dh\-php \(.*\)" | wc -l)
		# printf "\n\n $dhphp_num \n"
		if [[ $dhphp_num -gt 0 ]]; then
			sed -i -r 's/dh\-php \(>= .*\~?\)/dh\-php \(>= 4\~)/g' $afile
		fi
	done

	/usr/share/dh-php/gen-control
	cd "$odir"
}

