#!/bin/bash


MYFILE=$(which $0)
MYDIR=$(realpath $(dirname $MYFILE))
echo $MYDIR

/bin/bash $MYDIR/zup-devomd.sh


printf "\n\n --- stop lxc \n"
ssh devomd "lxc-stop -kqn bus; \
lxc-stop -kqn eye; \
lxc-stop -kqn tbus; \
lxc-stop -kqn teye"
sleep 0.5

printf "\n\n --- start lxc \n"
ssh devomd "lxc-start -qn bus; \
lxc-start -qn eye; \
lxc-start -qn tbus; \
lxc-start -qn teye"
sleep 0.5


printf "\n\n --- EXEC xbuild-test-all.sh "
ssh devomd "/bin/bash /tb2/build-devomd/xbuild-test-all.sh >/var/log/dkbuild/build-test-all.log 2>&1 &"
printf "\n\n --- done \n\n"
exit 0



# ssh devomd -- lxc-attach -n bus -- uptime
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-apt-upgrade.sh

# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-all.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-all.sh


# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/xrepo-rebuild.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-pcre.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-fix-php-sources.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-build-all.sh

# ssh devomd -- lxc-attach -n tbus -- /bin/bash /tb2/build-devomd/dk-install-all.sh
# ssh devomd -- lxc-attach -n tbus -- /bin/bash /tb2/build-devomd/dk-install-check.sh

# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-core-php8.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-deps-php8.sh

# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-build-php8.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-build-check-log.sh

# ssh devomd -- lxc-attach -n teye -- /bin/bash /tb2/build-devomd/dk-install-all.sh

# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-basic.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-basic.sh

# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/zdev.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/zdev.sh

# ssh devomd -- lxc-attach -n eye -- rm -rf /root/org.src/php /root/src/php

# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-config-gen.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-basic.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-core-php8.sh

# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-config-gen.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-basic.sh
# ssh devomd -- lxc-attach -n bus -- /bin/bash /tb2/build-devomd/dk-prep-core-php8.sh

# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-deps-nginx.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-deps-php8.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-gits.sh

# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-all.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-nginx.sh

# ssh devomd -- lxc-attach -n eye -- dig github.com
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-db4.sh

# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-prep-gits.sh
# ssh devomd -- lxc-attach -n eye -- /bin/bash /tb2/build-devomd/dk-build-nginx.sh
