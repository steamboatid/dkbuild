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
		curl -L --insecure --ipv4 -A "Aptly/1.0" "$aurl" 2>&1 >$cache_file
	fi
	# printf "\n curl -L --insecure --ipv4 -A Aptly/1.0 $aurl \n -- $cache_file \n"

	cat $cache_file
}

get_commit_lastdate(){
	agit="$1"

	#git_url = https://api.github.com/repos/openresty/lua-resty-lrucache/commits?page=1&per_page=1

	aurl="https://api.github.com/repos/$agit/commits?page=1&per_page=1"

	# gmt_date=$(get_curl "$aurl" | python3 -m json.tool |\
	# grep -i "date" | sed -r 's/\"//g' | sort -u | head -n1 | sed -r 's/\s+/ /g' |\
	# cut -d' ' -f3-)
	gmt_date=$(get_curl "$aurl" | jq -r '.[0].commit.committer.date')
	gmt_date=$(echo "$gmt_date")

	epoch_date=$(TZ=GMT date -d "$gmt_date" "+%s" 2>&1)
	epoch_date=$(( $epoch_date ))

	printf "\n gmt:   $gmt_date "
	printf "\n epoch: $epoch_date "

	dt_gmt=$(TZ=GMT date -d "@$epoch_date")
	printf "\n gmt2:  $dt_gmt "
}

get_compare_commit_lastdate(){
	ext_git="$1"
	int_git="$2"
	counter="$3"

	# get_commit_lastdate $ext_git
	# get_commit_lastdate $int_git

	epoch_ext=$(get_commit_lastdate $ext_git | grep "epoch" | cut -d' ' -f3-)
	epoch_ext=$(( $epoch_ext ))

	epoch_int=$(get_commit_lastdate $int_git | grep "epoch" | cut -d' ' -f3-)
	epoch_int=$(( $epoch_int ))

	epoch_delta=0
	if [[ $epoch_ext -gt $epoch_int ]]; then
		epoch_delta=$(( $epoch_ext - $epoch_int ))
	fi

	printf "\n --- epoch_int: $epoch_int "
	printf "\n --- epoch_ext: $epoch_ext "
	printf "\n --- delta: $epoch_delta "
}


populate_cache_urls(){
	printf "\n --- populate url caches "

	counter=0
	while IFS= read -r aline || [[ -n "$aline" ]]; do
		[[ -z "$aline" ]] && continue;

		counter=$(( counter+1 ))
		aline=$(printf "$aline" | sed -r 's/\s+/ /g')

		ext_git=$(printf "$aline" | cut -d' ' -f1)
		int_git=$(printf "$aline" | cut -d' ' -f2)
		# printf "\n --- $ext_git --- $int_git -- $counter"

		get_compare_commit_lastdate "$ext_git" "$int_git" "$counter" >/dev/null 2>&1 &
	done < "/tmp/gits-list.txt"

	printf " ins="
	wait_jobs
}



cat << EOF > /tmp/gits-list.txt
nginx/nginx   steamboatid/nginx
m6w6/ext-http   steamboatid/ext-http
X4BNet/nginx_accept_language_module   steamboatid/nginx_accept_language_module

openresty/lua-resty-lrucache   steamboatid/lua-resty-lrucache
openresty/lua-resty-core   steamboatid/lua-resty-core

twitter/twemproxy   steamboatid/nutcracker

libfuse/sshfs   steamboatid/sshfs
libfuse/libfuse   steamboatid/libfuse
nih-at/libzip   steamboatid/libzip

EQ-Alpha/KeyDB   steamboatid/keydb
phpredis/phpredis   steamboatid/phpredis

EOF


# install jq
apt install -fy jq >/dev/null 2>&1

# delete cache
rm -rf /tmp/cache-curl*


# populate caches
populate_cache_urls
wait_jobs
printf "\n\n"
# exit 0;


sum_delta=0
counter=0
while IFS= read -r aline || [[ -n "$aline" ]]; do
	[[ -z "$aline" ]] && continue;

	counter=$(( counter+1 ))

	aline=$(printf "$aline" | sed -r 's/\s+/ /g')
	ext_git=$(printf "$aline" | cut -d' ' -f1)
	int_git=$(printf "$aline" | cut -d' ' -f2)

	# printf "\n\n -- comparing: $ext_git -- $int_git"
	printf "\n"

	# get_compare_commit_lastdate "$ext_git" "$int_git"
	commit_dates=$(get_compare_commit_lastdate "$ext_git" "$int_git" 2>&1)

	epoch_delta=$(printf "$commit_dates" | grep 'delta' | cut -d':' -f2-)
	epoch_delta=$(( $epoch_delta ))

	epoch_int=$(printf "$commit_dates" | grep 'int' | cut -d':' -f2-)
	epoch_int=$(( $epoch_int ))
	date_int=$(TZ=GMT date -d "@$epoch_int")
	printf "\n --- $int_git: \t$date_int -- $epoch_int "

	epoch_ext=$(printf "$commit_dates" | grep 'ext' | cut -d':' -f2-)
	epoch_ext=$(( $epoch_ext ))
	date_ext=$(TZ=GMT date -d "@$epoch_ext")
	printf "\n --- $ext_git: \t$date_ext -- $epoch_ext "

	if [[ $epoch_delta -gt 0 ]]; then
		sum_delta=$(( $sum_delta + $epoch_delta ))
		printf "\n --- delta: ${green}$epoch_delta ${end} --- idx=$counter"
	else
		printf "\n --- delta: $epoch_delta --- idx=$counter"
	fi
	# exit 0

done < "/tmp/gits-list.txt"


printf "\n\n -- SUM delta: ${green}$sum_delta ${end}"


if [[ $sum_delta -gt 0 ]]; then
	format="+%H:%M:%S"
	if [[ $sum_delta -lt 86400 ]]; then
		format="+%H:%M:%S"
	elif [[ $sum_delta -gt 86400 ]] && [[ $sum_delta -lt 2592000 ]]; then
		format="+%d days  %H:%M:%S"
	else
		format="+%m months %d days  %H:%M:%S"
	fi
	formatted=$(date -u "$format" -d "@$(printf "%010d\n" $sum_delta)" | sed "s|^00:||")
	printf " -- ${cyn} $formatted ${end} \n\n\n"

	# /bin/bash /tb2/build-devomd/xbuild-test-all.sh 2>&1 | tee /var/log/dkbuild/build-test-all.log
fi

printf "\n\n --- done \n\n"
