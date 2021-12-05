#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/dk* root@argo:/tb2/build/

nohup /bin/bash /tb2/build/zgit-auto.sh >/dev/null 2>&1 &
ssh argo "nohup chmod +x /usr/local/sbin/* /tb2/build/*sh 2>&1 >/dev/null &"

lxcs=(bus eye tbus teye)
for alxc in ${lxcs[@]}; do
	ssh argo -- /bin/bash /tb2/build/xrestart-lxc.sh -a "$alxc"
done


# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-pcre.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-all.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-fix-php-sources.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-all.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-core-php8.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-deps-php8.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-php8.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-check-log.sh

# ssh argo -- lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/zdev.sh

# ssh argo "/bin/bash /tb2/build/xbuild-test-all.sh >/var/log/dkbuild/build-test-all.log 2>&1 &"
