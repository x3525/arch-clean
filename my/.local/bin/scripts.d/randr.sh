profiles() {
    for profile in ~/.config/autorandr/*/
    do
        if [ -d "$profile" ] && [ -x "$profile" ]
        then
            basename "$profile"
        fi
    done
}

case $1 in
    "remove" | "load")
        PROFILE=$(profiles | zenity --list --title "" --text "Select a profile from the list below:" --column "Available Profiles")
        ;;
    "save")
        PROFILE=$(zenity --entry --title "" --text "Enter a profile name:")
        ;;
esac

if [ -n "$PROFILE" ]
then
    if autorandr --force --"$1" "$PROFILE"
    then
        ~/.local/bin/scripts.d/notify.sh randr "$1" success
    else
        ~/.local/bin/scripts.d/notify.sh randr "$1" error
    fi
fi
