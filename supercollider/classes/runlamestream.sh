#!/bin/bash
curl --silent "${1}"  | /usr/bin/lame --mp3input --decode --silent --resample ${3} - "${2}"  > /dev/null &
echo $! > "${2}.pid"
