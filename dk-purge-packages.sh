#!/bin/bash


source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm




printf "\n\n"

nowpkgs=$(dpkg -l|grep "^ii"|sed -r "s/\s+/ /g"|cut -d" " -f2|sed -r "s/\:amd64//g"|grep -v "linux\|ccache\|wget\|curl\|apt\|udev\|init\|system")

pkgs=""
for apkg in $nowpkgs; do
	exists=$(grep -i "$apkg" /tb2/build-devomd/basic.pkgs | wc -l)
	if [[ $exists -lt 1 ]]; then
		pkgs="${apkg} ${pkgs}"
		# printf " $apkg"
		apt purge --auto-remove --purge $apkg
	fi
done

printf "\n\n apt purge --auto-remove --purge ${pkgs} \n\n"