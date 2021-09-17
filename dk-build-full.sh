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



#--- BUILD-ALL
AAA=`dpkg-buildflags --get CFLAGS`
GO2="-g -O2"
OPT3="-O3"
AAA="${AAA/$GO2/$OPT3}"
GO2="-O2"
OPT3="-O3"
CFLAGS="${AAA/$GO2/$OPT3}"
export CFLAGS
export DEB_CFLAGS_SET=$CFLAGS

LD=gcc
LDFLAGS="-Wl,-s ${CFLAGS} ${LDFLAGS}"
export LDFLAGS
export DEB_LDFLAGS_SET=$LDFLAGS

AR=gcc-ar
RANLIB=gcc-ranlib
echo $CFLAGS
echo $LDFLAGS

dpkg-buildflags --get CFLAGS
dpkg-buildflags --get LDFLAGS

export DEB_CFLAGS_STRIP="-g -O2"
export DEB_LDFLAGS_STRIP="-g -O2"


alias cd="cd -P"
export CCACHE_SLOPPINESS=include_file_mtime
export CC="ccache gcc"

mkdir -p /tb2/tmp/ccache /root/.ccache
rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times \
/root/.ccache/ /tb2/tmp/ccache/
export CCACHE_BASEDIR="/tb2/tmp/ccache"

chmod +x debian/rules

if [ -e "debian/libnginx-mod-http-ndk.nginx" ]; then
	chmod +x debian/libnginx-mod*nginx
	chmod -x debian/libnginx-mod-http-ndk.nginx
fi

rm -rf debian/.debhelper

nproc2=$(( 2*`nproc` ))

# dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest terse parallel=${nproc2}"; \
time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
--no-lintian --no-tgz-check --no-sign -b -uc -us -D 2>&1 | tee dkbuild.log

isfail=$(cat dkbuild.log | grep -i failed | wc -l)
if [[ $isfail -gt 0 ]];
	dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
	export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
	export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest terse parallel=${nproc2}"; \
	time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
	--no-lintian --no-tgz-check --no-sign -b -uc -us -D 2>&1 | tee dkbuild.log
fi

isflict=$(cat dkbuild.log | grep -i conflict | wc -l)
isfail=$(cat dkbuild.log | grep -i failed | wc -l)
if [[ $isfail -gt 0 ]] && [[ $isflict -gt 0 ]]; then
	dh clean; rm -rf debian/.debhelper; fakeroot debian/rules clean; \
	export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
	export DEB_BUILD_OPTIONS="nostrip noddebs nocheck notest terse parallel=${nproc2}"; \
	time debuild --preserve-envvar=CCACHE_DIR --prepend-path=/usr/lib/ccache \
	--no-lintian --no-tgz-check --no-sign -b -uc -us -d 2>&1 | tee dkbuild.log
fi

#was --no-lintian --no-tgz-check --no-sign -B -uc -us -D
