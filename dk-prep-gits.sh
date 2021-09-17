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


get_update_new_git "steamboatid/nginx" "/root/src/nginx/git-nginx"
get_update_new_git "steamboatid/lua-resty-lrucache" "/root/src/lua-resty-lrucache/git-lua-resty-lrucache"
get_update_new_git "steamboatid/lua-resty-core" "/root/src/lua-resty-core/git-lua-resty-core"

get_update_new_git "steamboatid/phpredis" "/root/src/php8/git-phpredis"
get_update_new_git "steamboatid/keydb" "/root/src/keydb/git-keydb"
get_update_new_git "steamboatid/nutcracker" "/root/src/nutcracker/git-nutcracker"
