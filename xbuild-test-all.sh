#!/bin/bash



kill_current_scripts(){
	PID=$$
	ps auxw | grep -v grep | grep "xbuild-test-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	sleep 0.3
	ps auxw | grep -v grep | grep "xtest-all.sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1
	sleep 0.3
	ps auxw | grep -v grep | grep "dk-" | grep ".sh" | \
		awk '{print $2}' | grep -v "$PID" | xargs kill -9  >/dev/null 2>&1

	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
	sleep 0.3
	killall -9 ccache cc cc1 gcc g++  >/dev/null 2>&1
}

reset
kill_current_scripts
kill_current_scripts


rm -rf /var/log/dkbuild
mkdir -p /var/log/dkbuild

lxc-start -qn bus
lxc-start -qn eye
lxc-start -qn tbus
lxc-start -qn teye
sleep 1

lxc-attach -n bus -- /bin/bash /tb2/build/dk-prep-all.sh   2>&1 | \
	tee /var/log/dkbuild/dk-bus-prep.log >/dev/null 2>&1 &
lxc-attach -n eye -- /bin/bash /tb2/build/dk-prep-all.sh   2>&1 | \
	tee /var/log/dkbuild/dk-eye-prep.log >/dev/null 2>&1 &

wait
sleep 1
lxc-attach -n bus -- /bin/bash /tb2/build/dk-build-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-bus-build.log >/dev/null 2>&1 &
lxc-attach -n eye -- /bin/bash /tb2/build/dk-build-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-eye-build.log >/dev/null 2>&1 &

wait
sleep 1

/bin/bash /tb2/build/xrepo-rebuild.sh  2>&1 | tee /var/log/dkbuild/dk-argo-repo-rebuild.log
sleep 1

lxc-attach -n tbus -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | \
	tee /var/log/dkbuild/dk-tbus-init.log >/dev/null 2>&1 &
lxc-attach -n tbus -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-tbus-install.log >/dev/null 2>&1 &

lxc-attach -n teye -- /bin/bash /tb2/build/dk-init-debian.sh  2>&1 | \
	tee /var/log/dkbuild/dk-teye-init.log >/dev/null 2>&1 &
lxc-attach -n teye -- /bin/bash /tb2/build/dk-install-all.sh  2>&1 | \
	tee /var/log/dkbuild/dk-teye-install.log >/dev/null 2>&1 &

wait
sleep 1
reset
