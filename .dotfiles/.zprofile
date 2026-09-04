if [ -z "$DISPLAY" ]
then
    case $XDG_VTNR in
        1)
            exec startx
            ;;
    esac
fi
