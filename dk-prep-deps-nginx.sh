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


source /tb2/build-devomd/dk-build-1libs.sh
fix_relname_bookworm
fix_apt_bookworm


#--- remove ALL first
#-------------------------------------------
# cd `mktemp -d` && apt remove -fy --fix-missing --fix-broken php* nginx*


#--- NGINX
#-------------------------------------------
rm -rf /tmp/nginx
mkdir -p /root/org.src/nginx /root/src/nginx /tmp/nginx /tb2/tmp


URL="http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu/dists/impish/main/binary-amd64/Packages.gz"
FDST="/tb2/tmp/nginx-pkg-org.txt"
FGZ="/tb2/tmp/nginx-pkg-org.gz"
FNOW="/tb2/tmp/nginx-pkg-now.txt"
get_package_file_gz $URL $FDST $FGZ


cd /root/org.src/nginx
chown -Rf _apt:root /root/org.src/nginx

cat $FDST | grep "Package:" | sed "s/Package\: //g" | \
grep -iv "resty\|ldap\|brotli\|pam\|js\|redis2\|vhost-traffic-status" | \
tr "\n" " " > $FNOW

cat $FNOW | xargs aptold build-dep -fy


cat /tb2/tmp/nginx-pkg-org.txt | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' | \
grep -iv "api\|perl\|debconf\|nginx-full\|nginx-light\|nginx-core\|nginx-extras" | \
grep -iv "|" | cut -d":" -f1 | sort -u >  /tmp/deps.pkgs

echo "perl-base"  >> /tmp/deps.pkgs

cat /tmp/deps.pkgs | sort -u | sort | tr "\n" " " | \
	xargs aptold install -my \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"

aptold install -fy
# apt autoremove --auto-remove --purge -fy \
#  2>&1 | grep --color "upgraded"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src: ${yel}nginx${end} \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/nginx/ /root/src/nginx/



#--- last
#-------------------------------------------
# save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find -L /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find -L /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1


#--- mark as manual installed,
# for nginx, php, redis, keydb, memcached
# 5.6  7.0  7.1  7.2  7.3  7.4  8.2
#-------------------------------------------
limit_php8x_only


printf "\n\n\n"
exit 0;