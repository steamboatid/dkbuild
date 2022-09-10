#!/bin/bash


# this script upload only to OMD production server
# not intended to be the development of omd repo


ssh omd "mkdir -p /tb2/build-devomd"

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build-devomd/*sh root@omd:/tb2/build-devomd/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build-devomd/dk* root@omd:/tb2/build-devomd/


ssh omd "nohup chmod +x /usr/local/sbin/* /tb2/build-devomd/*sh 2>&1 >/dev/null &"

ssh omd "killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &"
sleep 0.2
ssh omd "killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &"

# 
ssh omd "ln -sf /tb2/build-devomd/*sh /usr/local/sbin/"
