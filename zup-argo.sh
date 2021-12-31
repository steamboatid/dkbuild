#!/bin/bash


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh root@argo:/tb2/build/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/dk* root@argo:/tb2/build/

nohup /bin/bash /tb2/build/zgit-auto.sh >/dev/null 2>&1 &
ssh argo "nohup chmod +x /usr/local/sbin/* /tb2/build/*sh 2>&1 >/dev/null &"

ssh argo -- killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &
sleep 0.2
ssh argo -- killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &


printf "\n\n --- PREPARE LXCS --- \n\n"

lxcs=(bus eye tbus teye)
for alxc in ${lxcs[@]}; do
	ssh argo -- /bin/bash /tb2/build/xrestart-lxc.sh -a "$alxc" >/dev/null 2>&1 &
done

wait
printf "\n\n"

ssh argo "ln -sf /tb2/build/*sh /usr/local/sbin/"
