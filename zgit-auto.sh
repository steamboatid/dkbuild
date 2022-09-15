#!/bin/bash


mkdir -p /tb2/root/github/dkbuild/ /tb2/root/github/baks.dkbuild/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/root/github/dkbuild/ /tb2/root/github/baks.dkbuild

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build-devomd/*sh /tb2/root/github/dkbuild/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build-devomd/dk* /tb2/root/github/dkbuild/

cd /tb2/root/github/dkbuild/

for afile in $(find -L /tb2/root/github/dkbuild/ -mindepth 1 -maxdepth 1 | sort -nr); do
	bname=$(basename $afile)
	if [[ "$bname" == ".git"* ]]; then continue; fi

	anum=$(find -L /tb2/build-devomd/ -mindepth 1 -maxdepth 1 -iname "${bname}" | wc -l)
	if [[ $anum -lt 1 ]]; then
		printf " $bname deleted \n"
		rm -rf /tb2/root/github/dkbuild/"$bname"
	fi
done

git add . >/dev/null 2>&1
git status -s

git gc --auto --aggressive --prune=now >/dev/null 2>&1
git gc >/dev/null 2>&1
git repack -ad >/dev/null 2>&1

git commit -a -m "autoupdate dkbuild `date +%F-%T`"
git push -u origin master --progress -v
