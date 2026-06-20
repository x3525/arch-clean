# The primary prompt string, printed before a command is read.
PROMPT='%(1j.%F{white}%0~%f.%F{blue}%0~%f)%(0?.%F{cyan}%(!.#.$)%f.%F{red}%(!.#.$)%f) '

# This parameter undergoes prompt expansion, with the PROMPT_PERCENT option set.
PROMPT_EOL_MARK='%K{yellow} %k'

for f in "$XDG_CONFIG_HOME"/zsh/*.zsh(n)
do
    . "$f"
done

# Note that zsh-syntax-highlighting must be the last plugin sourced.
. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
