#!/bin/bash


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


source /tb2/build-devomd/dk-build-0libs.sh



# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4.8_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4-tcl_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4-dev_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4-dbg_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4%2B%2B_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4%2B%2B_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4%2B%2B_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/libdb4%2B%2B-dev_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/db4-util_4.8.30-buster1_amd64.deb
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/db4-doc_4.8.30-buster1_all.deb

# taken from:
# https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+sourcepub/236865/+listing-archive-extra

mkdir -p /root/org.src/db4 /root/src/db4
cd /root/org.src/db4
# find /root/org.src/db4 -mindepth 1 -type d -exec rm -rf {} \;
find /root/org.src/db4 -type f -empty | grep -i "gz\|dsc" | xargs rm -rf

fetch_url "https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/db4.8_4.8.30.orig.tar.gz"
fetch_url "https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/db4.8_4.8.30-buster1.dsc"
fetch_url "https://quickbuild.io/~luke-jr/+archive/ubuntu/bitcoinknots/+files/db4.8_4.8.30-buster1.debian.tar.gz"

dpkg-source --no-check --ignore-bad-version -x db4*.dsc


#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n --- wait for all background process...  [$bname] "
wait_backs_nopatt; wait
printf "\n\n --- wait finished... \n\n\n"


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src db4 \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude ".git" \
/root/org.src/db4/ /root/src/db4/

#--- last
#-------------------------------------------
# save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;