#!/bin/bash


source /tb2/build/dk-build-0libs.sh
printf "\n\n"

pkgs=""
for apkg in $(dpkg -l|grep "^ii"|sed -r "s/\s+/ /g"|cut -d" " -f2|sed -r "s/\:amd64//g"|grep -v linux); do
	exists=$(grep -i "$apkg" /tb2/build/basic.pkgs | wc -l)
	if [[ $exists -lt 1 ]]; then
		pkgs="${apkg} ${pkgs}"
		printf " $apkg"
	fi
done

printf "\n\n apt purge --auto-remove --purge ${pkgs} \n\n"