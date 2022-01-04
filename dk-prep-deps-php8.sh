#!/bin/bash
set -e

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

export PHPVERS=("php8.0" "php8.1")
export PHPGREP=("php8.0\|php8.1")


source /tb2/build/dk-build-0libs.sh




fixing_folders_by_dsc_files(){
	odir=$PWD
	cd /root/org.src/php
	for a in $(find . -maxdepth 1 -type f -iname "*.dsc" | sort ); do
		dpkg-source -x --no-check --no-overwrite-dir $a 2>&1 | grep -v 'error'
	done


	cd "$odir"
	chown_apt
	>/tmp/php-pkgs.txt
	for afile in $(find /root/org.src/php -maxdepth 1 -type f -iname "*.dsc"); do
		bname=$(basename $afile)
		ahead=$(printf "$bname" | cut -d"_" -f1)
		if [[ $ahead = *"xmlrpc"* ]]; then continue; fi

		adir=$(printf "$ahead" | sed -r 's/\_/\-/g')

		bdir=$adir
		patts=('php8\.0\-' 'php8\.1\-' 'php\-' '\-all\-dev')
		for apatt in "${patts[@]}"; do
			bdir=$(printf "$bdir" | sed -r "s/$apatt//g")
		done

		anum=$(find /root/org.src/php -maxdepth 1 -type d -iname "*${bdir}-*" | wc -l)
		if [[ $anum -lt 1 ]]; then
			printf "\n\n --- Dir ${read}$adir -- $bdir ${end} missing \n"
			echo "$adir" >>/tmp/php-pkgs.txt
		fi
	done

	apt_source_build_dep_from_file "/tmp/php-pkgs.txt" "php"

	cd "$odir"
	printf "\n\n"
}



# delete phideb
delete_phideb


#--- PHP
#-------------------------------------------
rm -rf /tmp/php
mkdir -p /root/src/php /root/org.src/php /tmp/php /tb2/tmp

cd /root/org.src/php
chown -Rf _apt:root /root/org.src/php
chown_apt

fixing_folders_by_dsc_files
fixing_folders_by_dsc_files


# list of package source
#-------------------------------------------
[[ -e /tmp/php-pkgs.txt ]] && touch /tmp/php-pkgs.txt || >/tmp/php-pkgs.txt


FPKGS="/tmp/php.pkgs"
FDEPS="/tmp/php-deps.pkgs"
FDEPF="/tmp/php-deps-final.pkgs"

URL="https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages"
URL="https://packages.sury.org/php/dists/buster/main/binary-amd64/Packages"
# URL="http://repo.aisits.id/php/dists/buster/main/binary-amd64/Packages"

rm -rf $FPKGS
URL="http://repo.aisits.id/php/dists/${RELNAME}/main/binary-amd64/Packages"
get_package_file $URL $FPKGS

# # if $FPKGS empty
# ls -la $FPKGS
# if [[ ! -s $FPKGS ]]; then
# 	URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
# 	get_package_file $URL $FPKGS
# fi

# ls -la $FPKGS
# if [[ ! -s $FPKGS ]]; then
# 	printf "\n\n --- $FPKGS empty \n\n"
# 	exit 1
# fi



cat $FPKGS | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' | \
grep -iv "\-embed\|\-dbg\|dbgsym\|libtiff-dev\|posix0\|apache2" | \
grep -iv "dictionary\|mysqlnd\|tmpfiles\|php-curl-all-dev\|\-ps\|\-json\|Pre-php-common\|yac" | \
grep -iv "php5\|php7\|yac\|gmagick\|xcache\|solr\|swoole\|recode\|phalcon\|apache2" | \
cut -d":" -f1 | sort -u | sort  >  $FDEPS

apt-cache search php | grep "\-dev" | \
grep -iv "php5\|php7\|yac\|gmagick\|xcache\|solr\|swoole\|recode\|phalcon\|apache2" | \
cut -d" " -f1  >>  $FDEPS

cat $FDEPS | sort -u | sort | sed -r 's/\|//g' | sed '/^$/d' | \
grep -iv "php5\|php7\|yac\|gmagick\|xcache\|solr\|swoole\|recode\|phalcon\|apache2" | \
  >>  $FDEPF

cat $FDEPF | tr "\n" " " | xargs aptold install -my \
	2>&1 | grep -iv "nable to locate\|not installed\|newest\|picking\|reading\|building\|stable CLI"


FDST1="/tb2/tmp/php-pkg-org-1.txt"
FDST2="/tb2/tmp/php-pkg-org-2.txt"
FDST3="/tb2/tmp/php-pkg-org-3.txt"

# URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
# get_package_file $URL $FDST1
cp $FPKGS $FDST1

FNOW1="/tb2/tmp/php-pkg-now-1.txt"
FNOW2="/tb2/tmp/php-pkg-now-2.txt"
FNOW3="/tb2/tmp/php-pkg-now-3.txt"

FSRC1="/tb2/tmp/php-pkg-src-1.txt"
FSRC2="/tb2/tmp/php-pkg-src-2.txt"
FSRC3="/tb2/tmp/php-pkg-src-3.txt"

