#!/bin/bash
/usr/bin/oggdec --quiet  "${1}" --output "${2}" > /dev/null &
echo $! > "${2}.pid"