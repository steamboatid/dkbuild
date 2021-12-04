#!/bin/bash

# example
alxc="teye"

mkdir -p /root/lxc-conf
cp /var/lib/lxc/$alxc/config /root/lxc-conf/$alxc.config -fv

lxc-destroy -fsn $alxc

# actual create
lxc-create -n $alxc -t download \
-- --dist debian --release bullseye --arch amd64 \
--force-cache --no-validate --server images.linuxcontainers.org \
--keyserver hkp://p80.pool.sks-keyservers.net:80

# copy config file back
mv /var/lib/lxc/$alxc/config /var/lib/lxc/$alxc/config.old
cp /root/lxc-conf/$alxc.config /var/lib/lxc/$alxc/config -fv

lxc-start -n $alxc
