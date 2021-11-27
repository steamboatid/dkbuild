#/bin/bash


apt-cache search php8.1 | cut -d' ' -f1 | \
grep -iv "symfony\|cgi\|lib\|enchant\|dbg" | tr "\n" " " | \
xargs aptold install -fy 2>&1 |
	grep -iv "newest\|cli interface\|reading\|building"

cat <<\EOT >/etc/php/8.0/mods-available/zdev.ini
assert.exception = 1
zend.assertions = 1
opcache.enable = 1
opcache.enable_cli = 1
opcache.optimization_level = -1
opcache.jit = 1255
opcache.jit_buffer_size = 32M

error_reporting = -1
log_errors_max_len = 0
display_errors = stderr

phar.readonly = 0
xdebug.mode = coverage
EOT

ln -sf /etc/php/8.0/mods-available/zdev.ini /etc/php/8.0/cli/conf.d/99-zdev.ini
ln -sf /etc/php/8.0/mods-available/zdev.ini /etc/php/8.0/fpm/conf.d/99-zdev.ini


re_arrange_extensions(){
	sapi="$1"
	for asym in $(grep -i "opcache.so" /etc/php/8.0/$sapi/conf.d/* -l); do
		bname=$(basename $asym)
		dname=$(dirname $asym)
		oname=$(echo "$bname" | cut -d"-" -f2)
		nname="$dname/80-$oname"
		# printf "\n old=$asym --- new $nname"
		mv $asym $nname >/dev/null 2>&1
	done

	for asym in $(grep -i "xdebug.so" /etc/php/8.0/$sapi/conf.d/* -l); do
		bname=$(basename $asym)
		dname=$(dirname $asym)
		oname=$(echo "$bname" | cut -d"-" -f2)
		nname="$dname/00-$oname"
		# printf "\n old=$asym --- new $nname"
		mv $asym $nname >/dev/null 2>&1
		sed -i -r "s/^zend/\; zend/g" $nname
	done
}

re_arrange_extensions "cli"
re_arrange_extensions "fpm"

if [[ ! -e /usr/local/bin/composer ]]; then
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	mv composer.phar /usr/local/bin/composer
fi

chmod +x /usr/local/bin/composer
