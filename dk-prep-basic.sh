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


# bug
rm -rf /etc/apt/sources.list.d/mariadb.list.*
fix_apt_bookworm

#--- init
#-------------------------------------------
init_dkbuild
dig packages.sury.org @1.1.1.1

if [[ "${RELNAME}" = "bookworm" ]]; then
	sed -i 's/bookworm/bullseye/' /etc/apt/sources.list.d/php-sury.list
	sed -i 's/bookworm/bullseye/' /etc/apt/sources.list.d/keydb.list
fi



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

fix_apt_bookworm

dpkg --configure -a; \
aptold install -y
# apt autoremove --auto-remove --purge -fy \
#  2>&1 | grep --color "upgraded"

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
mkdir -p $CCACHE_DIR ~/.ccache
export CCACHE_DIR=/root/.ccache
echo \
'cache_dir = ~/.ccache
max_size = 100.0G
'>~/.ccache/ccache.conf

echo \
'cache_dir = ~/.ccache
max_size = 100.0G
'>/etc/ccache.conf


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
rm -rf mariadb_repo_setup /etc/apt/sources.list.d/mariadb.list*
curl -LO https://r.mariadb.com/downloads/mariadb_repo_setup
chmod +x mariadb_repo_setup
./mariadb_repo_setup --skip-os-eol-check --skip-eol-check --skip-verify


#--- keydb sources.list
echo "deb https://download.keydb.dev/open-source-dist $(lsb_release -sc) main" |\
tee /etc/apt/sources.list.d/keydb.list
wget -O /etc/apt/trusted.gpg.d/keydb.gpg https://download.keydb.dev/open-source-dist/keyring.gpg
fix_apt_bookworm
apt update
apt install keydb -fy

#--- php sources.list
echo \
"deb https://packages.sury.org/php/ ${RELNAME} main
deb-src https://packages.sury.org/php/ ${RELNAME} main
">/etc/apt/sources.list.d/php-sury.list


# fix apt sources
fix_apt_bookworm


aptold install -fy gnupg2
# apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys EFE0AC8B31B6305B &
# apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys B9316A7BC7917B12 &
# apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 4F4EA0AAE5267A6C &
# wait
aptold install -y wget curl; apt-key del 95BD4743; \
/usr/bin/curl -sS "https://packages.sury.org/php/apt.gpg" | gpg --dearmor \
> /etc/apt/trusted.gpg.d/sury-php.gpg

cd `mktemp -d`
aptold update
dpkg --configure -a
aptold install -yf locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
gnupg2 apt-utils tzdata curl ssh rsync libxmlrpc* \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"
echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen


# apt-key adv --fetch-keys http://repo.omd.my.id/trusted-keys \
# 	2>&1 | grep -iv "not changed"

aptold update; \
aptold full-upgrade --auto-remove --purge -fy


#--- just incase needed
#-------------------------------------------
dpkg --configure -a; \
aptold install -y linux-image-amd64 linux-headers-amd64 \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping" | grep --color=auto "Depends"

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
# echo "libzip4 libdb4.8 libdb4.8++ db4.8-util" >>  /tmp/deps.pkgs
echo "psmisc" >>  /tmp/deps.pkgs

apt-cache search libpcre | cut -d" " -f1 | \
grep -iv "dbg\|lisp\|ocaml\|posix0" >>  /tmp/deps.pkgs

touch ~/build.deps
cat ~/build.deps | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | \
sed "s/\s/\n/g" | sed '/^$/d' | sed "s/:any//g"  >>  /tmp/deps.pkgs

cat /tmp/deps.pkgs | sort -u | sort | tr "\n" " " | \
	xargs aptold install -y --ignore-missing \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"


