#!/bin/bash


prepare_lxc(){
	printf "\n\n --- PREPARE LXCS --- \n\n"

	lxcs=(bus eye tbus teye)
	for alxc in ${lxcs[@]}; do
		ssh devomd -- /bin/bash /tb2/build-devomd/xrestart-lxc.sh -a "$alxc" >/dev/null 2>&1 &
	done

	wait
	printf "\n\n"
}



ssh devomd "mkdir -p /tb2/build-devomd"

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build-devomd/*sh root@devomd:/tb2/build-devomd/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build-devomd/dk* root@devomd:/tb2/build-devomd/

nohup /bin/bash /tb2/build-devomd/zgit-auto.sh >/dev/null 2>&1 &
ssh devomd "nohup chmod +x /usr/local/sbin/* /tb2/build-devomd/*sh 2>&1 >/dev/null &"

ssh devomd -- killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &
sleep 0.2
ssh devomd -- killall -9 cc ccache cc1 gcc g++  >/dev/null 2>&1 &


# prepare_lxc
ssh devomd "ln -sf /tb2/build-devomd/*sh /usr/local/sbin/"
