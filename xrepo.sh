#!/bin/bash

# Directory structure
# 
# --phideb
#     |--dists
#          |-- buster
#          |-- bullseye
#     |--pool
#          |-- buster
#          |-- bullseye


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

create_release() {
	RELNAME=$1
	RELVER="0.1"

	cat << EOF
Origin: phideb of ${RELNAME}
Label: phideb
Suite: ${RELNAME}
Codename: ${RELNAME}
Version: ${RELVER}
Architectures: amd64
Components: main
Description: phideb custom packages for ${RELNAME}
Date: $(date -Ru)
EOF
	do_hash "MD5Sum" "md5sum"
	do_hash "SHA1" "sha1sum"
	do_hash "SHA256" "sha256sum"
}


mkdir -p /tb2/phideb/{dists,pool}/{buster,bullseye}
mkdir -p /tb2/phideb/dists/{buster,bullseye}/main/binary-amd64


rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/buster-all/ /tb2/phideb/pool/buster/

rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
/tb2/build/bullseye-all/ /tb2/phideb/pool/bullseye/


cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/buster/ > dists/buster/main/binary-amd64/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bullseye/ > dists/bullseye/main/binary-amd64/Packages


cd /tb2/phideb/dists/buster/main/binary-amd64
gzip -kf Packages
echo \
'Archive: stable
Origin: phideb
Label: phideb
Version: 0.1
Component: main
Architecture: amd64
'>Release

cd /tb2/phideb/dists/bullseye/main/binary-amd64
gzip -kf Packages
echo \
'Archive: stable
Origin: phideb
Label: phideb
Version: 0.1
Component: main
Architecture: amd64
'>Release


cd /tb2/phideb/dists/buster
create_release buster > Release

cd /tb2/phideb/dists/bullseye
create_release bullseye > Release


printf " chown folders \n"
find -L /w3repo/phideb -type d -group root  -exec chown webme:webme {} \;
find -L /w3repo/phideb -type d -user root  -exec chown webme:webme {} \;

printf " chown files \n"
find -L /w3repo/phideb -type f -group root  -exec chown webme:webme {} \;
find -L /w3repo/phideb -type f -user root  -exec chown webme:webme {} \;

/bin/bash /root/cf-clear.sh
