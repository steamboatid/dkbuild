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

export PHPV_DEFAULT="php8.0"
export PHPV="${1:-$PHPV_DEFAULT}"
export PHPVNUM=$(echo $PHPV | sed 's/php//g')


source /tb2/build/dk-build-0libs.sh




get_package_file(){
	URL="$1"
	DST="$2"

	DOGET=0
	if [ ! -s "${DST}" ]; then DOGET=1; fi
	if [ test `find "${DST}" -mtime +10800` ]; then DOGET=1; fi
	if [[ $DOGET -gt 0 ]]; then
		curl -A "Aptly/1.0" -Ss "$URL" > "$DST"
	fi
}

get_package_file_gz(){
	URL="$1"
	DST="$2"
	AGZ="$3"

	get_package_file "$URL" "$AGZ"
	if [ ! -s "${AGZ}" ]; then
		gzip -cdk "$AGZ" > "$DST"
	fi
}

fixing_folders_by_dsc_files(){
	for afile in $(find /root/org.src/$PHPV -maxdepth 1 -type f -iname "*.dsc"); do
		bname=$(basename $afile)
		ahead=$(printf "$bname" | cut -d"_" -f1)
		anum=$(find /root/org.src/$PHPV -maxdepth 1 -type d -iname "${ahead}*" | wc -l)
		if [[ $anum -lt 1 ]]; then
			printf " $ahead \n"

			aptold build-dep -my $ahead
			apt source -my $ahead
		fi
	done
}



# print PHP version
#-------------------------------------------
printf "\n\n --- php version: ${yel}$PHPV${end} [$PHPVNUM] \n\n"


#--- PHP
#-------------------------------------------
rm -rf /tmp/$PHPV
mkdir -p /root/src/$PHPV /root/org.src/$PHPV /tmp/$PHPV /tb2/tmp

cd /root/org.src/$PHPV
chown -Rf _apt:root /root/org.src/$PHPV
chown_apt

fixing_folders_by_dsc_files
fixing_folders_by_dsc_files


FPKGS="/tmp/$PHPV.pkgs"
FDEPS="/tmp/$PHPV-deps.pkgs"
FDEPF="/tmp/$PHPV-deps-final.pkgs"

URL="https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages"
URL="https://packages.sury.org/php/dists/buster/main/binary-amd64/Packages"
# URL="http://repo.aisits.id/php/dists/buster/main/binary-amd64/Packages"

URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
# URL="http://repo.aisits.id/php/dists/${RELNAME}/main/binary-amd64/Packages"
get_package_file $URL $FPKGS

cat $FPKGS | grep "Depends:" | sed -r "s/Depends: //g"| \
sed "s/\,//g" | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | sed "s/\s/\n/g" | sed '/^$/d' | \
grep -iv "\-embed\|\-dbg\|dbgsym\|libtiff-dev\|posix0" | \
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


FDST1="/tb2/tmp/$PHPV-pkg-org-1.txt"
FDST2="/tb2/tmp/$PHPV-pkg-org-2.txt"
FDST3="/tb2/tmp/$PHPV-pkg-org-3.txt"

# URL="https://packages.sury.org/php/dists/${RELNAME}/main/binary-amd64/Packages"
# get_package_file $URL $FDST1
cp $FPKGS $FDST1

FNOW1="/tb2/tmp/$PHPV-pkg-now-1.txt"
FNOW2="/tb2/tmp/$PHPV-pkg-now-2.txt"
FNOW3="/tb2/tmp/$PHPV-pkg-now-3.txt"

FSRC1="/tb2/tmp/$PHPV-pkg-src-1.txt"
FSRC2="/tb2/tmp/$PHPV-pkg-src-2.txt"

# search package from "Package:"
#-------------------------------------------
cat $FDST1 | grep "Package:\|Source:" | \
	sed "s/Package\: //g" | sed "s/Source\: //g" | \
	grep -v "\-embed\|\-dbg\|dbgsym\|php5\|php7\|recode\|phalcon\|apache" | \
	grep -v "Auto-Built" | sed -E 's/\(([^(.*)]*)\)//g' | sed -r 's/\s+//g' | \
	sort -u | sort > $FNOW1


tails=(gmagick solr swoole yac xmlrpc phalcon4)
for atail in "${tails[@]}"; do
	apt-cache search "\-${atail}" | grep "php\-\|${PHPV}" | cut -d" " -f1  >> $FNOW1
done

echo "libicu-dev" >> $FNOW1


apt-cache search $PHPV | awk '{print $1}' | grep "$PHPV" | \
	grep -v "dbgsym\|dbg\|apache" >> $FNOW1
apt-cache search php | grep "php\-" | grep "\-dev" | awk '{print $1}' | \
	grep -v "dbgsym\|dbg\|apache" >> $FNOW1

cat $FNOW1 | grep -i "$PHPV\|php\-" | \
	sort -u | sort | \
	sed 's/(\([^\)]*\))//g' >> $FNOW2

cat $FNOW2 | sort -u | sort | \
	xargs aptold build-dep -my $apkg  2>&1 | tee $FSRC1

# source packages
cat $FSRC1 | grep -iv "unable" | cut -d" " -f2 | sed -r "s/'//g" | sort -u | sort > $FSRC2

>$FSRC1
cat $FSRC2 | grep "php\-" >> $FSRC1
cat $FSRC2 | grep "$PHPV" >> $FSRC1

cat $FSRC1 | sort -u | sort | tr "\n" " " | xargs apt source -my


fixing_folders_by_dsc_files
fixing_folders_by_dsc_files


dsc_num=$(find /root/org.src/$PHPV -maxdepth 1 -type f -iname "*.dsc" | wc -l)
dir_num=$(find /root/org.src/$PHPV -maxdepth 1 -type d | wc -l)
printf "\n\n\n --- DSC=${blue}$dsc_num ${end} --- DIR=${blue}$dir_num ${end} \n\n"




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
printf "\n-- sync to src: ${yel}$PHPV ${end}\n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/$PHPV/ /root/src/$PHPV/




#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building" | grep --color=auto "Depends"

find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;