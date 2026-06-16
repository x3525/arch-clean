history() {
    if [ "$1" = "clear" ]
    then
        print -n -u 2 "Clear the histor[y] list? "

        read -r

        case $REPLY in
            y|Y)
                print -n -u 2 >| "$HISTFILE"
                fc -p "$HISTFILE"
                ;;
        esac
    else
        fc -i -l 1
    fi
}
