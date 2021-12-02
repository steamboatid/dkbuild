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

lxcs=(bus eye tbus teye)
for alxc in ${lxcs[@]}; do
	ssh argo -- lxc-start -qn $alxc
	ssh argo -- lxca $alxc -- dhclient eth0 >/dev/null 2>&1 &
	ssh argo -- lxca $alxc -- rm -rf /usr/local/sbin/dk*sh
	ssh argo -- lxca $alxc -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
done

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-pcre.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-fix-php-sources.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-php8.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-check-log.sh
ssh argo -- lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh

# ssh argo "/bin/bash /tb2/build/xbuild-test-all.sh >/var/log/dkbuild/build-test-all.log 2>&1 &"