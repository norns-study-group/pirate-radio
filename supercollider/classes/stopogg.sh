#!/bin/bash
sleep 2
pkill -f curl 
pkill -f oggdec
pkill -f ogg123
pkill -f lame
rm -rf /dev/shm/sc3mp3*