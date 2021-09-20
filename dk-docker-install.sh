#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then apt update; apt install -fy lsb-release; fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh

# gen config
#-------------------------------------------
/bin/bash /tb2/build/dk-config-gen.sh
/bin/bash /tb2/build/dk-init-debian.sh


# prepare install docker packages
#-------------------------------------------
if [[ $(dpkg -l | grep "^ii" | grep "containerd\.io" | wc -l) -lt 1 ]]; then
	aptnew install -fy apt-transport-https ca-certificates curl gnupg lsb-release
	curl -sS https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	curl -sS https://download.docker.com/linux/ubuntu/gpg | apt-key add -

	echo \
	"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable
	">/etc/apt/sources.list.d/docker.list

	apt update
	pkgs=(docker-ce docker-ce-cli containerd.io)
	install_old $pkgs
fi


# basic package
#-------------------------------------------
pkgs=(net-tools dnsutils)
install_old $pkgs

dhclient >/dev/null 2>&1
sleep 0.5
/etc/init.d/docker restart


# create Dockerfile
#-------------------------------------------
build_docker() {
	RELNAME=$1
	DOCBASE="${HOME}/docker-${RELNAME}"
	mkdir -p $DOCBASE
	cd $DOCBASE

	>Dockerfile
	echo \
"FROM debian:${RELNAME}

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8 UTF-8' LANGUAGE='en_US.UTF-8 UTF-8' LC_ALL='en_US.UTF-8 UTF-8'

WORKDIR /tb2
RUN mkdir -p /tb2; echo 'nameserver 1.1.1.1' > /etc/resolv.conf; cat /etc/resolv.conf; \
ip a; ip r; ping 1.1.1.1 -c3; ping yahoo.com -c3

RUN printf '\
deb http://repo.aisits.id/debian ${RELNAME} main contrib non-free \n\
'>/etc/apt/sources.list; \
apt update; apt install -fy locales apt-utils; dpkg-reconfigure locales; \
apt install -fy git net-tools dnsutils

ENV LANG='en_US.UTF-8 UTF-8' LANGUAGE='en_US.UTF-8 UTF-8' LC_ALL='en_US.UTF-8 UTF-8'
RUN git clone https://github.com/steamboatid/dkbuild /tb2/build &&\
/bin/bash /tb2/build/dk-init-debian.sh &&\
/bin/bash /tb2/build/zins.sh

">Dockerfile

	docker rm -f $(docker ps -aq)
	docker build --no-cache --network host --force-rm \
	-t busterdocker:latest -f ./Dockerfile .
}

build_docker "bullseye"