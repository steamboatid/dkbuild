#!/bin/bash



# bash colors
export red=$'\e[1;31m'
export grn=$'\e[1;32m'
export green=$'\e[1;32m'
export yel=$'\e[1;33m'
export blu=$'\e[1;34m'
export blue=$'\e[1;34m'
export mag=$'\e[1;35m'
export magenta=$'\e[1;35m'
export cyn=$'\e[1;36m'
export cyan=$'\e[1;36m'
export end=$'\e[0m'


rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/*sh ava:/tb2/build/

rsync -aHAXvztr --numeric-ids --modify-window 5 --omit-dir-times \
/tb2/build/dk* ava:/tb2/build/

##--- start all lxc
ssh ava -- /bin/bash /root/start-lxc-all.sh

##--- testing
# ssh ava -- lxca vmig -- /bin/bash /tb2/build/dk-bus-to-bul.sh

##--- upgrade lxc
for alxc in $(ssh ava -- lxc-ls --fancy | tail -n +2 | cut -d" " -f1); do
	printf "\n\n\n${cyan} --- $alxc --- ${end}\n\n"
	ssh ava -- lxca "$alxc" -- /bin/bash /tb2/build/avafix.sh

	ssh ava -- lxca "$alxc" -- /bin/bash /tb2/build/dk-bus-to-bul.sh | \
		grep -iv "stable\|upgraded\|reading\|building\|get\|ign\|calcu\|preparing\|setting\|unpacking\|process\|up to date\|complete\|root\|export\|fetched\|ing\|after this\|dns\|done\|now\|tz\|zone" | sed '/^$/d'

	printf "\n\n\n${cyan} --- $alxc --- ${end}\n\n"
	ssh ava -- lxca "$alxc" -- /bin/bash /tb2/build/avafix.sh
done
