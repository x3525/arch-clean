#!/bin/bash

case $1 in
    audio)
        pamixer -"$2" 5 --allow-boost --set-limit 150 && killall -USR1 i3status

        if pamixer --get-mute | grep -q -- 'true'
        then
            ICON=volume-level-none
        else
            ICON=volume-level-high
        fi

        dunstify -u L -h string:x-dunst-stack-tag:all -i "$ICON" "Volume" -h int:value:"$(pamixer --get-volume)"
        ;;
    touchpad)
        DEVICE="$(xinput list --short | grep -- 'Touchpad' | grep -oP -- '(?<=id=)[0-9]+')"

        xinput "$2" "$DEVICE"

        dunstify -u L -h string:x-dunst-stack-tag:all -i touchpad-indicator-light-"$2"d "$(xinput list --name-only "$DEVICE")" "Device is ${2}d"
        ;;
    battery)
        case $2 in
            C)
                dunstify -u L -h string:x-dunst-stack-tag:battery -i battery-050-charging "Battery" "Battery is charging..."
                ;;
            D)
                dunstify -u L -h string:x-dunst-stack-tag:battery -i battery-050 "Battery" "Battery is discharging..."
                ;;
            F)
                ;;
            N)
                ;;
            U)
                dunstify -u C -h string:x-dunst-stack-tag:battery -i battery-missing "Battery" "Battery status unknown"
                ;;
        esac
        ;;
esac
