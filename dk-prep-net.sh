#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)


get_package_file(){
	URL=$1
	DST=$2

	DOGET=0
	if [ ! -s "${DST}" ]; then DOGET=1; fi
	if [ test `find "${DST}" -mtime +100` ]; then DOGET=1; fi
	if [[ $DOGET -gt 0 ]]; then
		curl -A "Aptly/1.0" -Ss $URL > $DST
	fi
}

get_package_file_gz(){
	URL=$1
	DST=$2
	AGZ=$3

	get_package_file $URL $AGZ
	if [ ! -s "${AGZ}" ]; then
		gzip -cdk $AGZ > $DST
	fi
}

# remove ALL first
#-------------------------------------------
# cd `mktemp -d` && apt remove -fy --fix-missing --fix-broken php* nginx*


# NGINX
#-------------------------------------------
rm -rf /tmp/nginx
mkdir -p /tb2/tmp /root/src/nginx /tmp/nginx

URL="http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu/dists/bionic/main/binary-amd64/Packages.gz"
FDST="/tb2/tmp/nginx-pkg-org.txt"
FGZ="/tb2/tmp/nginx-pkg-org.gz"
FNOW="/tb2/tmp/nginx-pkg-now.txt"
get_package_file_gz $URL $FDST $FGZ

cat $FDST | grep "Package:" | sed "s/Package\: //g" | \
tr "\n" " " > $FNOW

cd /root/src/nginx
cat $FNOW | xargs apt build-dep -fy
# cat $FNOW | xargs apt source -y

cd /root/src/nginx
rm -rf *asc *xz *gz *bz2


# PHP
#-------------------------------------------
rm -rf /tmp/php8
mkdir -p /tb2/tmp /root/src/php8 /tmp/php8

URL="https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages"
FDST="/tb2/tmp/php8-pkg-org.txt"
FNOW="/tb2/tmp/php8-pkg-now.txt"
get_package_file $URL $FDST

cat $FDST | grep "Package:" | sed "s/Package\: //g" | \
grep -v "libapache2\|libpcre2-posix2\|symbols\|dbgsym\|php5\|php7\|php8.1" | \
tr "\n" " " > $FNOW

cd /root/src/php8
cat $FNOW | xargs apt build-dep -fy
cat $FNOW | xargs apt source -y

cd /root/src/php8
rm -rf *asc *xz *gz *bz2
