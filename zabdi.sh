#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@abdi:/tb2/build/

/bin/bash /tb2/build/zgit-auto.sh

ssh abdi "chmod +x /usr/local/sbin/* /tb2/build/*sh 2>&1 >/dev/null; ln -s /tb2/build ~/b"

ssh abdi "/bin/bash /tb2/build/dk-docker-install.sh"
