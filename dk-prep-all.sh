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


source /tb2/build-devomd/dk-build-1libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm


# read command parameter
#-------------------------------------------
# while getopts d:y:a: flag
while getopts h: flag
do
	case "${flag}" in
		h) alxc=${OPTARG};;
	esac
done

# if empty lxc, the use hostname
if [ -z "${alxc}" ]; then
	alxc="$HOSTNAME"
fi



# fix keydb perm, purge pendings, del locks
delete_apt_lock
fix_keydb_permission_problem
purge_pending_installs


# delete unpacked folders
mkdir -p /root/org.src /root/src
# find -L /root/org.src -mindepth 2 -maxdepth 2 -type d -exec rm -rf {} \;
# find -L /root/src -mindepth 2 -maxdepth 2 -type d -exec rm -rf {} \;

#  kill slow git
ps axww | grep -v grep | grep git | grep -iv "dk-prep-gits.sh" | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
ps axww | grep -v grep | grep git | grep -iv "dk-prep-gits.sh" | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1

# delete old php source
find /root/org.src/php -maxdepth 2 -name "php7*-7*" | xargs rm -rf
find /root/org.src/php -maxdepth 2 -name "php8*-8*" | xargs rm -rf

# prepare basic need: apt configs, sources list, etc
#-------------------------------------------
/bin/bash /tb2/build-devomd/dk-config-gen.sh -h "$alxc"
/bin/bash /tb2/build-devomd/dk-prep-basic.sh -h "$alxc"

nohup /bin/bash /tb2/build-devomd/dk-prep-gits.sh -h "$alxc" >/dev/null 2>&1 &

/bin/bash /tb2/build-devomd/dk-prep-deps-nginx.sh -h "$alxc"

/bin/bash /tb2/build-devomd/dk-prep-core-php8.sh -h "$alxc"
/bin/bash /tb2/build-devomd/dk-prep-deps-php8.sh -h "$alxc"
wait


# NGINX, source via git
#-------------------------------------------
aptold update
aptold full-upgrade --fix-missing -fy
aptold install -fy   --no-install-recommends \
devscripts build-essential lintian debhelper git git-extras wget axel \
diffutils patch patchutils quilt git dgit \
curl make gcc libpcre3 libpcre3-dev libpcre++-dev zlib1g-dev libbz2-dev libxslt1-dev libxml2-dev \
libgeoip-dev libgoogle-perftools-dev libperl-dev libssl-dev libcurl4-openssl-dev libgd-dev libgeoip-dev libssl-dev libpcre++-dev libxslt1-dev \
gcc libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev  libgd-dev google-perftools libgoogle-perftools-dev libperl-dev \
libatomic-ops-dev libgeoip1 libgeoip-dev libperl-dev \
libmaxminddb-dev libexpat-dev libldap2-dev libedit-dev openssl clang \
libpcre3 build-essential libpcre3 libpcre3-dev zlib1g-dev \
webp libwebp-dev libgeoip-dev lua-geoip-dev \
libluajit*dev luajit \
webp libwebp-dev libgeoip-dev lua-geoip-dev libsodium-dev meson \
liblua5*-dev libluajit-5*-dev libtexluajit-dev luajit uthash-dev \
libtexluajit*dev libluajit-*dev libxslt*-dev libxslt1.1 \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

aptold build-dep -fydu nginx lua-resty-core lua-resty-lrucache libpcre3 libsodium-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
aptold install -fy --fix-broken  --allow-downgrades --allow-change-held-packages \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
# save_local_debs


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/nginx /root/src/nginx \
/root/org.src/lua-resty-lrucache /root/src/lua-resty-lrucache \
/root/org.src/lua-resty-core /root/src/lua-resty-core

