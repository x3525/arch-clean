history() {
    if [ "$1" = "clear" ]
    then
        : >| "$HISTFILE"
        fc -p "$HISTFILE"
    else
        fc -E -l 1
    fi
}
