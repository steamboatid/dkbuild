#!/bin/bash


mkdir -p /tb2/root/github/dkbuild/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh /tb2/root/github/dkbuild/

cd /tb2/root/github/dkbuild/

git add . >/dev/null 2>&1
git status -s

git gc --auto --aggressive --prune=now >/dev/null 2>&1
git gc >/dev/null 2>&1
git repack -ad >/dev/null 2>&1

git commit -a -m "autoupdate dkbuild `date +%F-%T`"
# git push -u origin master --progress -v
