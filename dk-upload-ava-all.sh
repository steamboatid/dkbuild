#!/bin/bash

rsync -aHAXvztr --numeric-ids \
--exclude '*.o' --exclude '*.so' --exclude '*.log' --exclude '*stamp' \
-e "ssh -p22 -T -o Compression=no -x"  \
/var/lib/lxc/bus/rootfs/root/src/php8/* root@ava:/var/lib/lxc/bus/rootfs/root/src/php8/

ssh root@ava -p22 "chmod 755 /var/lib/lxc/bus/rootfs/root/src/php8/php8.0/dk*sh"
ssh root@ava -p22 "chmod 755 /var/lib/lxc/bus/rootfs/root/src/php8/dk*sh"
