#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


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


#--- chown apt
chown -Rv _apt:root /var/cache/apt/archives/partial/
chmod -Rv 700 /var/cache/apt/archives/partial/


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



# PHP
#-------------------------------------------
rm -rf /tmp/php8
mkdir -p /tb2/tmp /root/src/php8 /root/org.src/php8 /tmp/php8
cd /root/org.src/php8

FDST="/tb2/tmp/php8-pkg-org.txt"

URL="https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages"
FDST1="/tb2/tmp/php8-pkg-org-1.txt"
get_package_file $URL $FDST1

URL="https://packages.sury.org/php/dists/buster/main/binary-amd64/Packages"
FDST2="/tb2/tmp/php8-pkg-org-2.txt"
get_package_file $URL $FDST2

>$FDST
cat $FDST1 >> $FDST
cat $FDST2 >> $FDST

FNOW1="/tb2/tmp/php8-pkg-now-1.txt"
FNOW2="/tb2/tmp/php8-pkg-now-2.txt"
FSRC="/tb2/tmp/php8-pkg-src.txt"

# search package from "Package:"
cat $FDST | grep "Package:" | sed "s/Package\: //g" |
grep -v "\-embed\|\-dbg\|dbgsym\|\-dev\|php5\|php7\|php8.1\|recode" |
grep -v "Auto-Built" | sed -E 's/\(([^(.*)]*)\)//g' | sed -r 's/\s+//g' | sort -u | sort > $FNOW1

# search package from "Source:"
cat $FDST | grep "Source:" | sed "s/Source\: //g" |
grep -v "\-embed\|\-dbg\|dbgsym\|\-dev\|php5\|php7\|php8.1\|recode" |
sed -E 's/\(([^()]*)\)//g' | sed -r 's/\s+//g' | sort -u | sort >> $FNOW1

cd /root/org.src/php8
cat $FNOW1 | sort -u | sort >> $FNOW2
cat $FNOW2 | tr "\n" " " | xargs apt build-dep -y --ignore-missing | tee $FSRC
for apkg in $(cat $FSRC | cut -d" " -f2 | sed -r "s/'//g" | sort -u | sort); do
	apt source -y --ignore-missing $apkg
done



#-- sync to src
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/php8/ /root/src/php8/
