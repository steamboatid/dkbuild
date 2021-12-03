#!/bin/bash



kill_current_scripts(){
	PID=$$
	ps auxw | grep -v grep | grep "xbuild-test-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	ps auxw | grep -v grep | grep "xtest-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	ps auxw | grep -v grep | grep "dk-" | grep ".sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1

	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
}

kill_current_scripts
kill_current_scripts


mkdir -p /var/log/dkbuild

lxc-start -qn tbus
lxc-attach -n tbus -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | tee /var/log/dkbuild/dk-tbus-init.log
lxc-attach -n tbus -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | tee /var/log/dkbuild/dk-tbus-install.log
sleep 1

lxc-start -qn teye
lxc-attach -n teye -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | tee /var/log/dkbuild/dk-teye-init.log
lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | tee /var/log/dkbuild/dk-teye-install.log
