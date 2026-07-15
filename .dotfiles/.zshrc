# An array of directories specifying the search path for function definitions.
fpath=(~/.zsh/functions "${fpath[@]}")

# The primary prompt string, printed before a command is read.
PROMPT='%F{blue}%0~%f%F{cyan}%(!.#.$)%f '

# This prompt is displayed on the right-hand side of the screen when the primary prompt is being displayed on the left.
RPROMPT='%(0?..%F{red}%?%f)'

# This parameter undergoes prompt expansion, with the PROMPT_PERCENT option set.
PROMPT_EOL_MARK='%K{yellow} %k'

for f in "${fpath[1]}"/*(.:t)
do
    autoload -Uz "$f"
done; unset f

for f in ~/.zsh/*.zsh(.n)
do
    . "$f"
done; unset f

# Note that zsh-syntax-highlighting must be the last plugin sourced.
. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
