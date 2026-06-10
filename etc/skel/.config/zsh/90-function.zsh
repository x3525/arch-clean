function history() {
    if [ $# -eq 0 ]
    then
        fc -i -l 1
    else
        print -n -u 2 "Clear the histor[y] list? "

        read -r

        case $REPLY in
            y|Y)
                print -n -u 2 >| "$HISTFILE"
                fc -p "$HISTFILE"
                ;;
        esac
    fi
}
