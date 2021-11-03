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
ssh argo "lxc-start -qn bus >/dev/null 2>&1 &"
ssh argo "lxc-start -qn eye >/dev/null 2>&1 &"

ssh argo -- lxca eye  -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca bus  -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca tbus -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
ssh argo -- lxca teye -- ln -sf /tb2/build/dk*sh /usr/local/sbin/

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

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-gits.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-all.sh


# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/xrepo.sh
# ssh argo -- /bin/bash /tb2/build/xrepo-rebuild.sh
# ssh argo -- /bin/bash /root/cf-clear.sh

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-docker-install.sh

# ssh argo "lxc-del aaa; lxc-new aaa buster"

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-init-debian.sh
# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/zins.sh
# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-docker-install.sh

# ssh argo "/bin/bash /tb2/build/dk-lxc-exec.sh -n aaa -d buster"

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-db4.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/5-php.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-gits.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-db4.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/5-php.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/3-php.sh

# ssh argo "nohup lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-all.sh >/dev/null 2>&1 &"
# ssh argo "nohup lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-all.sh >/dev/null 2>&1 &"

# ssh argo "nohup /bin/bash /tb2/build/xbuild-test-all.sh >/dev/null 2>&1 &"


# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-gits.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/6-php.sh


# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh
ssh argo -- lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh
