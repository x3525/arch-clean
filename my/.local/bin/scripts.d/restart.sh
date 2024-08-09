for d in "$@"
do
    f=$(basename "$d")
    p=${f%.*}

    killall -q "$p"

    while pgrep -u "$UID" -x "$p" > /dev/null
    do
        sleep 1
    done

    dex ~/.config/autostart/custom.d/"$p".desktop
done
