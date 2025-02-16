#!/bin/bash

dunstctl set-paused true

i3lock --nofork --color 000000 --pointer default --ignore-empty-password --show-failed-attempts --show-keyboard-layout

dunstctl set-paused false
