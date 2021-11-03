#!/bin/bash

lxc-start -qn tbus
lxc-attach -n tbus -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | tee /var/log/dkbuild/dk-tbus-init.log
lxc-attach -n tbus -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | tee /var/log/dkbuild/dk-tbus-install.log
sleep 1

lxc-start -qn teye
lxc-attach -n teye -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | tee /var/log/dkbuild/dk-teye-init.log
lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | tee /var/log/dkbuild/dk-teye-install.log
