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
export ERRBASE=0


source /tb2/build/dk-build-0libs.sh



get_url_lastmod_date(){
	aurl="$1"
	gmt_date=$(curl -A "Aptly/1.0" -IL "$aurl" 2>&1 | grep -i "last-modified" | cut -d' ' -f2-)
	gmt_date=$(echo "$gmt_date")

	epoch_date=$(date -d "$gmt_date" "+%s" 2>&1)
	epoch_date=$(( $epoch_date ))

	printf "\n gmt:   $gmt_date "
	printf "\n epoch: $epoch_date "
}




printf "\n --- get sury: sources "
epoch_src=$(get_url_lastmod_date "https://packages.sury.org/php/dists/bullseye/main/source/Sources.gz" |\
	grep "epoch" | cut -d' ' -f3-)
epoch_src=$(( $epoch_src ))


printf "\n --- get sury: packages "
epoch_pkg=$(get_url_lastmod_date "https://packages.sury.org/php/dists/bullseye/main/binary-amd64/Packages.gz" |\
	grep "epoch" | cut -d' ' -f3-)
epoch_pkg=$(( $epoch_pkg ))


# set epoch_sury
epoch_sury=$(( $epoch_src ))
[[ $epoch_pkg -gt $epoch_sury ]] && epoch_pkg$(( $epoch_sury ))


printf "\n --- get phideb: packages "
epoch_phidep=$(get_url_lastmod_date "http://repo.aisits.id/phideb/dists/bullseye/main/binary-amd64/Packages.gz" |\
	grep "epoch" | cut -d' ' -f3-)
epoch_phidep=$(( $epoch_phidep ))

dt_sury=$(date -d "@$epoch_sury")
dt_phideb=$(date -d "@$epoch_phidep")

printf "\n"
printf "\n --- sury:   $dt_sury -- $epoch_sury "
printf "\n --- phideb: $dt_phideb -- $epoch_phidep "

if [[ $epoch_sury -le $epoch_phidep ]]; then
	printf "\n\n --- phideb updated already \n\n"
	exit 0
fi

epoch_delta=$(( $epoch_sury - $epoch_phidep ))
printf "\n\n --- DELTA:  ${green}$epoch_delta ${end}"


# if [[ $HOSTNAME == "argo" ]]; then
# 	printf "\n --- execute: xbuild-test-all.sh "
# 	/bin/bash /tb2/build/xbuild-test-all.sh
# fi

printf "\n\n --- done \n\n"
