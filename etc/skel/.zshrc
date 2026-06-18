unsetopt AUTO_REMOVE_SLASH
unsetopt BANG_HIST
unsetopt FLOW_CONTROL
unsetopt INTERACTIVE_COMMENTS
unsetopt RC_QUOTES

setopt ALWAYS_TO_END
setopt AUTO_PUSHD
setopt CD_SILENT
setopt COMPLETE_IN_WORD
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt LONG_LIST_JOBS
setopt PROMPT_SUBST
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS
setopt SHARE_HISTORY

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
