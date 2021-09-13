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
mkdir -p /tb2/phideb/dists/{buster,bullseye}/main/binary-amd64


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/buster-all/ /tb2/phideb/pool/buster/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/bullseye-all/ /tb2/phideb/pool/bullseye/


cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/buster/ > dists/buster/main/binary-amd64/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bullseye/ > dists/bullseye/main/binary-amd64/Packages


cd /tb2/phideb/dists/buster/main/binary-amd64
gzip -kf Packages
echo \
'Archive: stable
Origin: phideb
Label: phideb
Version: 0.1
Component: main
Architecture: amd64
'>Release

cd /tb2/phideb/dists/bullseye/main/binary-amd64
gzip -kf Packages
echo \
'Archive: stable
Origin: phideb
Label: phideb
Version: 0.1
Component: main
Architecture: amd64
'>Release


cd /tb2/phideb/dists/buster
/bin/bash /tb2/build/xrelease.sh buster > Release

cd /tb2/phideb/dists/bullseye
/bin/bash /tb2/build/xrelease.sh bullseye > Release
