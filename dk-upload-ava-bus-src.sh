#!/bin/bash

rsync -apHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
--include "debian/*" \
--exclude '*.deb' --exclude '*.gz' --exclude '*.tar' --exclude '*.zip' --exclude '*.xz' \
--exclude '*.dsc' --exclude '*.changes' \
--exclude '*.lo' --exclude '*.la' \
--exclude '*.o' --exclude '*.so' --exclude '*.log' --exclude '*stamp' \
--exclude 'tmp/*' --exclude '.git/*' \
--exclude '.pc/*' --exclude '.debhelper/*' \
-e "ssh -p22 -T -o Compression=no -x"  \
/var/lib/lxc/bus/rootfs/root/src/* root@ava:/var/lib/lxc/bus/rootfs/root/src/

ssh root@ava -p22 "chmod 755 /var/lib/lxc/bus/rootfs/root/src/nginx/nginx-1.19.3/dk*sh"
ssh root@ava -p22 "chmod 755 /var/lib/lxc/bus/rootfs/root/src/nginx/dk*sh"
