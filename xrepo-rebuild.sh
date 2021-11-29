#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)
export PKGDATE=$(date -Ru)
export VALIDDATE=$(date -d'+3 years' -Ru)


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
Valid-Until: $(date -d'+3 years' -Ru)
EOF
	do_hash "MD5Sum" "md5sum"
	do_hash "SHA1" "sha1sum"
	do_hash "SHA256" "sha256sum"
}


mkdir -p /tb2/phideb/{dists,pool}/{buster,bullseye}
mkdir -p /tb2/phideb/dists/{buster,bullseye}/main/binary-amd64

# delete old files
find /tb2/phideb -type f -delete

folders=(php nginx nutcracker lua-resty-core lua-resty-lrucache keydb pcre libzip db4 sshfs)
for afolder in "${folders[@]}"; do
	printf " copy folder: $afolder \n"

	# buster
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
	/tb2/build/buster-$afolder /tb2/phideb/pool/buster/

	# bullseye
	rsync -aHAXztr --numeric-ids --modify-window 5 --omit-dir-times --delete \
	/tb2/build/bullseye-$afolder /tb2/phideb/pool/bullseye/
done


printf "\n\n create Packages files"
cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/buster/ > dists/buster/main/binary-amd64/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bullseye/ > dists/bullseye/main/binary-amd64/Packages


printf "\n\n create Release files at binary-amd64 folder"
cd /tb2/phideb/dists/buster/main/binary-amd64
gzip -kf Packages
xz -kfz Packages

cat <<\EOT >Release
Archive: stable
Origin: phideb
Label: phideb
Version: 0.2
Component: main
Architecture: amd64
EOT


cd /tb2/phideb/dists/bullseye/main/binary-amd64
gzip -kf Packages
xz -kfz Packages

cat <<\EOT >Release
Archive: stable
Origin: phideb
Label: phideb
Version: 0.2
Component: main
Architecture: amd64
EOT


printf "\n\n create Release files at distribution folder"
cd /tb2/phideb/dists/buster
create_release buster > Release

cd /tb2/phideb/dists/bullseye
create_release bullseye > Release


printf "\n\n chown folders & files: "
printf "folders "
find -L /w3repo/phideb -type d -group root  -exec chown webme:webme {} \;
find -L /w3repo/phideb -type d -user root  -exec chown webme:webme {} \;

printf "files "
find -L /w3repo/phideb -type f -group root  -exec chown webme:webme {} \;
find -L /w3repo/phideb -type f -user root  -exec chown webme:webme {} \;

printf "\n\n touch folders & files: "
find -L /w3repo/phideb -exec touch {} \;

/bin/bash /root/cf-clear.sh
