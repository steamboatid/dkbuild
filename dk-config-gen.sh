#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)



#--- check .bashrc
if [ `cat ~/.bashrc | grep alias | grep "find -L" | wc -l` -lt 1 ]; then
	echo "find alias not found"
	echo "alias find='find -L'" >> ~/.bashrc
fi

#--- colorfull shell
if [ `cat ~/.bashrc | grep "# alias ls" | wc -l` -gt 0 ]; then
	sed -i "s/\# export LS/export LS/g" ~/.bashrc
	sed -i "s/\# eval /eval /g" ~/.bashrc
	sed -i "s/\# alias ls/alias ls/g" ~/.bashrc
fi
source ~/.bashrc



#--- systemd
LINE='DefaultTimeoutStartSec=3s'
FILE='/etc/systemd/user.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultTimeoutStopSec=3s'
FILE='/etc/systemd/user.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultTasksMax=infinity'
FILE='/etc/systemd/user.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultLimitNOFILE=1048576'
FILE='/etc/systemd/user.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"



LINE='DefaultTimeoutStartSec=3s'
FILE='/etc/systemd/system.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultTimeoutStopSec=3s'
FILE='/etc/systemd/system.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultTasksMax=infinity'
FILE='/etc/systemd/system.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='DefaultLimitNOFILE=1048576'
FILE='/etc/systemd/system.conf'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"


#-- ssh
LINE='   StrictHostKeyChecking no'
FILE='/etc/ssh/ssh_config'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

LINE='   CheckHostIP no'
FILE='/etc/ssh/ssh_config'
grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"


#-- keydb server
STR1='TimeoutSec=0'
STR2='TimeoutSec=2s'
FILE='/lib/systemd/system/keydb-server.service'
[[ -f "$FILE" ]] && sed -i "s/$STR1/$STR2/g" "$FILE"


#-- https://unix.stackexchange.com/a/294050/238296
LINE='session required pam_limits.so'
FILE="/etc/pam.d/common-session"
[[ -f "$FILE" ]] && grep -qxF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"



#--- limits
ulimit -HSn 1048576
ulimit -HSu 1048576
ulimit -HSi 1048576
ulimit -HSl 1048576
ulimit -HSq 67108864

#--- apt tweaks
systemctl enable apt-daily.timer  >/dev/null 2>&1
systemctl enable apt-daily-upgrade.timer  >/dev/null 2>&1

echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io
apt install -fy eatmydata

