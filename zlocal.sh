#!/bin/bash

source /tb2/build/dk-build-0libs.sh


printf "\n GIT repos behinds: \n"

for adir in $(find /root/github/ -name ".git" | grep -v "_baks\|dkbuild"); do
	cd $adir/..
	BEHIND=$(git rev-list HEAD..origin --count 2>&1 || 1)
	BNAME=$(basename $PWD)
	printf "\n %20s \t %s " $BNAME $BEHIND
	if [[ $BEHIND -gt 0 ]]; then printf " ---${red} do something ${end}---"; fi
done

printf "\n\n"
