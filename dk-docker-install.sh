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


# create Dockerfile
#-------------------------------------------
>Dockerfile
echo \
"FROM debian:${RELNAME}
RUN mkdir -p /tb2
RUN git clone https://github.com/steamboatid/dkbuild /tb2/build
RUN /bin/bash /tb2/build/dk-init-debian.sh
# RUN /bin/bash /tb2/build/zins.sh
">Dockerfile
