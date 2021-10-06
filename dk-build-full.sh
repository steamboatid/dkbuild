#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)


source /tb2/build/dk-build-0libs.sh


# reset default build flags
#-------------------------------------------
reset_build_flags
prepare_build_flags


echo $CFLAGS
echo $LDFLAGS
dpkg-buildflags --get CFLAGS
dpkg-buildflags --get LDFLAGS



if [ -e debian/rules ]; then
	sed -i -r "s/O2/O3/g" debian/rules
	sed -i -r "s/\-pedantic//g" debian/rules
	sed -i -r "s/\-Wall//g" debian/rules

	if [[ $(cat debian/rules | grep "dpkg\-shlibdeps" | wc -l) -gt 0 ]]; then
		if [[ $(cat debian/rules | grep "dpkg\-shlibdeps" | grep "warnings" | wc -l) -lt 1 ]]; then
			sed -i -r "s/dpkg-shlibdeps/dpkg-shlibdeps --warnings=0/g" debian/rules
		fi
	fi
	chmod +x debian/rules
fi

if [ -e "debian/libnginx-mod-http-ndk.nginx" ]; then
	chmod +x debian/libnginx-mod*nginx
	chmod -x debian/libnginx-mod-http-ndk.nginx
fi

rm -rf debian/.debhelper

#--- prepend verbose
dkverb=$(grep dkverbosev2 debian/rules | wc -l)
if [[ $dkverb -lt 1 ]]; then
	ATMP=$(mktemp)
	echo \
"#!/usr/bin/make -f
# -*- makefile -*-

#----------------- dkverbosev2
DH_VERBOSE=1
export DH_VERBOSE
export DH_OPTIONS
export DEB_BUILD_OPTIONS
export DEB_BUILD_PROFILES
export DPKG_EXPORT_BUILDFLAGS
export SHELL
export DEB_CFLAGS_MAINT_APPEND
export DEB_LDFLAGS_MAINT_APPEND
#----------------- end
">$ATMP
	cat debian/rules >> $ATMP
	cp $ATMP debian/rules
fi
chmod +x debian/rules

nproc2=$(( 2*`nproc` ))

# dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
export DH_VERBOSE=1; \
export DEB_BUILD_PROFILES="noudep nocheck noinsttest nojava nosql"; \
export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest parallel=${nproc2}"; \
time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
--no-lintian --no-tgz-check --no-sign -b -uc -us -d 2>&1 | tee dkbuild.log


# isdeps=$(cat dkbuild.log | grep -i "unmet build dependencies" | wc -l)
# if [[ $isdeps -gt 0 ]]; then
# 	cat dkbuild.log | grep -i "unmet build dependencies" | \
# 	sed "s/dpkg-checkbuilddeps: //g" |
# 	sed "s/error: //g" |
# 	sed "s/Unmet build dependencies: //g" | sed "s/|//g" >> ~/build.deps
# 	cat ~/build.deps
# fi

# isfail=$(tail -n100 dkbuild.log | grep -i failed | wc -l)
# if [[ $isfail -gt 0 ]]; then
# 	dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
# 	export DH_VERBOSE=1; \
# 	export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
# 	export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest parallel=${nproc2}"; \
# 	time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
# 	--no-lintian --no-tgz-check --no-sign -b -uc -us -D 2>&1 | tee dkbuild.log
# fi

# isflict=$(tail -n100 dkbuild.log | grep -i conflict | wc -l)
# isfail=$(tail -n100 dkbuild.log | grep -i failed | wc -l)
# if [[ $isfail -gt 0 ]] && [[ $isflict -gt 0 ]]; then
# 	dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
# 	export DH_VERBOSE=1; \
# 	export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
# 	export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest parallel=${nproc2}"; \
# 	time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
# 	--no-lintian --no-tgz-check --no-sign -b -uc -us -d 2>&1 | tee dkbuild.log
# fi

# if [[ $isdeps -gt 0 ]]; then
# 	printf "\n\n ${red}unmet build dependencies: ${end}"
# 	ATMP=$(mktemp)
# 	cat ~/build.deps | sed "s/) /)\n/g" | sed -E 's/\((.*)\)//g' | \
# 	sed "s/\s/\n/g" | sed '/^$/d' | sed "s/:any//g" | sort -u | sort > $ATMP
# 	mv $ATMP ~/build.deps
# 	cat ~/build.deps
# 	cat ~/build.deps | xargs aptold install -fy 2>&1 | grep --color=auto "Depends"
# 	printf "\n\n"
# 	exit 1;
# fi

# isflict=$(tail -n100 dkbuild.log | grep -i conflict | wc -l)
# isfail=$(tail -n100 dkbuild.log | grep -i failed | wc -l)
# if [[ $isfail -gt 0 ]] || [[ $isflict -gt 0 ]]; then
# 	exit 2;
# fi

# # if no error, then success
# isok=$(tail -n100 dkbuild.log | grep -i "binary\-only" | wc -l)
# if [[ $isok -gt 0 ]]; then
# 	exit 0;
# fi