#!/bin/bash

# --repo
#     |--dists
#          |-- buster
#          |-- bullseye
#     |--pool
#          |-- buster
#          |-- bullseye

# 0. create keys (once)
# 1. merge + inspect sources
# 2. build sources
# 3. copy files
# 4. update Release, Release.gpg, InRelease, Packages (.xz,.bz2,.gz)
# 5. publish

mkdir -p /tb2/phideb/{dists,pool}/{buster,bullseye}

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/buster-all/ /tb2/phideb/pool/buster/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/bullseye-all/ /tb2/phideb/pool/bullseye/

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/buster/ > dists/buster/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bullseye/ > dists/bullseye/Packages

cd /tb2/phideb/dists/buster; \
gzip -kf Packages; apt-ftparchive release . > Release

cd /tb2/phideb/dists/bullseye; \
gzip -kf Packages; apt-ftparchive release . > Release

cd /tb2/phideb/dists; apt-ftparchive release . > Release
