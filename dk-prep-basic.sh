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





#--- init
#-------------------------------------------
init_dkbuild
dig packages.sury.org @1.1.1.1


#--- clean up previous
#-------------------------------------------
systemctl daemon-reload; \
systemctl restart systemd-resolved.service; \
systemctl restart systemd-timesyncd.service; \
killall -9 apt; sleep 1; killall -9 apt; \
killall -9 apt; sleep 1; killall -9 apt; \
find /var/lib/apt/lists/ -type f -delete; \
find /var/cache/apt/ -type f -delete; \
rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
/etc/apt/preferences.d/00-revert-stable \
/var/cache/debconf/ /var/lib/apt/lists/* \
/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
mkdir -p /root/.local/share/nano/ /root/.config/procps/; \
dpkg --configure -a; \
apt autoclean; apt clean; apt update --allow-unauthenticated

dpkg --configure -a; \
aptold install -y
apt autoremove --auto-remove --purge -fy

if [[ -e /usr/local/sbin/aptold ]]; then
	aptold full-upgrade --auto-remove --purge --fix-missing \
		-o Dpkg::Options::="--force-overwrite" -fy
else
	apt full-upgrade --auto-remove --purge --fix-missing \
		-o Dpkg::Options::="--force-overwrite" -fy
fi


#--- preparing screen
#-------------------------------------------
aptold install -y screen
# screen -rR

cat <<\EOT >~/.screenrc
# Turn off the welcome message
startup_message off

# Disable visual bell
vbell off

# Set scrollback buffer to 1000000
defscrollback 1000000

# Customize the status line
hardstatus alwayslastline
hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %m-%d %{W}%c %{g}]'
EOT

#--- preparing ccache
#-------------------------------------------
aptold install -y ccache
export CCACHE_DIR=/tb2/tmp/ccache
mkdir -p $CCACHE_DIR ~/.ccache
echo \
'cache_dir = /tb2/tmp/ccache
max_size = 100.0G
'>~/.ccache/ccache.conf

echo \
'cache_dir = /tb2/tmp/ccache
max_size = 100.0G
'>/etc/ccache.conf

echo \
'cache_dir = /tb2/tmp/ccache
max_size = 100.0G
'>/tb2/tmp/ccache/ccache.conf


#--- preparing apt sources.list
#-------------------------------------------
ping 1.1.1.1 -c3

echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io
aptold install -y eatmydata

echo \
'Acquire::Queue-Mode "host";
Acquire::Languages "none";
Acquire::http { Pipeline-Depth "200"; };
Acquire::https { Verify-Peer false; };
'>/etc/apt/apt.conf.d/99translations


echo \
'APT::Get::AllowUnauthenticated "true";
Acquire::Check-Valid-Until "false";
Acquire::AllowDowngradeToInsecureRepositories "true";
Acquire::AllowInsecureRepositories "true";
APT::Ignore "gpg-pubkey";
Acquire::ForceIPv4 "true";

APT::Authentication::TrustCDROM "true";
Acquire::cdrom::mount "/media/cdrom";
Dir::Media::MountPath "/media/cdrom";

APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";

APT::Install-Recommends "false";
APT::Install-Suggests "false";

Binary::apt::APT::Keep-Downloaded-Packages "true";
APT::Keep-Downloaded-Packages "true";

Acquire::EnableSrvRecords "false";
APT::FTPArchive::AlwaysStat "false";

APT::Cache-Limit "100000000";
'>/etc/apt/apt.conf.d/98more

echo \
'export HISTFILESIZE=100000
export HISTSIZE=100000

#-- encodings
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
'>/etc/environment && source /etc/environment

export PATH=$PATH:/usr/sbin
timedatectl set-timezone Asia/Jakarta


rm -rf /etc/apt/sources.list.d/nginx-devel-ppa.list
rm -rf /etc/apt/sources.list.d/nginx-ppa-devel.list
rm -rf /etc/apt/sources.list.d/php-ppa.list
rm -rf /etc/apt/sources.list.d/keydb-ppa.list

# echo \
# '# deb http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu bionic main
# # deb-src http://ppa.launchpad.net/chris-lea/nginx-devel/ubuntu bionic main
# '>/etc/apt/sources.list.d/nginx-ppa-devel.list

# echo \
# '# deb http://ppa.launchpad.net/eqalpha/keydb-server/ubuntu bionic main
# # deb-src http://ppa.launchpad.net/eqalpha/keydb-server/ubuntu bionic main
# '>/etc/apt/sources.list.d/keydb-ppa.list



#--- mariadb sources.list
rm -rf mariadb_repo_setup
curl -LO https://r.mariadb.com/downloads/mariadb_repo_setup
chmod +x mariadb_repo_setup
./mariadb_repo_setup --skip-os-eol-check --skip-eol-check --skip-verify --os-type=debian


#--- keydb sources.list
echo "deb https://download.keydb.dev/open-source-dist $(lsb_release -sc) main" |\
tee /etc/apt/sources.list.d/keydb.list
wget -O /etc/apt/trusted.gpg.d/keydb.gpg https://download.keydb.dev/open-source-dist/keyring.gpg
apt update
apt install keydb

#--- php sources.list
echo \
"#-- deb https://packages.sury.org/php/ ${RELNAME} main
deb-src https://packages.sury.org/php/ ${RELNAME} main
">/etc/apt/sources.list.d/php-sury.list


aptold install -fy gnupg2
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys B9316A7BC7917B12
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
aptold install -y wget curl; apt-key del 95BD4743; \
/usr/bin/curl -sS "https://packages.sury.org/php/apt.gpg" | apt-key add -
# /usr/bin/wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg


cd `mktemp -d`
aptold update
dpkg --configure -a
aptold install -yf locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
gnupg2 apt-utils tzdata curl ssh rsync libxmlrpc* \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends"
echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen


# apt-key adv --fetch-keys http://repo.omd.my.id/trusted-keys \
# 	2>&1 | grep -iv "not changed"

aptold update; \
aptold full-upgrade --auto-remove --purge -fy

#--- just incase needed
#-------------------------------------------
dpkg --configure -a; \
aptold install -y linux-image-amd64 linux-headers-amd64 \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends"

#--- remove unneeded packages
#-------------------------------------------
dpkg --configure -a; \
apt purge -yf unattended-upgrades apparmor \
anacron msttcorefonts ttf-mscorefonts-installer needrestart redis*; \
rm -rf /var/log/unattended-upgrades /var/cache/apparmor /etc/apparmor.d

dpkg --configure -a; \
aptold install -fy
aptold install -y


#--- install build dependencies:
#--- clang, cmake, libgearman-dev
#-------------------------------------------
apt-cache search clang|grep 11|awk '{print $1}' > /tmp/deps.pkgs
echo "libclang-dev" >>  /tmp/deps.pkgs
echo "cmake cmake-extras extra-cmake-modules" >>  /tmp/deps.pkgs
echo "libgearman-dev" >>  /tmp/deps.pkgs
echo "d-shlibs help2man liblz4-dev" >>  /tmp/deps.pkgs

echo "libgraphicsmagick*dev" >>  /tmp/deps.pkgs
echo "libmagickwand-dev" >>  /tmp/deps.pkgs
echo "libzmq*-dev" >>  /tmp/deps.pkgs
echo "libvips*dev" >>  /tmp/deps.pkgs
echo "libssh2*dev" >>  /tmp/deps.pkgs
echo "libsmb*dev" >>  /tmp/deps.pkgs
echo "libsmbclient-dev" >>  /tmp/deps.pkgs
echo "librrd*dev" >>  /tmp/deps.pkgs
echo "libmcrypt*dev" >>  /tmp/deps.pkgs
echo "libgpgme*dev" >>  /tmp/deps.pkgs
echo "libmpdec*dev" >>  /tmp/deps.pkgs
echo "librabbitmq*dev" >>  /tmp/deps.pkgs
echo "libxml*dev" >>  /tmp/deps.pkgs
echo "dh-python libpython3*dev python3*dev rename" >>  /tmp/deps.pkgs
echo "hspell libdbus*dev libhunspell*dev libvoikko*dev" >>  /tmp/deps.pkgs
echo "liblzma*dev zlib1g*dev" >>  /tmp/deps.pkgs
echo "libzip4 libdb4.8 libdb4.8++ db4.8-util" >>  /tmp/deps.pkgs

apt-cache search libpcre | cut -d" " -f1 | \
grep -iv "dbg\|lisp\|ocaml\|posix0" >>  /tmp/deps.pkgs

touch ~/build.deps
cat ~/build.deps | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | \
sed "s/\s/\n/g" | sed '/^$/d' | sed "s/:any//g"  >>  /tmp/deps.pkgs

cat /tmp/deps.pkgs | sort -u | sort | tr "\n" " " | \
	xargs aptold install -y --ignore-missing \
	2>&1 | grep -iv "newest"


#--- wait
#-------------------------------------------
bname=$(basename $0)
printf "\n\n --- wait for all background process...  [$bname] "
wait_jobs; wait
printf "\n\n --- wait finished... \n\n\n"


#--- last
#-------------------------------------------
save_local_debs
aptold install -fy --auto-remove --purge \
	2>&1 | grep -iv "newest" | grep --color=auto "Depends"

rm -rf org.src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
rm -rf src/nginx/git-nginx/debian/modules/nchan/dev/nginx-pkg/nchan
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1
find /root/src -type d -iname ".git" -exec rm -rf {} \; >/dev/null 2>&1

printf "\n\n\n"
exit 0;