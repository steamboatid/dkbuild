#!/bin/bash

rm -rf /root/org.src /root/src

/bin/bash /tb2/build/dk-prep-deps-php8.sh

dsc_num=$(find /root/org.src/php -maxdepth 1 -type f -iname "*.dsc" | grep -iv "xmlrpc" | wc -l)
dir_num=$(find /root/org.src/php -maxdepth 1 -type d | wc -l)
printf "\n\n\n --- DSC=${blue}$dsc_num ${end} --- DIR=${blue}$dir_num ${end} \n\n"

