#!/bin/bash


upgrade_host() {
	ahost="$1"
	ssh $ahost "mkdir -p /tb2/build"

	rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
	/tb2/build/*sh root@$ahost:/tb2/build/

	rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
	/tb2/build/dk* root@$ahost:/tb2/build/

	ssh $ahost -- ln -sf /tb2/build/dk*sh /usr/local/sbin/
	ssh $ahost "chmod +x /usr/local/sbin/* /tb2/build/*sh"

	ssh $ahost -- /bin/bash /tb2/build/dk-bus-to-bul.sh
}

# upgrade_host "abdi"
# upgrade_host "awan"
# upgrade_host "atan"
# upgrade_host "agan"
# upgrade_host "aisgw"
# upgrade_host "argo"
upgrade_host "ava"
