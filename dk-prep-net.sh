#!/bin/bash
set -e

export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh

#--- chown apt
chown_apt



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

#--- remove ALL first
#-------------------------------------------
# cd `mktemp -d` && apt remove -fy --fix-missing --fix-broken php* nginx*


#--- chown apt
chown_apt


#--- NGINX
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
cat $FNOW | xargs aptold build-dep -fy

cat /tb2/tmp/nginx-pkg-org.txt | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' |
grep -iv "api\|perl\|debconf\|nginx-full\|nginx-light\|nginx-core\|nginx-extras" |
grep -iv "|" | cut -d":" -f1  >  /tmp/deps.pkgs

echo "perl-base"  >> /tmp/deps.pkgs
cat /tmp/deps.pkgs | tr "\n" " " | xargs aptold install -my
# exit 0;


#--- PHP
#-------------------------------------------
rm -rf /tmp/php8
mkdir -p /tb2/tmp /root/src/php8 /root/org.src/php8 /tmp/php8
cd /root/org.src/php8

URL="https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages"
URL="https://packages.sury.org/php/dists/buster/main/binary-amd64/Packages"

URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
get_package_file $URL /tmp/php8.pkgs

cat /tmp/php8.pkgs | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' |
grep -iv "\-embed\|\-dbg\|dbgsym\|php5\|php7\|php8.1\|recode\|phalcon\||\|apache2-api" | \
grep -iv "dictionary\|mysqlnd\|tmpfiles\|php-curl-all-dev\|\-ps\|\-json\|Pre-php-common\|yac" |
grep -iv "php5\|php7\|php8.1\|yac\|gmagick\|xcache\|solr\|swoole\|libtiff-dev\|posix0" |
cut -d":" -f1  >  /tmp/deps.pkgs

apt-cache search php | grep "\-dev" | \
grep -v "php5\|php7\|php8.1\|yac\|gmagick\|xcache\|solr\|swoole" | cut -d" " -f1 >>  /tmp/deps.pkgs
cat /tmp/deps.pkgs | tr "\n" " " | xargs aptold install -my


FDST="/tb2/tmp/php8-pkg-org.txt"
FDST1="/tb2/tmp/php8-pkg-org-1.txt"
FDST2="/tb2/tmp/php8-pkg-org-2.txt"

URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
get_package_file $URL $FDST

FNOW="/tb2/tmp/php8-pkg-now.txt"
FNOW1="/tb2/tmp/php8-pkg-now-1.txt"
FNOW2="/tb2/tmp/php8-pkg-now-2.txt"
FSRC="/tb2/tmp/php8-pkg-src.txt"

# search package from "Package:"
#-------------------------------------------
cat $FDST | grep "Package:\|Source:" | \
sed "s/Package\: //g" | sed "s/Source\: //g" |
grep -v "\-embed\|\-dbg\|dbgsym\|php5\|php7\|php8.1\|recode\|phalcon" |
grep -v "Auto-Built" | sed -E 's/\(([^(.*)]*)\)//g' | sed -r 's/\s+//g' | sort -u | sort > $FNOW

cd /root/org.src/php8

echo "php-phalcon3" >> $FNOW
echo "libicu-dev" >> $FNOW
apt-cache search php8.0 | awk '{print $1}' | grep -v "dbgsym\|dbg" >> $FNOW
apt-cache search php | grep "php\-" | grep "\-dev" | awk '{print $1}' | grep -v "dbgsym\|dbg" >> $FNOW
cat $FNOW | sort -u | sort | tr "\n" " " | xargs aptold build-dep -y --ignore-missing | tee $FSRC

for apkg in $(cat $FSRC | cut -d" " -f2 | sed -r "s/'//g" | sort -u | sort); do
	chown_apt
	apt source -y --ignore-missing $apkg || echo "failed for $apkg"
done


#--- wait
#-------------------------------------------
bname=$(basename $0)
printf "\n\n --- wait for all background process...  [$bname] "
while :; do
	nums=$(jobs -r | grep -iv "find\|chmod\|chown" | wc -l)
	printf ".$nums "
	if [[ $nums -lt 1 ]]; then break; fi
	sleep 1
done

wait
printf "\n\n --- wait finished... \n\n\n"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src php8 \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/php8/ /root/src/php8/



#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;