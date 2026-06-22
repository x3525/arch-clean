# Create a new keymap, named main.
bindkey -N main

# Delete the character behind the cursor.
bindkey '^?' backward-delete-char
# This widget is invoked when text is pasted to the terminal emulator.
bindkey '^[[200~' bracketed-paste
# Delete the character under the cursor.
bindkey '^[[3~' delete-char
# Move up a line in the buffer, or if already at the top line, move to the previous event in the history list.
bindkey '^[[5~' up-line-or-history
# Move down a line in the buffer, or if already at the bottom line, move to the next event in the history list.
bindkey '^[[6~' down-line-or-history
# Move up within the buffer, otherwise search for a history line matching the start of the current line.
bindkey '^[[A' up-line-or-beginning-search
# Move down within the buffer, otherwise search for a history line matching the start of the current line.
bindkey '^[[B' down-line-or-beginning-search
# Move forward one character.
bindkey '^[[C' forward-char
# Move backward one character.
bindkey '^[[D' backward-char
# Move to the previous completion rather than the next.
bindkey '^[[Z' reverse-menu-complete
# Attempt shell expansion on the current word.
bindkey '^I' expand-or-complete
# Finish editing the buffer.
bindkey '^J' accept-line
# Clear the screen and redraw the prompt.
bindkey '^L' clear-screen
# Finish editing the buffer.
bindkey '^M' accept-line
# Search backward incrementally for a specified string.
bindkey '^R' history-incremental-search-backward
# Search forward incrementally for a specified string.
bindkey '^S' history-incremental-search-forward
# Kill the word behind the cursor.
bindkey '^W' backward-kill-word

# Insert a character into the buffer at the cursor position.
bindkey -R ' -~' self-insert
# Insert a character into the buffer at the cursor position.
bindkey -R '\M-^@-\M-^?' self-insert

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
