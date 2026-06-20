# There is a single base directory relative to which user-specific data files should be written.
export XDG_DATA_HOME="$HOME/.local/share"

# There is a single base directory relative to which user-specific configuration files should be written.
export XDG_CONFIG_HOME="$HOME/.config"

# There is a single base directory relative to which user-specific state data should be written.
export XDG_STATE_HOME="$HOME/.local/state"

# There is a set of preference ordered base directories relative to which data files should be searched.
export XDG_DATA_DIRS="/usr/local/share/:/usr/share/"

# There is a set of preference ordered base directories relative to which configuration files should be searched.
export XDG_CONFIG_DIRS="/etc/xdg"

# There is a single base directory relative to which user-specific non-essential (cached) data should be written.
export XDG_CACHE_HOME="$HOME/.cache"

# A colon-separated list of names that the current desktop is known as.
export XDG_CURRENT_DESKTOP="i3:XFCE"

# The directory to search for shell startup files.
export ZDOTDIR="$HOME"

# The file to save the history in when an interactive shell exits.
export HISTFILE="$ZDOTDIR/.zsh_history"

# The maximum number of events stored in the internal history list.
export HISTSIZE=100000

# The maximum number of history events to save in the history file.
export SAVEHIST=100000

# A list of non-alphanumeric characters considered part of a word by the line editor.
export WORDCHARS=

# The name of the editor.
export EDITOR="vim"

# The name of the editor.
export VISUAL="vim"

# The name of the program used to display the manual page.
export MANPAGER="less"

# The name of the program used to display the manual page.
export PAGER="less"

# Options which are passed to less automatically.
export LESS="-iR"
