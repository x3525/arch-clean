battery () {
    command cat /sys/class/power_supply/"${1:-BAT0}"/uevent
}

history () {
    if [ "$1" = "clear" ]
    then
        : >| "$HISTFILE"
        fc -p "$HISTFILE"
    else
        fc -E -l 1
    fi
}
