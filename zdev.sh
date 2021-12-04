#!/bin/bash

rm -rf /root/src/php/libsodium-1.0.18/dkbuild.log
rm -rf /root/src/php/libsodium-1.0.18/dkbuild.log

/bin/bash /tb2/build/dk-build-full.sh -d /root/src/php/libsodium-1.0.18

tail /root/src/php/libsodium-1.0.18/dkbuild.log
