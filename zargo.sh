#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

nohup /bin/bash /tb2/build/zgit-auto.sh >/dev/null 2>&1 &

ssh argo "chmod +x /usr/local/sbin/* &"

ssh argo "lxc-start -n tus >/dev/null 2>&1 &"
ssh argo "lxc-start -n tes >/dev/null 2>&1 &"
ssh argo "lxc-start -n bus >/dev/null 2>&1 &"
ssh argo "lxc-start -n eye >/dev/null 2>&1 &"

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-build-all.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-net.sh

# ssh argo -- lxc-attach -n tus -- /bin/bash /tb2/build/xrepo.sh
# ssh argo -- /bin/bash /tb2/build/xlast.sh
# ssh argo -- /bin/bash /root/cf-clear.sh

# ssh argo -- lxc-attach -n tes -- /bin/bash /tb2/build/zins.sh
