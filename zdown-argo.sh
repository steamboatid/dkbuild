#!/bin/bash

mkdir -p /tb2/build
cd /tb2/build

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
--exclude '.git' \
--exclude 'buster-*/*' --exclude 'bullseye-*/*' \
--exclude '*.deb' \
root@argo:/tb2/build/* /tb2/build/

rm -rf build bullseye-* buster-* nbproject/
ls /tb2/build
