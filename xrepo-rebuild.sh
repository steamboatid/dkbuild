#!/bin/bash


export DEBIAN_FRONTEND="noninteractive"

export DEBFULLNAME="Dwi Kristianto"
export DEBEMAIL="steamboatid@gmail.com"
export EMAIL="steamboatid@gmail.com"

if [[ $(dpkg -l | grep "^ii" | grep "lsb\-release" | wc -l) -lt 1 ]]; then
	apt update; dpkg --configure -a; apt install -fy;
	apt install -fy lsb-release;
fi
export RELNAME=$(lsb_release -sc)
export RELVER=$(LSB_OS_RELEASE="" lsb_release -a 2>&1 | grep Release | awk '{print $2}' | tail -n1)

export TODAY=$(date +%Y%m%d-%H%M)
export TODATE=$(date +%Y%m%d)

export PKGDATE=$(date -Ru)
export VALIDDATE=$(date -d'+3 years' -Ru)
export PKGDATEVER=$(date +%Y%m%d.%H%M)


# Directory structure
#
# --phideb
#     |--dists
#          |-- buster
#          |-- bullseye
#          |-- bookworm
#     |--pool
#          |-- buster
#          |-- bullseye
#          |-- bookworm


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
	RELVER="0.3"

	cat << EOF
Archive: stable
Origin: phideb
Label: phideb
Suite: ${RELNAME}
Codename: ${RELNAME}
Version: ${RELVER}.${PKGDATEVER}
Architectures: amd64
Components: main
Description: phideb custom packages for ${RELNAME}
Date: $(date -Ru)
EOF
	do_hash "MD5Sum" "md5sum"
	do_hash "SHA1" "sha1sum"
	do_hash "SHA256" "sha256sum"
}


mkdir -p /tb2/phideb/{dists,pool}/{buster,bullseye,bookworm}
mkdir -p /tb2/phideb/dists/{buster,bullseye,bookworm}/main/binary-amd64

# delete old files
find -L /tb2/phideb -mindepth 2 -type f -delete
rm -rf /tb2/phideb/pool /tb2/phideb/dists

folders=(php nginx nutcracker lua-resty-core lua-resty-lrucache keydb pcre libzip db4 sshfs)
for afolder in "${folders[@]}"; do
	printf " copy folder: $afolder "

	mkdir -p /tb2/phideb/pool/buster/$afolder
	mkdir -p /tb2/phideb/pool/bullseye/$afolder
	mkdir -p /tb2/phideb/pool/bookworm/$afolder

	# buster
	printf " -- buster "
	rsync -aHAXztr --numeric-ids --delete \
	/tb2/build-devomd/buster-$afolder/ /tb2/phideb/pool/buster/$afolder

	# bullseye
	printf " -- bullseye "
	rsync -aHAXztr --numeric-ids --delete \
	/tb2/build-devomd/bullseye-$afolder/ /tb2/phideb/pool/bullseye/$afolder

	# bookworm
	printf " -- bookworm "
	rsync -aHAXztr --numeric-ids --delete \
	/tb2/build-devomd/bookworm-$afolder/ /tb2/phideb/pool/bookworm/$afolder

	printf " -- done \n"
done


printf "\n\n create Packages files"
cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/buster/ > dists/buster/main/binary-amd64/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bullseye/ > dists/bullseye/main/binary-amd64/Packages

cd /tb2/phideb; \
apt-ftparchive --arch amd64 packages pool/bookworm/ > dists/bookworm/main/binary-amd64/Packages


printf "\n\n create Release files at binary-amd64 folder"
cd /tb2/phideb/dists/buster/main/binary-amd64
gzip -kf Packages
xz -kfz Packages

release="buster"

cat << EOT >Release
Archive: stable
Origin: phideb
Label: phideb
Suite: ${release}
Codename: ${release}
Version: 0.3.${PKGDATEVER}
Architectures: amd64
Components: main
Description: phideb custom packages for ${release}
Date: $(date -Ru)
EOT


cd /tb2/phideb/dists/bullseye/main/binary-amd64
gzip -kf Packages
xz -kfz Packages

release="bullseye"

cat << EOT >Release
Archive: stable
Origin: phideb
Label: phideb
Suite: ${release}
Codename: ${release}
Version: 0.3.${PKGDATEVER}
Architectures: amd64
Components: main
Description: phideb custom packages for ${release}
Date: $(date -Ru)
EOT


cd /tb2/phideb/dists/bookworm/main/binary-amd64
gzip -kf Packages
xz -kfz Packages

release="bookworm"

cat << EOT >Release
Archive: stable
Origin: phideb
Label: phideb
Suite: ${release}
Codename: ${release}
Version: 0.3.${PKGDATEVER}
Architectures: amd64
Components: main
Description: phideb custom packages for ${release}
Date: $(date -Ru)
EOT


printf "\n\n create Release files at distribution folder"
cd /tb2/phideb/dists/buster
create_release buster > Release

cd /tb2/phideb/dists/bullseye
create_release bullseye > Release

cd /tb2/phideb/dists/bookworm
create_release bookworm > Release


# trusted-keys
[[ ! -e /tb2/phideb/trusted-keys ]] && \
	apt-key exportall > /tb2/phideb/trusted-keys 2>&1 >/dev/null


printf "\n\n chown folders & files: "
printf "folders "
find -L /tb2/phideb -type d -group root  -exec chown webme:webme {} \;
find -L /tb2/phideb -type d -user root  -exec chown webme:webme {} \;

printf "files "
find -L /tb2/phideb -type f -group root  -exec chown webme:webme {} \;
find -L /tb2/phideb -type f -user root  -exec chown webme:webme {} \;

printf "\n\n touch folders & files: "
find -L /tb2/phideb -exec touch {} \;

/bin/bash /root/clear-nginx-cache.sh
/bin/bash /root/clear-cloudflare.sh
