if (( $(date +%s) - $(date +%s -r "$ZDOTDIR"/.zcompdump 2> /dev/null || echo 0) > 86400 ))
then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' completer \
    _extensions _complete

zstyle ':completion:*' complete-options \
    true
zstyle ':completion:*' list-colors \
    ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list \
    'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu \
    select
zstyle ':completion:*' special-dirs \
    true
zstyle ':completion:*' squeeze-slashes \
    true
