#!/bin/bash


# ssh argo "rm -rf /tb2/build/dk-prep*sh"

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/dk* root@argo:/tb2/build/

#-- db4 debs
# rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
# /var/lib/lxc/bus/rootfs/root/db4-debs/ argo:/tb2/build/buster-db4/

nohup /bin/bash /tb2/build/zgit-auto.sh >/dev/null 2>&1 &
# /bin/bash /tb2/build/zgit-auto.sh

ssh argo "nohup chmod +x /usr/local/sbin/* /tb2/build/*sh 2>&1 >/dev/null &"

ssh argo "lxc-start -qn tbus >/dev/null 2>&1 &"
ssh argo "lxc-start -qn teye >/dev/null 2>&1 &"
ssh argo "lxc-start -qn bus  >/dev/null 2>&1 &"
ssh argo "lxc-start -qn eye  >/dev/null 2>&1 &"

ssh argo -- lxca eye  -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca bus  -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca tbus -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca teye -- ln -sf /tb2/build/dk*sh /usr/local/sbin/

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-purge-packages.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net-php8.sh "php8.1"
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net-php8.sh "php8.0"
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-net-nginx.sh
ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-php8.sh "php8.1"
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-php8.sh "php8.0"
