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

# check dns resolve
dig github.com | grep -v ";" | grep "IN"
dig github.com @192.168.1.1 | grep -v ";" | grep "IN"
dig github.com @1.1.1.1 | grep -v ";" | grep "IN"

#  kill slow git
ps axww | grep -v grep | grep git | grep -iv "dk-prep-gits.sh" | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
ps axww | grep -v grep | grep git | grep -iv "dk-prep-gits.sh" | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1


#-- taken from dk-prep-all.sh
get_update_new_github "steamboatid/nginx" "/root/org.src/nginx/git-nginx"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/lua-resty-lrucache" "/root/org.src/lua-resty-lrucache/git-lua-resty-lrucache"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/lua-resty-core" "/root/org.src/lua-resty-core/git-lua-resty-core"  >/dev/null 2>&1 &

#-- taken from dk-prep-all.sh
get_update_new_github "steamboatid/keydb" "/root/org.src/keydb/git-keydb"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/nutcracker" "/root/org.src/nutcracker/git-nutcracker"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/libzip" "/root/org.src/libzip/git-libzip"  >/dev/null 2>&1 &


#-- /root/org.src/git-redis is old folder
rm -rf /root/org.src/git-redis

get_update_new_github "steamboatid/phpredis" "/root/org.src/git-phpredis"  >/dev/null 2>&1 &
get_update_new_github "php/pecl-networking-gearman" "/root/org.src/git-gearman"  >/dev/null 2>&1 &


get_update_new_github "krakjoe/parallel" "/root/org.src/git-parallel"  >/dev/null 2>&1 &
get_update_new_github "rosmanov/pecl-eio" "/root/org.src/git-eio"  >/dev/null 2>&1 &
get_update_new_bitbucket "osmanov/pecl-ev.git" "/root/org.src/git-ev"  >/dev/null 2>&1 &

get_update_new_github "php/pecl-database-dbase" "/root/org.src/git-dbase"  >/dev/null 2>&1 &
get_update_new_github "php/pecl-caching-memcache" "/root/org.src/git-memcache"  >/dev/null 2>&1 &
get_update_new_github "php/pecl-math-stats" "/root/org.src/git-mathstats"  >/dev/null 2>&1 &
get_update_new_github "php/pecl-system-sync" "/root/org.src/git-sync"  >/dev/null 2>&1 &
get_update_new_github "laruence/taint" "/root/org.src/git-taint"  >/dev/null 2>&1 &
get_update_new_github "phpv8/php-v8" "/root/org.src/git-phpv8"  >/dev/null 2>&1 &

get_update_new_github "php/pecl-file_formats-lzf" "/root/org.src/git-lzf"  >/dev/null 2>&1 &
get_update_new_github "RubixML/Tensor" "/root/org.src/git-tensor"  >/dev/null 2>&1 &


# rm -rf /root/org.src/git-raph
get_update_new_github "m6w6/ext-raphf" "/root/org.src/git-raphf"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/ext-http" "/root/org.src/git-http"  >/dev/null 2>&1 &
get_update_new_github "php-memcached-dev/php-memcached" "/root/org.src/git-memcached"  >/dev/null 2>&1 &

# fuse,  https://github.com/libfuse/libfuse
# sshfs, https://github.com/libfuse/sshfs
get_update_new_github "steamboatid/libfuse" "/root/org.src/sshfs/git-fuse"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/sshfs" "/root/org.src/sshfs/git-sshfs"  >/dev/null 2>&1 &


# db4
get_update_new_github "steamboatid/db4" "/root/org.src/db4/git-db4"  >/dev/null 2>&1 &
get_update_new_github "steamboatid/debs-db4" "/root/org.src/db4/git-debs-db4"  >/dev/null 2>&1 &

# debug
# get_update_new_github "steamboatid/nginx" "/root/org.src/nginx/git-nginx"
# get_update_new_github "steamboatid/keydb" "/root/org.src/keydb/git-keydb"




#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n wait for all background process... [$bname] "
wait_backs_wpatt "dk-prep-gits.sh"
printf "\n\n --- wait finished... \n\n\n"


# fix raphf
if [[ -d /root/org.src/git-raphf ]]; then
	tdir=$PWD
	cd /root/org.src/git-raphf
	[[ -e php_raphf.h ]] && ln -sf php_raphf.h src/php_raphf.h
	[[ -e src/php_raphf_api.c ]] && ln -sf src/php_raphf_api.c php_raphf_api.c
	[[ -e src/php_raphf_api.h ]] && ln -sf src/php_raphf_api.h php_raphf_api.h
	rm -rf src/php_raphf_test.c php_raphf_test.c
	cd $tdir
fi

#--- sync to src
#-------------------------------------------
printf "\n-- sync to src ALL \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
--exclude ".git" \
/root/org.src/ /root/src/


#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;