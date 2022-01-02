#!/bin/bash


MYFILE=$(which $0)
MYDIR=$(realpath $(dirname $MYFILE))
echo $MYDIR


/bin/bash $MYDIR/zup-argo.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-pcre.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-all.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-fix-php-sources.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-all.sh

# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-install-all.sh
# ssh argo -- lxc-attach -n tbus -- /bin/bash /tb2/build/dk-install-check.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-core-php8.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-deps-php8.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-php8.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-check-log.sh

# ssh argo -- lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-basic.sh

# ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/zdev.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/zdev.sh

# ssh argo -- lxc-attach -n eye -- rm -rf /root/org.src/php /root/src/php
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-config-gen.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-basic.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-core-php8.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-deps-nginx.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-deps-php8.sh

ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh


# printf "\n\n --- EXEC xbuild-test-all.sh "
# ssh argo "/bin/bash /tb2/build/xbuild-test-all.sh >/var/log/dkbuild/build-test-all.log 2>&1 &"

# wait
# printf "\n\n --- done \n\n"
