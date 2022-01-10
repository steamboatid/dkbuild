#!/bin/bash

mkdir -p /tb2/build
cd /tb2/build

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude '.git' \
--exclude 'buster-*/*' --exclude 'bullseye-*/*' \
--exclude '*.deb' \
root@argo:/tb2/build/* /tb2/build/

rm -rf build bullseye-* buster-* nbproject/
ls --color=auto -F /tb2/build

# create/update symlinks
ln -sf /tb2/build/*sh /usr/local/sbin/

# /tb2/build/dk-build-0libs.sh
# update aptold aptnew
[[ -f /tb2/build/dk-build-0libs.sh ]] && source /tb2/build/dk-build-0libs.sh
