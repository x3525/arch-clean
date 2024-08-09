MODULES_RIGHT="vpn pulseaudio battery menu backlight notify_battery"

IFS=$'\n'

for x in $(xrandr -q | grep ' connected')
do
    if echo "$x" | grep -q 'primary'
    then
        MODULES_RIGHT="tray ${MODULES_RIGHT}"
    fi

    MONITOR=$(echo "$x" | cut -d' ' -f1) MODULES_RIGHT=$MODULES_RIGHT polybar --reload -c ~/.config/polybar/config.ini &
done
