#!/bin/bash

mkdir -p /tb2/build-devomd
cd /tb2/build-devomd

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude '.git' \
--exclude 'buster-*/*' --exclude 'bullseye-*/*' \
--exclude '*.deb' \
root@devomd:/tb2/build-devomd/ /tb2/build-devomd

rm -rf build bullseye-* buster-* nbproject/
ls --color=auto -F /tb2/build-devomd

# create/update symlinks
ln -sf /tb2/build-devomd/*sh /usr/local/sbin/

# /tb2/build-devomd/dk-build-0libs.sh
# update aptold aptnew
[[ -f /tb2/build-devomd/dk-build-0libs.sh ]] && source /tb2/build-devomd/dk-build-0libs.sh
fix_relname_relver_bookworm
fix_apt_bookworm
