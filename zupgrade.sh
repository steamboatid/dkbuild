#!/bin/bash


upgrade_host() {
	ahost="$1"
	ssh $ahost "mkdir -p /tb2/build-devomd"

	rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
	/tb2/build-devomd/*sh root@$ahost:/tb2/build-devomd/

	rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
	/tb2/build-devomd/dk* root@$ahost:/tb2/build-devomd/

	ssh $ahost -- ln -sf /tb2/build-devomd/dk*sh /usr/local/sbin/
	ssh $ahost "chmod +x /usr/local/sbin/* /tb2/build-devomd/*sh"

	ssh $ahost -- /bin/bash /tb2/build-devomd/dk-bus-to-bul.sh
}

upgrade_host "devomd"