# search package from "Package:"
#-------------------------------------------
cat $FDST1 | grep "Package:\|Source:" | \
	sed "s/Package\: //g" | sed "s/Source\: //g" | \
	grep -v "\-embed\|\-dbg\|dbgsym\|php5\|php7\|recode\|phalcon\|apache" | \
	grep -v "Auto-Built" | sed -E 's/\(([^(.*)]*)\)//g' | sed -r 's/\s+//g' | \
	sort -u | sort > $FNOW1


tails=(solr swoole xmlrpc phalcon4)
for atail in "${tails[@]}"; do
	apt-cache search "\-${atail}" | grep "php\-\|${PHPV}" | cut -d" " -f1  >> $FNOW1
done

echo "libicu-dev" >> $FNOW1


apt-cache search "php" | awk '{print $1}' | grep "${PHPGREP}" | \
	grep -v "dbgsym\|dbg\|apache" >> $FNOW1
apt-cache search php | grep "php\-" | grep "\-dev" | awk '{print $1}' | \
	grep -v "dbgsym\|dbg\|apache" >> $FNOW1

apt-cache search php8 | cut -d" " -f1 | \
	grep -iv "symfony\|apache\|embed\|dbgsym" >> $FNOW1

echo "php-pecl-http php-pecl-http-dev" | tr " " "\n" >> $FNOW1


cat $FNOW1 | grep -i "${PHPGREP}\|php\-" | \
	sort -u | sort | \
	sed 's/(\([^\)]*\))//g' > $FNOW2


cat $FNOW2 | sort -u | sort > $FNOW3


#--- check by apt-cache search
>$FNOW2
printf "\n\n missing packages: \n"
for apkg in $(cat $FNOW3); do
	if [[ $(apt-cache search "$apkg" | wc -l) -gt 0 ]]; then
		echo "${apkg}" >> $FNOW2
	else
		printf " --- $apkg \n"
	fi
done

cat $FNOW2 | sort -u | sort | \
	xargs aptold build-dep -my 2>&1 | tee $FSRC1

# source packages
cat $FSRC1 | grep "Picking" | grep -iv "unable" | cut -d" " -f2 | sed -r "s/'//g" | sort -u | sort > $FSRC2

>$FSRC3
cat $FSRC2 | grep "php\-" >> $FSRC3
cat $FSRC2 | grep "${PHPGREP}" >> $FSRC3

chown_apt
cat $FSRC3 | \
grep -iv "php8.1-http\|php8.0-http\|php-http" | \
sort -u | sort  >>/tmp/php-pkgs.txt
# cat $FSRC3 | sort -u | sort



#--- last attempt to install all
cd /root/org.src/php

apt-cache search php8 | cut -d" " -f1 | \
	grep -iv "symfony\|apache\|embed\|dbgsym\|yac\|gmagick" | xargs aptold install -fy

apt-cache search php8 | cut -d" " -f1 | \
	grep -iv "symfony\|apache\|embed\|dbgsym\|yac\|gmagick" >>/tmp/php-pkgs.txt
apt-cache search php8 | cut -d" " -f1 | \
	grep -iv "symfony\|apache\|embed\|dbgsym" | \
	grep -iv "php8.1-http\|php8.0-http\|php-http"  >>/tmp/php-pkgs.txt

apt-cache search sodium | cut -d" " -f1 | \
	grep -iv "python\|ruby\|dbg\|cran\|apache\|embed\|php7\|php5\|rust" | \
	xargs aptold install -fy
apt-cache search sodium | cut -d" " -f1 | \
	grep -iv "python\|ruby\|dbg\|cran\|apache\|embed\|php7\|php5\|rust" \
	>>/tmp/php-pkgs.txt

apt-cache search libicu | cut -d" " -f1 | \
	grep -iv "java\|dbg\|sym\|hb" | xargs aptold install -fy
apt-cache search libicu | cut -d" " -f1 | \
	grep -iv "java\|dbg\|sym\|hb" \
	>>/tmp/php-pkgs.txt

apt-cache search libxmlrpc | cut -d" " -f1 | \
	grep -iv "perl\|java\|ocaml" | xargs aptold install -fy


apt search php 2>&1 | grep -iv "stable cli" | grep 2021 | \
grep -iv "php5\|php7\|embed\|apache\|dbg\|sym\|dh-php\|dev\|common\|default\|\-http" | \
cut -d"/" -f1  | sort -u | sort  \
	>>/tmp/php-pkgs.txt

apt_source_build_dep_from_file "/tmp/php-pkgs.txt" "php"



fixing_folders_by_dsc_files
fixing_folders_by_dsc_files
apt autoremove --auto-remove --purge -fy


# xmlrpc included in php-defaults
dsc_num=$(find /root/org.src/php -maxdepth 1 -type f -iname "*.dsc" | grep -iv "xmlrpc" | wc -l)
dir_num=$(find /root/org.src/php -maxdepth 1 -type d | wc -l)
printf "\n\n\n --- DSC=${blue}$dsc_num ${end} --- DIR=${blue}$dir_num ${end} \n\n"




#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n --- wait for all background process...  [$bname] "
wait_backs_nopatt; wait
printf "\n\n --- wait finished... \n\n\n"


#--- delete unused
#-------------------------------------------
rm -rf ~/org.src/php/rust*

#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: PHP \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/php/ /root/src/php/




#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"

find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;