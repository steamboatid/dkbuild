#!/bin/bash

printf "\n GIT repos behinds: \n"

find /root/github/ -name ".git" | grep -v "_baks\|dkbuild" |
while read adir; do
	cd $adir/..
	BEHIND=$(git rev-list HEAD..origin --count 2>&1 || 1)
	BNAME=$(basename $PWD)
	printf "\n %20s \t %d " $BNAME $BEHIND
	if [[ $BEHIND -gt 0 ]]; then printf " --- do something ---"; fi
done

printf "\n\n"
