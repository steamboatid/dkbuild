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
export ERRBASE=0


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relname_bookworm
fix_apt_bookworm



get_md5(){
	echo "$1" | md5sum | awk '{print $1}'
}

get_curl(){
	aurl="$1"
	cache_file=$(get_md5 "$aurl")
	cache_file="/tmp/cache-curl-$cache_file.txt"

	docurl=0
	if [[ ! -f "$cache_file" ]]; then
		docurl=1
	else
		date_file=$(date -r "$cache_file" "+%s")
		date_now=$(date "+%s")

		date_file=$(( $date_file ))
		date_now=$(( $date_now ))
		date_delta=$(( $date_now - $date_file ))

		if [[ $date_delta -gt 3600 ]]; then
			docurl=1
		fi
	fi

	if [[ $docurl -gt 0 ]]; then
		curl -IL --insecure --ipv4 -A "Aptly/1.0" "$aurl" 2>&1 >$cache_file
	fi

	cat $cache_file
}




get_url_lastmod_date(){
	aurl="$1"
	gmt_date=$(get_curl "$aurl" 2>&1 | grep -i "last-modified" | cut -d' ' -f2-)
	gmt_date=$(echo "$gmt_date")

	epoch_date=$(date -d "$gmt_date" "+%s" 2>&1)
	epoch_date=$(( $epoch_date ))

	printf "\n gmt:   $gmt_date "
	printf "\n epoch: $epoch_date "

	dt_gmt=$(TZ=GMT date -d "@$epoch_date")
	printf "\n gmt2:  $dt_gmt "
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
[[ $epoch_pkg -gt $epoch_sury ]] && epoch_pkg=$(( $epoch_sury ))


printf "\n --- get phideb: packages "
epoch_phidep=$(get_url_lastmod_date "http://repo.omd.id/phideb/dists/bullseye/main/binary-amd64/Packages.gz" |\
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

if [[ $epoch_delta -gt 0 ]]; then
	format="+%H:%M:%S"
	if [[ $sum_delta -lt 86400 ]]; then
		format="+%H:%M:%S"
	elif [[ $epoch_delta -gt 86400 ]] && [[ $epoch_delta -lt 2592000 ]]; then
		format="+%d days  %H:%M:%S"
	else
		format="+%m months %d days  %H:%M:%S"
	fi
	formatted=$(date -u "$format" -d "@$(printf "%010d\n" $epoch_delta)" | sed "s|^00:||")
	printf " -- ${cyn} $formatted ${end} \n\n\n"

	/bin/bash /tb2/build-devomd/xbuild-test-all.sh 2>&1 | tee /var/log/dkbuild/build-test-all.log
fi


# if [[ $HOSTNAME == "devomd" ]]; then
# 	printf "\n --- execute: xbuild-test-all.sh "
# 	/bin/bash /tb2/build-devomd/xbuild-test-all.sh
# fi

printf "\n\n --- done \n\n"
