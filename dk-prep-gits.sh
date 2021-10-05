#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh


get_update_new_github "steamboatid/nginx" "/root/org.src/nginx/git-nginx"
get_update_new_github "steamboatid/lua-resty-lrucache" "/root/org.src/lua-resty-lrucache/git-lua-resty-lrucache"
get_update_new_github "steamboatid/lua-resty-core" "/root/org.src/lua-resty-core/git-lua-resty-core"

get_update_new_github "steamboatid/phpredis" "/root/org.src/php8/git-phpredis"
get_update_new_github "steamboatid/keydb" "/root/org.src/keydb/git-keydb"
get_update_new_github "steamboatid/nutcracker" "/root/org.src/nutcracker/git-nutcracker"
get_update_new_github "steamboatid/libzip" "/root/org.src/libzip/git-libzip"
get_update_new_github "steamboatid/db4" "/root/org.src/db4/git-db4"


get_update_new_github "php/pecl-networking-gearman" "/root/org.src/git-gearman"
get_update_new_github "m6w6/ext-http" "/root/org.src/git-http"
rm -rf /root/org.src/git-raph
get_update_new_github "m6w6/ext-raphf" "/root/org.src/git-raphf"

#--- sync to src
#-------------------------------------------
printf "\n-- sync to src ALL \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
/root/org.src/ /root/src/


#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep --color=auto "Depends"