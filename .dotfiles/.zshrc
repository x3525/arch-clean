# An array of directories specifying the search path for function definitions.
fpath=("$ZDOTDIR"/.zsh/functions "${fpath[@]}")

# The primary prompt string, printed before a command is read.
PROMPT='%F{blue}%0~%f%F{cyan}%(!.#.$)%f '

# This prompt is displayed on the right-hand side of the screen when the primary prompt is being displayed on the left.
RPROMPT='%(0?..%F{red}%?%f)'

# When the PROMPT_CR and PROMPT_SP options are set, the PROMPT_EOL_MARK parameter can be used to customize how the end of partial lines are shown.
PROMPT_EOL_MARK='%K{yellow} %k'

# Color setup for ls.
eval "$(dircolors -b "$HOME"/.dir_colors)"

for f in "${fpath[1]}"/**/*(^/)
do
    autoload -Uz "${f:t}"

    if [[ $f == */zle/* ]]
    then
        zle -N "${f:t}"
    fi
done; unset f

for f in "$ZDOTDIR"/.zsh/*.zsh(^/n)
do
    . "$f"
done; unset f

# Note that zsh-syntax-highlighting must be the last plugin sourced.
. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
