history() {
    if [ "$1" = "Clear" ]
    then
        : >| "$HISTFILE"
        fc -p "$HISTFILE"
    else
        fc -E -l 1
    fi
}
