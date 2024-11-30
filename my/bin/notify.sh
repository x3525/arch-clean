#!/bin/bash

case $1 in
    audio)
        pamixer -"$2" 5 --allow-boost --set-limit 150

        if pamixer --get-mute | grep -q -- 'true'
        then
            ICON=volume-level-none
        else
            ICON=volume-level-high
        fi

        dunstify -u L -h string:x-dunst-stack-tag:all -i "$ICON" "Volume" -h int:value:"$(pamixer --get-volume)"
        ;;
    touchpad)
        DEVICE="$(xinput list --short | grep -- 'Touchpad' | grep -P -o -- '(?<=id=)[0-9]+')"

        xinput "$2" "$DEVICE"

        dunstify -u L -h string:x-dunst-stack-tag:all -i touchpad-indicator-light-"$2"d "$(xinput list --name-only "$DEVICE")" "Device is ${2}d"
        ;;
    battery)
        case $2 in
            C)
                ICON=battery-$(awk -v CAPACITY="$3" 'BEGIN{printf "%03d",int(CAPACITY/10)*10}')-charging
                dunstify -u L -h string:x-dunst-stack-tag:battery -i "$ICON" "Battery" "Battery is charging..." -h int:value:"$3"
                ;;
            D)
                ICON=battery-$(awk -v CAPACITY="$3" 'BEGIN{printf "%03d",int(CAPACITY/10)*10}')
                dunstify -u L -h string:x-dunst-stack-tag:battery -i "$ICON" "Battery" "Battery is discharging..." -h int:value:"$3"
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
