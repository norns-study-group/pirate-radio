#!/bin/bash
# /usr/bin/oggdec --quiet  "${1}" --output "${2}" > /dev/null &
/usr/bin/ogg123 -q -d wav -k ${3} -f "${2}" "${1}"  > /dev/null &
pid=$!
echo $pid > "${2}.pid"
renice 19 $pid