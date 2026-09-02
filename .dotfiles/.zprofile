if [ -z "$DISPLAY" ]
then
    case $(tty) in
        /dev/tty1)
            exec startx
            ;;
    esac
fi
