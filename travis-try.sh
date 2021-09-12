#!/bin/bash

cd /root/src/nginx/nginx-1.21.2

export NPROC2=$(( 2*`nproc` ))
export DEB_BUILD_PROFILES="noudep nocheck noinsttest"; \
export DEB_BUILD_OPTIONS="nocheck notest terse parallel=${NPROC2}"; \

export TRAVIS_BUILD_NUMBER=1.21.3
export TRAVIS_DEBIAN_NETWORK_ENABLED=true
export TRAVIS_DEBIAN_INCREMENT_VERSION_NUMBER=true
export TRAVIS_DEBIAN_LINTIAN=true
export TRAVIS_DEBIAN_DISTRIBUTION=buster

bash /tb2/build/travis.sh
