#!/bin/bash

for d in "$1"/*
do
    f=$(basename -- "$d")
    p=${f%.*}

    killall -q -- "$p"

    while pgrep -u "$UID" -x "$p" > /dev/null
    do
        sleep 1
    done
done

dex -a -s "$1"
