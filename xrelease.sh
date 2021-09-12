#!/bin/sh
set -e

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

do_hash() {
	HASH_NAME=$1
	HASH_CMD=$2
	echo "${HASH_NAME}:"
	for f in $(find -type f); do
		f=$(echo $f | cut -c3-) # remove ./ prefix
		if [ "$f" = "Release" ]; then
			continue
		fi
		echo " $(${HASH_CMD} ${f}  | cut -d" " -f1) $(wc -c $f)"
	done
}

cat << EOF
Origin: phideb
Label: phideb
Suite: ${RELNAME}
Codename: ${RELNAME}
Version: ${RELVER}
Architectures: amd64
Components: main
Description: phideb custom packages
Date: $(date -Ru)
EOF
do_hash "MD5Sum" "md5sum"
do_hash "SHA1" "sha1sum"
do_hash "SHA256" "sha256sum"