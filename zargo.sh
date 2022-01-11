#!/bin/bash


MYFILE=$(which $0)
MYDIR=$(realpath $(dirname $MYFILE))
echo $MYDIR

/bin/bash $MYDIR/zup-argo.sh


# printf "\n\n --- EXEC xbuild-test-all.sh "
# ssh argo "/bin/bash /tb2/build/xbuild-test-all.sh >/var/log/dkbuild/build-test-all.log 2>&1 &"
# printf "\n\n --- done \n\n"
# exit 0


printf "\n\n --- stop lxc \n"
ssh argo "lxc-stop -kqn bus; \
lxc-stop -kqn eye; \
lxc-stop -kqn tbus; \
lxc-stop -kqn teye"

printf "\n\n --- start lxc \n"
ssh argo "lxc-start -qn bus; \
lxc-start -qn eye; \
lxc-start -qn tbus; \
lxc-start -qn teye"

ssh argo -- lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-all.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh


# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/xrepo-rebuild.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-pcre.sh
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
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-gits.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-nginx.sh

# ssh argo -- lxc-attach -n eye -- dig github.com
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-db4.sh

# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-gits.sh
# ssh argo -- lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-nginx.sh
