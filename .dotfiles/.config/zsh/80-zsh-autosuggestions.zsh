# Color to use when highlighting suggestion
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=#4c4c4c

# Strategies to use to fetch a suggestion
ZSH_AUTOSUGGEST_STRATEGY=(
    history
)

# Widgets that clear the suggestion
ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
    up-line-or-beginning-search
    down-line-or-beginning-search
    up-line-or-history
    down-line-or-history
    accept-line
)

# Widgets that accept the entire suggestion
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
    forward-char
    end-of-line
)

# Widgets that accept the entire suggestion and execute it
ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=(
)

# Widgets that accept the suggestion as far as the cursor moves
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
    forward-word
)

# Widgets that should be ignored (globbing supported but must be escaped)
ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
)
