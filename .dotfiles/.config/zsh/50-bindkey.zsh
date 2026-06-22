# Select keymap 'emacs' for any operations by the current command.
bindkey -e

# Delete the character under the cursor.
bindkey '^[[3~' delete-char
# Move to the previous event in the history list.
bindkey '^[[5~' up-line-or-history
# Move to the next event in the history list.
bindkey '^[[6~' down-line-or-history
# Move up within the buffer, otherwise search for a history line matching the start of the current line.
bindkey '^[[A' up-line-or-beginning-search
# Move down within the buffer, otherwise search for a history line matching the start of the current line.
bindkey '^[[B' down-line-or-beginning-search
# Move to the previous completion rather than the next.
bindkey '^[[Z' reverse-menu-complete

case $TERM in
    linux)
        # Move to the beginning of the line.
        bindkey '^[[1~' beginning-of-line
        # Move to the end of the line.
        bindkey '^[[4~' end-of-line
        ;;
    *)
        # Move to the beginning of the next word.
        bindkey '^[[1;5C' forward-word
        # Move to the beginning of the previous word.
        bindkey '^[[1;5D' backward-word
        # Kill the current word.
        bindkey '^[[3;5~' kill-word
        # Move to the end of the line.
        bindkey '^[[F' end-of-line
        # Move to the beginning of the line.
        bindkey '^[[H' beginning-of-line
        ;;
esac
