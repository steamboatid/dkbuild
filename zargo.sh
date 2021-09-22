#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

# nohup /bin/bash /tb2/build/zgit-auto.sh >/dev/null 2>&1 &
/bin/bash /tb2/build/zgit-auto.sh

ssh argo "nohup chmod +x /usr/local/sbin/* /tb2/build/*sh 2>&1 >/dev/null &"

ssh argo "lxc-start -n tbus >/dev/null 2>&1 &"
ssh argo "lxc-start -n teye >/dev/null 2>&1 &"
ssh argo "lxc-start -n bus >/dev/null 2>&1 &"
ssh argo "lxc-start -n eye >/dev/null 2>&1 &"

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-purge-packages.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-check-log.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-check-log.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-net.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-build-all.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-net.sh

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/xrepo.sh
# ssh argo -- /bin/bash /tb2/build/xlast.sh
# ssh argo -- /bin/bash /root/cf-clear.sh

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-docker-install.sh

# ssh argo "lxc-del aaa; lxc-new aaa buster"

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-init-debian.sh
# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/zins.sh
# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-docker-install.sh

# ssh argo "/bin/bash /tb2/build/dk-lxc-exec.sh -n aaa -d buster"

ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/1-php.sh

