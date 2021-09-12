#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

bash /tb2/build/zgit-auto.sh

ssh argo "chmod +x /usr/local/sbin/* &"
ssh argo "lxc-start -n bus >/dev/null 2>&1 &"
ssh argo "lxc-start -n eye >/dev/null 2>&1 &"

# ssh argo -- lxc-attach -n bus -- "bash /tb2/build/travis-try.sh"

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-build-all.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-net.sh
