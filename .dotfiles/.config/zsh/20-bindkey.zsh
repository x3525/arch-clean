# Select keymap 'emacs' for any operations by the current command.
bindkey -e

autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search

autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Move to the previous event in the history list.
bindkey '^[[5~' up-line-or-history
# Move to the next event in the history list.
bindkey '^[[6~' down-line-or-history
# Delete the character under the cursor.
bindkey '^[[3~' delete-char
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
        # Move to the beginning of the line.
        bindkey '^[[H' beginning-of-line
        # Move to the end of the line.
        bindkey '^[[F' end-of-line
        # Move to the beginning of the previous word.
        bindkey '^[[1;5D' backward-word
        # Move to the beginning of the next word.
        bindkey '^[[1;5C' forward-word
        # Kill the current word.
        bindkey '^[[3;5~' kill-word
        ;;
esac
