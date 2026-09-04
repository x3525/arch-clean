# An array of directories specifying the search path for function definitions.
fpath=("$ZDOTDIR"/.zsh/functions "${fpath[@]}")

# When the PROMPT_CR and PROMPT_SP options are set, the PROMPT_EOL_MARK parameter can be used to customize how the end of partial lines are shown.
PROMPT_EOL_MARK='%K{yellow} %k'

# The primary prompt string, printed before a command is read.
PS1='%~%# '

# These escape sequences are used to enable bracketed paste when ZLE is active and disable it at other times.
zle_bracketed_paste=($'\C-[[?2004h' $'\C-[[?2004l')

# An array describing contexts in which ZLE should highlight the input text.
zle_highlight=(default:none isearch:standout region:none special:none suffix:none paste:none)

# Typically this will be used to set the value to 0 so that the prompt appears flush with the right hand side of the screen.
ZLE_RPROMPT_INDENT=0

# Controls how the --color option highlights output.
export GREP_COLORS='sl=:cx=:mt=31:ms=31:mc=31:fn=35:ln=32:bn=33:se=36:'

# Color setup for ls.
eval "$(dircolors -b "$HOME"/.dir_colors)"

for f in "${fpath[1]}"/*(:t)
do
    autoload -Uz "$f"

    if [[ $f == zle-* ]]
    then
        zle -N "${f/zle-/}" "$f"
    fi
done; unset f

for f in "$ZDOTDIR"/.zsh/*.zsh(^/n)
do
    . "$f"
done; unset f

# Note that zsh-syntax-highlighting must be the last plugin sourced.
. /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
. /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
