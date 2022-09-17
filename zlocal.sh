#!/bin/bash

source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm


printf "\n GIT repos behinds: \n"

for adir in $(find -L /root/github/ -name ".git" | grep -v "_baks\|dkbuild"); do
	cd $adir/..
	BEHIND=$(git rev-list HEAD..origin --count 2>&1 || 1)
	BNAME=$(basename $PWD)
	printf "\n %20s \t %s " $BNAME $BEHIND
	if [[ $BEHIND -gt 0 ]]; then printf " ---${red} do something ${end}---"; fi
done

printf "\n\n"
