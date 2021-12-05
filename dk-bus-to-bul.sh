#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(which lsb_release | wc -l) -lt 1 ]]; then
	apt update  \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"
	apt install -fy lsb-* \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"
fi

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh


remove_old_pkgs(){
	rm -rf /etc/resolvconf

	pwd=$(pwd)
	cd $(mktemp -d)

	aptold purge --auto-remove --purge -fy \
		ruby* node* libdvdcss* resolvconf apparmor* rsyslog* libdvdcss* nvidia* \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"

	rm -rf /var/lib/dpkg/info/rsyslog-mysql*
	dpkg --configure -D 777 rsyslog-mysql >/dev/null 2>&1

	aptold install -fy \
		2>&1 | grep -iv "selecting\|nable to locate\|not installed\|newest\|reading\|building\|stable CLI"

	aptold purge --auto-remove --purge -fy \
		ruby* node* rsyslog-* libdvdcss* resolvconf* \
		2>&1 | grep -iv "nable to locate\|not installed\|newest\|reading\|building\|stable CLI"

	cd -P $pwd
}

clean_apt_caches(){
	killall -9 apt aptold aptnew

	find /var/lib/apt/lists/ -type f -delete; \
	find /var/cache/apt/ -type f -delete; \
	rm -rf /var/cache/apt/* /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/ \
	/etc/apt/preferences.d/00-revert-stable \
	/var/cache/debconf/ /var/lib/apt/lists/* \
	/var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/debconf/; \
	mkdir -p /root/.local/share/nano/ /root/.config/procps/

	aptold autoclean >/dev/null 2>&1
	aptold clean >/dev/null 2>&1

	aptold update --allow-unauthenticated \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

	dpkg --configure -a \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

	remove_old_pkgs
}

upgrade_all(){
	aptold full-upgrade --auto-remove --purge --fix-missing -fy \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"
}

fix_bugs(){
	dpkg --configure -a
	[[ $(apt-mark showhold | wc -l) -gt 0 ]] && apt-mark unhold $(apt-mark showhold)
	sed -i '/keydb/d' /var/lib/dpkg/statoverride

	if [[ ! -e /usr/lib/x86_64-linux-gnu/libzip.so.4 ]]; then
		if [[ -e /usr/lib/x86_64-linux-gnu/libzip.so ]]; then
			ln -s /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/x86_64-linux-gnu/libzip.so.4
		elif [[ -e /usr/lib/x86_64-linux-gnu/libzip.so.5 ]]; then
			ln -s /usr/lib/x86_64-linux-gnu/libzip.so.5 /usr/lib/x86_64-linux-gnu/libzip.so.4
		fi
	fi

	[[ -e /usr/share/nginx/modules-available/mod-http-lua.conf ]] && \
		sed -i -r "s/^load/\#load/g" /usr/share/nginx/modules-available/mod-http-lua.conf
}

last_purge(){
	aptold full-upgrade -fy --auto-remove --purge \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

	aptold purge -yf --auto-remove wpasupplicant modemmanager unattended-upgrades apparmor \
	anacron msttcorefonts ttf-mscorefonts-installer needrestart php7* apache2* packagekit* \
	firewalld mercurial \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

	rm -rf /var/log/unattended-upgrades /var/cache/apparmor /etc/apparmor.d
	fix_bugs
}

install_phideb(){
	aptold update \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"

	aptold -o Dpkg::Options::="--force-overwrite" full-upgrade -fy
	aptold install -o Dpkg::Options::="--force-overwrite" -fy db4.8-util libdb4.8* \
		2>&1 | grep -iv "newest\|reading\|building\|stable CLI"
	fix_bugs
}

install_bpo_kernels(){
	MAJOR=$(apt-cache search linux | grep bpo | cut -d" " -f1 | \
		grep -iv "cloud\|dbg\|unsign\|lib\|\-rt\|pae\|686\|386\|support" | \
		cut -d"-" -f3 | sort -u | sort -r | head -n1)

	MINOR=$(apt-cache search linux | grep bpo | cut -d" " -f1 | \
		grep -iv "cloud\|dbg\|unsign\|lib\|\-rt\|pae\|686\|386\|support" | \
		grep "$MAJOR" | cut -d"-" -f4 | sort -u | sort -r | head -n1)

	apt-cache search linux | grep bpo | cut -d" " -f1 | \
		grep "$MAJOR" | grep "$MINOR" | \
		grep -iv "cloud\|dbg\|unsign\|lib\|\-rt\|pae\|686\|386\|support" | \
		grep -i "headers\|images" | \
		tr "\n" " " | xargs aptold install -fy \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

	aptold install -t bullseye-backports -fy  --no-install-recommends \
		firmware-atheros firmware-linux firmware-linux-free firmware-linux-nonfree \
		firmware-misc-nonfree firmware-realtek firmware-samsung firmware-iwlwifi firmware-intelwimax \
		firmware-amd-graphics \
		firmware-brcm80211 firmware-libertas firmware-misc-nonfree \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"
}

move_old_sources(){
	if [[ $(grep buster /etc/apt/sources.list.d/* -l | wc -l) -gt 0 ]]; then
		for afile in $(grep buster /etc/apt/sources.list.d/* -l); do
			bname=$(basename "$afile")
			mv "$afile" /root/"$bname"
		done
	fi
}


#--- move old sources to root
move_old_sources
locale-gen

#--- clean caches, remove old first
clean_apt_caches
remove_old_pkgs
upgrade_all


[[ ! -e /root/.bashrc.bak ]] && \
	cp /root/.bashrc /root/.bashrc.bak

#--- fixing bugs
fix_bugs
last_purge


cat <<\EOT >~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.

# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\h \[\033[00m\]\u:\[\033[01;34m\]\w\[\033[00m\]\$ '

case "$TERM" in
xterm*|rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\h \u: \w\a\]$PS1"
  ;;
*)
  ;;
esac


export LS_OPTIONS='--color=auto -F'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'

alias lxc-ls='/usr/bin/lxc-ls --fancy'
alias meld='/usr/bin/meld -na --diff'
alias links2='/usr/bin/links2 -ssl.certificates 0'
alias axel='/usr/bin/axel -k -n 9'
alias curl='/usr/bin/curl -k --no-buffer'
alias grep='/bin/grep --color'
alias wanip='dig @resolver1.opendns.com ANY myip.opendns.com +short'
alias ipwan='dig @resolver1.opendns.com ANY myip.opendns.com +short'
alias ssh='ssh -ttq'

#-- proxies
unset http_proxy
unset https_proxy
unset ftp_proxy
unset all_proxy

#-- GITs
unset GIT_TRACE_PACKET
unset GIT_TRACE
unset GIT_CURL_VERBOSE

#-- glx
unset LIBGL_ALWAYS_INDIRECT
unset LIBGL_DEBUG
unset LIBGL_ALWAYS_SOFTWARE

#-- encodings
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

EOT


source ~/.bashrc


sed -i "s/\#DNS=/DNS=172.16.251.1 10.0.2.1 10.0.3.1 192.168.8.1 192.168.0.1/g" /etc/systemd/resolved.conf
sed -i "s/\#FallbackDNS=/FallbackDNS=1.1.1.1 8.8.8.8/g" /etc/systemd/resolved.conf
sed -i "s/\#Cache=yes/Cache=yes/g" /etc/systemd/resolved.conf
cat /etc/systemd/resolved.conf | grep "DNS="

rm -rf /etc/resolv.conf; touch /etc/resolv.conf
cat <<\EOT >/etc/resolv.conf
domain aisdev.id
search aisdev.id ais.its.ac.id ais now loc lo

#--aisgw
nameserver 172.16.251.1
#--topgw
nameserver 172.16.0.1
nameserver 10.0.2.1
nameserver 10.0.3.1

#--nasdec-NS
nameserver 103.94.190.3
nameserver 103.94.190.6

#--ext
nameserver 1.1.1.1
nameserver 8.8.8.8
EOT


echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io

systemctl enable systemd-resolved.service
systemctl restart systemd-resolved.service


[[ ! -e /etc/apt/buster-sources.list ]] && \
	cp /etc/apt/sources.list /etc/apt/buster-sources.list


cat <<\EOT >/etc/apt/sources.list
deb http://repo.aisits.id/debian bullseye main contrib non-free
deb http://repo.aisits.id/debian bullseye-updates main contrib non-free
deb http://repo.aisits.id/debian bullseye-proposed-updates main contrib non-free
deb http://repo.aisits.id/debian bullseye-backports main contrib non-free
deb http://repo.aisits.id/debian-security bullseye-security main

# deb-src http://repo.aisits.id/debian bullseye main contrib non-free
# deb-src http://repo.aisits.id/debian bullseye-updates main contrib non-free
# deb-src http://repo.aisits.id/debian bullseye-proposed-updates main contrib non-free
# deb-src http://repo.aisits.id/debian bullseye-backports main contrib non-free
# deb-src http://repo.aisits.id/debian-security bullseye-security main

deb [arch=amd64] http://repo.aisits.id/mariadb/repo/10.6/debian bullseye main
deb [arch=amd64] http://repo.aisits.id/zabbix/5.5/debian bullseye main

deb http://repo.aisits.id/keydb-server/ubuntu bionic main

# deb http://repo.aisits.id/php bullseye main
# deb http://repo.aisits.id/nginx bullseye nginx
# deb http://repo.aisits.id/nginx-devel devel nginx

# deb http://repo.aisits.id/wine bullseye main
# deb http://repo.aisits.id/node16 bullseye main
# deb http://repo.aisits.id/virtualbox bullseye contrib

# deb http://repo.aisits.id/spotify stable non-free
# deb http://repo.aisits.id/audacity bionic main
# deb http://repo.aisits.id/skype stable main
# deb http://repo.aisits.id/multimedia bullseye main non-free

# deb http://repo.aisits.id/opera stable non-free
# deb http://repo.aisits.id/chrome stable main
# deb http://repo.aisits.id/vivaldi stable main

# deb http://repo.aisits.id/earth stable main
# deb http://repo.aisits.id/vscode stable main

EOT
#--- end of /etc/apt/sources.list

#--- add phideb
echo \
"deb [trusted=yes arch=amd64] http://repo.aisits.id/phideb ${RELNAME} main
#deb-src [trusted=yes arch=amd64] http://repo.aisits.id/phideb ${RELNAME} main
">/etc/apt/sources.list.d/phideb.list



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

APT::Cache-Limit "1000000000";
'>/etc/apt/apt.conf.d/98more

echo \
'export HISTFILESIZE=100000
export HISTSIZE=100000

#-- encodings
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
'>/etc/environment && cat /etc/environment

export PATH=$PATH:/usr/sbin
timedatectl set-timezone Asia/Jakarta


#--- fixing bugs
fix_bugs

aptold update \
	2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

aptold install -fy locales dialog apt-utils lsb-release apt-transport-https ca-certificates \
gnupg2 apt-utils tzdata curl rsync lsb-release eatmydata nano lsb-release \
	2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

echo 'en_US.UTF-8 UTF-8'>/etc/locale.gen && locale-gen

aptold install -yf gnupg2 apt-utils tzdata curl \
		2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

apt-key adv --fetch-keys http://repo.aisits.id/trusted-keys \
	2>&1 | grep --color "processed"

aptold full-upgrade --auto-remove --purge -fy \
	2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"


sleep 1
aptold install -fy openssh-* \
	2>&1 | grep -iv "not installed\|newest\|reading\|building\|stable CLI"

[[ $(grep -i "PermitRootLogin yes" /etc/ssh/sshd_config | wc -l) -lt 1 ]] && \
	sed -i "s/\#PermitRootLogin prohibit-password/PermitRootLogin yes\n#PermitRootLogin prohibit-password/g" /etc/ssh/sshd_config
cat /etc/ssh/sshd_config | grep -i permitroot
/etc/init.d/ssh restart


fix_bugs; sleep 1
aptold  install -fy \
--no-install-recommends --fix-missing \
apt-utils binutils bridge-utils bsdmainutils bsdutils coreutils debconf-utils \
debianutils diffutils dnsutils findutils iputils-arping iputils-ping \
iputils-tracepath pciutils psutils sharutils usbutils util-linux \
dosfstools mtools net-tools squashfs-tools \
accountsservice apt aptitude apt-transport-https axel bc bzip2 ca-certificates \
cron curl debootstrap dirmngr dos2unix fping gnupg2 gzip host hostname htop \
ifenslave ifupdown iotop ipcalc iproute2 ipset iptables iptraf-ng jpegoptim \
libdbd-mysql-perl libgeo-osm-tiles-perl libgsf-bin libmariadb3 \
libnet-ssleay-perl libpoppler-glib8 \
libterm-readkey-perl libterm-termkey-perl links2 locate login logrotate \
lsb-release lshw mc mlocate mtr-tiny nano nfs-common nload nmap \
openssh-client openssh-server openssl p7zip-full procps psmisc rsync screen \
socat software-properties-common sudo tar tcpdump traceroute tzdata unrar-free \
unzip wget zip lsb-release \
	2>&1 | grep -iv "newest\|reading\|building\|stable CLI"


fix_bugs; sleep 1
dpkg-query -Wf '${Package;-40}${Essential}\n' | grep yes | awk '{print $1}' > /tmp/ess
dpkg-query -Wf '${Package;-40}${Priority}\n' | grep -E "required" | awk '{print $1}' >> /tmp/ess
aptitude search ~E 2>&1 | awk '{print $2}' >> /tmp/ess
aptitude search ~prequired -F"%p" >> /tmp/ess
aptitude search ~pimportant -F"%p" >> /tmp/ess

cat /tmp/ess | sort -u | sort | \
grep -iv "libdb\|libsigc\|libssl\|i386\|gcc\|rsyslog" | tr '\n' ' ' | \
xargs aptold install --reinstall --fix-missing --install-suggests -fy \
	2>&1 | grep -iv "newest\|reading\|building\|stable CLI"


fix_bugs; sleep 1
last_purge

fix_bugs; sleep 1
install_phideb
install_bpo_kernels

sleep 1
printf "\n\n"
LSB_OS_RELEASE="" lsb_release -a
printf "\n"
uname -a

printf "\n\n --- done \n\n\n"