#!/bin/bash
# /usr/bin/oggdec --quiet  "${1}" --output "${2}" > /dev/null &
/usr/bin/lame --decode --silent --resample ${3} "${1}" "${2}"  > /dev/null &
echo $! > "${2}.pid"
