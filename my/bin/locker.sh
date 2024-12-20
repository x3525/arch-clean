#!/bin/bash

brightnessctl --save
brightnessctl set 1%
dunstctl set-paused true

i3lock --nofork --pointer default --color 000000 --ignore-empty-password --show-failed-attempts --show-keyboard-layout

dunstctl set-paused false
brightnessctl --restore
