compinit

zstyle ':completion:*' completer _extensions _complete

# This is used by the completer for cd, chdir and pushd.
zstyle ':completion:*' complete-options true
# If the zsh/complist module is loaded, this style can be used to set color specifications.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# This style can be set to a list of match specifications that are to be applied everywhere.
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
# If the value contains the string 'select', menu selection will be started unconditionally.
zstyle ':completion:*' menu select
# If this style is set to 'true', it will add both '.' and '..' as possible completions.
zstyle ':completion:*' special-dirs true
# If set to 'true', sequences of slashes in filename paths will be treated as a single slash.
zstyle ':completion:*' squeeze-slashes true
