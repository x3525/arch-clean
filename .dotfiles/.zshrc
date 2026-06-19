# The primary prompt string, printed before a command is read.
PROMPT='%(1j.%F{white}%0~%f.%F{blue}%0~%f)%(0?.%F{cyan}%(!.#.$)%f.%F{red}%(!.#.$)%f) '

# This parameter undergoes prompt expansion, with the PROMPT_PERCENT option set.
PROMPT_EOL_MARK='%K{yellow} %k'

for f in "$XDG_CONFIG_HOME"/zsh/*.zsh(n)
do
    . "$f"
done; unset f

# Note that zsh-syntax-highlighting must be the last plugin sourced.
for f in /usr/share/zsh/plugins/*/*.plugin.zsh
do
    . "$f"
done; unset f
