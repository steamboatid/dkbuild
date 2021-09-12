#!/bin/bash

printf " chown folders \n"
find -L /w3repo/phideb -type d -group root  -exec chown webme:webme {} \; &
find -L /w3repo/phideb -type d -user root  -exec chown webme:webme {} \; &

printf " chown files \n"
find -L /w3repo/phideb -type f -group root  -exec chown webme:webme {} \; &
find -L /w3repo/phideb -type f -user root  -exec chown webme:webme {} \; &
