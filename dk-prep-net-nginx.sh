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


#--- NGINX
#-------------------------------------------
rm -rf /tmp/nginx
mkdir -p /root/org.src/nginx /root/src/nginx /tmp/nginx /tb2/tmp


URL="http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu/dists/bionic/main/binary-amd64/Packages.gz"
FDST="/tb2/tmp/nginx-pkg-org.txt"
FGZ="/tb2/tmp/nginx-pkg-org.gz"
FNOW="/tb2/tmp/nginx-pkg-now.txt"
get_package_file_gz $URL $FDST $FGZ

cat $FDST | grep "Package:" | sed "s/Package\: //g" | \
tr "\n" " " > $FNOW


cd /root/org.src/nginx
chown -Rf _apt:root /root/org.src/nginx

cat $FNOW | xargs aptold build-dep -fy

cat /tb2/tmp/nginx-pkg-org.txt | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' | \
grep -iv "api\|perl\|debconf\|nginx-full\|nginx-light\|nginx-core\|nginx-extras" | \
grep -iv "|" | cut -d":" -f1  >  /tmp/deps.pkgs

echo "perl-base"  >> /tmp/deps.pkgs
cat /tmp/deps.pkgs | tr "\n" " " | xargs aptold install -fy \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"



#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: nginx \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/nginx/ /root/src/nginx/



#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;