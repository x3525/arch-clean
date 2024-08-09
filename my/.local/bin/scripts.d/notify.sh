case $1 in
    pulseaudio)
        polybar-msg action pulseaudio "$2"

        if pamixer --get-mute | grep -q 'true'
        then
            ICON=volume-level-none
        else
            ICON=volume-level-high
        fi

        dunstify -u L -h string:x-dunst-stack-tag:all -i "$ICON" "Volume" -h int:value:"$(pamixer --get-volume)"
        ;;
    backlight)
        CARD=$(find /sys/class/backlight -mindepth 1 -maxdepth 1 | sort | head -1)

        polybar-msg action backlight "$2"

        if [ "$(cat "$CARD"/actual_brightness)" = "$(cat "$CARD"/max_brightness)" ]
        then
            dunstify -u L -h string:x-dunst-stack-tag:all -i notification-display-brightness-full "Backlight" "Maximum brightness"
        fi
        ;;
    touchpad)
        dunstify -u L -h string:x-dunst-stack-tag:all -i input-touchpad-"$2" "Touchpad" "Device is $2"
        ;;
    airplane)
        dunstify -u C -h string:x-dunst-stack-tag:rfkill -i airplane-mode "Wireless Devices" "$(rfkill -n -o soft | uniq)"
        ;;
    battery)
        FILE_BATTERY_DISCHARGING=/tmp/NOTIFY_BATTERY_DISCHARGING
        FILE_BATTERY_LOW=/tmp/NOTIFY_BATTERY_LOW

        FILE_BATTERY_CHARGING=/tmp/NOTIFY_BATTERY_CHARGING
        FILE_BATTERY_FULL=/tmp/NOTIFY_BATTERY_FULL

        BATTERY=$(find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name "BAT*" | sort | head -1)

        CAPACITY="$(grep -o -P '(?<=POWER_SUPPLY_CAPACITY=).+' "$BATTERY"/uevent)"

        if grep -q 'Discharging' "$BATTERY"/uevent
        then
            rm -f "$FILE_BATTERY_CHARGING"
            if [ ! -f "$FILE_BATTERY_DISCHARGING" ]
            then
                touch "$FILE_BATTERY_DISCHARGING"
                dunstify -u N -h string:x-dunst-stack-tag:bat -i battery-050 "Battery" "Battery is discharging..."
            fi
            rm -f "$FILE_BATTERY_FULL"
            if [ ! -f "$FILE_BATTERY_LOW" ] && [ "$CAPACITY" -le "$BATTERY_RISK_AT" ]
            then
                touch "$FILE_BATTERY_LOW"
                dunstify -u C -h string:x-dunst-stack-tag:bat -i battery-010 "Battery" "Battery level is low!"
            fi
        else
            rm -f "$FILE_BATTERY_DISCHARGING"
            if [ ! -f "$FILE_BATTERY_CHARGING" ]
            then
                touch "$FILE_BATTERY_CHARGING"
                dunstify -u L -h string:x-dunst-stack-tag:bat -i battery-050-charging "Battery" "Battery is charging..."
            fi
            rm -f "$FILE_BATTERY_LOW"
            if [ ! -f "$FILE_BATTERY_FULL" ] && [ "$CAPACITY" -ge "$BATTERY_FULL_AT" ]
            then
                touch "$FILE_BATTERY_FULL"
                dunstify -u L -h string:x-dunst-stack-tag:bat -i battery-100-charging "Battery" "Battery is full :)"
            fi
        fi
        ;;
    randr)
        if [ "$3" = "success" ]
        then
            URGENCY=N
        else
            URGENCY=C
        fi
        dunstify -u "$URGENCY" -h string:x-dunst-stack-tag:randr -i emblem-"$3" "Autorandr" "Option $3 ($2)"
        ;;
esac