aptold install -fy  --no-install-recommends --fix-missing \
-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
-o Dpkg::Options::="--force-overwrite" \
openssh-* nano devscripts build-essential debhelper git git-extras wget axel \
zlib1g-dev lua-zlib-dev libmemcached-dev libcurl4-openssl-dev \
apt-utils gnupg2 apt-utils tzdata curl \
debian-archive-keyring debian-keyring debian-ports-archive-keyring \
gnome-keyring mercurial-keyring \
python3-keyring \
debian-archive-keyring debian-ports-archive-keyring \
neurodebian-archive-keyring \
firmware-atheros firmware-linux firmware-linux-free firmware-linux-nonfree \
firmware-misc-nonfree firmware-realtek firmware-samsung firmware-iwlwifi firmware-intelwimax \
firmware-amd-graphics \
firmware-brcm80211 firmware-libertas firmware-misc-nonfree \
mlocate locate zip tar unzip rsync \
apt-utils binutils bsdmainutils bsdutils coreutils \
debconf-utils debianutils diffutils dnsutils dosfstools e2fsprogs findutils gettext-base \
gzip host hostname ifupdown iproute2 iptables iputils-arping iputils-ping iputils-tracepath \
login logrotate make mtools net-tools procps psutils sharutils \
util-linux libpcre3-dev libnet-ssleay-perl libssl-dev openssl ssl-cert \
tcpdump nmap locate zip tar unzip rsync memcached dnsutils \
openssl ssl-cert zip tar unzip wget axel links2 curl rblcheck bzip2 \
ca-certificates debian-archive-keyring openssh-server openssh-client build-essential nano \
fakeroot wget bzip2 curl git \
apt-utils binutils bridge-utils bsdmainutils bsdutils coreutils \
debconf-utils debianutils diffutils dnsutils findutils pciutils psutils usbutils \
locate zip tar unzip rsync apt-utils binutils \
bsdmainutils bsdutils coreutils debconf-utils debianutils diffutils dnsutils \
dosfstools e2fsprogs findutils gettext-base gzip host hostname ifupdown iproute2 iptables iputils-arping \
iputils-ping iputils-tracepath login logrotate make mtools net-tools procps \
psutils sharutils util-linux openssl ssl-cert nano \
mtr-tiny iptraf-ng nmap tcpdump openssh-server openssh-client nload \
dirmngr software-properties-common sudo build-essential dkms mysqltuner bc nload \
apt aptitude accountsservice mc p7zip-full htop \
libgsf-bin ffmpegthumbnailer tumbler libpoppler-glib8 tumbler-plugins-extra xfonts-75dpi \
pdftk qpdf libimage-exiftool-perl xvfb ghostscript \
optipng pngquant gifsicle jpegoptim \
wkhtmltopdf xbase-clients x11-xfs-utils x11-common xorg software-properties-common dirmngr xvfb \
dos2unix unrar-free p7zip-full vlan \
ipmitool ifenslave nfs-common \
ipset ipcalc rkhunter chkrootkit bridge-utils ifenslave nfs-common traceroute \
debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools \
iotop saidar byobu tmux fping lsb-release apt-transport-https ca-certificates apt-utils \
ipcalc ipset whois libterm-readkey-perl libterm-termkey-perl libdbd-mysql-perl linux-cpupower \
libterm-readkey-perl libdbd-mysql-perl libgeo-osm-tiles-perl lshw cron screen \
linux-headers-amd64 linux-image-amd64 udev ccache psmisc cheese \
ebtables arptables ipcalc ipset whois jq \
google-perftools libgoogle-perftools-dev libedit-dev devscripts \
libfl-dev flex bison libsodium* libldap2-dev libpcre2-dev zstd \
libboost-all-dev libboost-dev libboost-tools-dev \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"

apt-cache search libssl | grep -v "ocaml\|clojure" | \
cut -d" " -f1 | tr "\n" ' ' | xargs aptold install -fy \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"

apt install -fy --install-suggests --install-recommends \
build-essential fakeroot devscripts dh-exec dh-php dh-make dh-strip-nondeterminism \
dh-sysuser \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"

apt build-dep -fy build-essential fakeroot devscripts \
dh-exec dh-php dh-make dh-strip-nondeterminism dh-sysuser \
	2>&1 | grep -iv "cli\|newest\|picking\|reading\|building\|skipping"


#--- wait
#-------------------------------------------
bname=$(basename $0)
printf "\n\n --- wait for all background process...  [$bname] "
wait_jobs; wait
printf "\n\n --- wait finished... \n\n\n"



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