rm -rf /root/src/nginx/*deb \
/root/src/lua-resty-lrucache/*deb \
/root/src/lua-resty-core/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/nginx" "/root/org.src/nginx/git-nginx"
get_update_new_github "steamboatid/lua-resty-lrucache" "/root/org.src/lua-resty-lrucache/git-lua-resty-lrucache"
get_update_new_github "steamboatid/lua-resty-core" "/root/org.src/lua-resty-core/git-lua-resty-core"

mkdir -p /root/org.src/pcre /root/src/pcre
cd /root/org.src/pcre
ftmp=$(mktemp)
echo 'libpcre2-posix2' > $ftmp
apt-cache search pcre2 | grep -iv "rust\|elpa\|dbg\|posix" | cut -d" " -f1 >> $ftmp
apt-cache search pcre3 | grep -iv "rust\|elpa\|dbg\|posix" | cut -d" " -f1 >> $ftmp
cat $ftmp | tr "\n" " " | xargs aptold install -fy

apt_source_build_dep_from_file "$ftmp" "pcre"
# cat $ftmp | tr "\n" " " | xargs aptold build-dep -fy
# cat $ftmp | tr "\n" " " | xargs aptold source -y


#--- sync to src
#-------------------------------------------
printf "\n-- sync to src pcre \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/root/org.src/pcre/ /root/src/pcre/

#-- nginx source bug, nchan
rm -rf /root/src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan




# KEYDB, source via git
#-------------------------------------------
killall -9 keydb-server 2>&1 >/dev/null
aptold install -fy build-essential nasm autotools-dev autoconf libjemalloc-dev tcl tcl-dev \
uuid-dev libcurl4-openssl-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
aptold build-dep -fy keydb-server keydb-tools \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
aptold install -fy keydb-server keydb-tools \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

# fix keyd perm
fix_keydb_permission_problem

killall -9 keydb-server 2>&1 >/dev/null; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1; \
systemctl stop keydb-server; killall -9 keydb-server >/dev/null 2>&1
KEYCHECK=$(keydb-server /etc/keydb/keydb.conf --loglevel verbose --daemonize yes 2>&1 | grep -i "loaded" | wc -l)
if [[ $KEYCHECK -gt 0 ]]; then
	printf "\n\n keydb: OK \n\n"
else
	printf "\n\n keydb: FAILED INSTALL \n\n"
fi

killall -9 keydb-server 2>&1 >/dev/null
aptold install -y


#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/keydb /root/src/keydb
rm -rf /root/src/keydb/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/keydb" "/root/org.src/keydb/git-keydb" \
	2>&1 >/dev/null &



# NUTCRACKER, source via git
#-------------------------------------------
aptold install -fy build-essential fakeroot devscripts libyaml-dev libyaml-0* doxygen nutcracker \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
aptold build-dep -fy nutcracker \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/nutcracker /root/src/nutcracker
rm -rf /root/src/nutcracker/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/nutcracker" "/root/org.src/nutcracker/git-nutcracker" \
	2>&1 >/dev/null &



# libzip, source via git
#-------------------------------------------
aptold install -fy build-essential fakeroot devscripts liblzma*dev zlib1g*dev bzip2 libzip-dev libzip-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
aptold build-dep -fy libzip4 \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

#--- recreate dir, delete debs
#-------------------------------------------
mkdir -p /root/org.src/libzip /root/src/libzip
rm -rf /root/src/libzip/*deb

# get source if not exists via github
#-------------------------------------------
get_update_new_github "steamboatid/libzip" "/root/org.src/libzip/git-libzip" \
	2>&1 >/dev/null &


# sshfs, libfuse
#-------------------------------------------
mkdir -p /root/org.src/sshfs /root/src/sshfs
cd /root/org.src/sshfs
apt install fuse3 libfuse3* -fy
aptold source -y sshfs libfuse3-dev


# sshfs, libfuse
#-------------------------------------------
aptold install -fy clang bison flex


#--- wait
#-------------------------------------------
bname=$(basename $0)
# printf "\n\n --- wait for all background process...  [$bname] "
wait_backs_nopatt; wait
printf "\n\n --- wait finished... \n\n\n"



#--- final delete all *deb
#-------------------------------------------
find -L /root/src -type f -iname "*.deb" -delete

#--- final rsync org.src to src {WITHOUT delete}
#--- sync to src
#-------------------------------------------
printf "\n-- sync to src ALL \n"
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
--exclude ".git" \
/root/org.src/ /root/src/


#--- last
# save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

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