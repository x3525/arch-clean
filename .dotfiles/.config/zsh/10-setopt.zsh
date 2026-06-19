# When the last character resulting from a completion is a slash and the next character typed is a slash, remove the slash.
unsetopt AUTO_REMOVE_SLASH
# Perform textual history expansion, csh-style, treating the character ! specially.
unsetopt BANG_HIST
# If this option is unset, output flow control via start/stop characters (usually assigned to ^S/^Q) is disabled in the shell's editor.
unsetopt FLOW_CONTROL
# Allow comments even in interactive shells.
unsetopt INTERACTIVE_COMMENTS
# Allow the character sequence '' to signify a single quote within singly quoted strings.
unsetopt RC_QUOTES
# If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word.
setopt ALWAYS_TO_END
# Make cd push the old directory onto the directory stack.
setopt AUTO_PUSHD
# Never print the working directory after a cd (whether explicit or implied with the AUTO_CD option set).
setopt CD_SILENT
# If unset, the cursor is set to the end of the word if completion is started.
setopt COMPLETE_IN_WORD
# Save each command's beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file.
setopt EXTENDED_HISTORY
# Do not enter command lines into the history list if they are duplicates of the previous event.
setopt HIST_IGNORE_DUPS
# Remove command lines from the history list when the first character on the line is a space.
setopt HIST_IGNORE_SPACE
# Whenever the user enters a line with history expansion, don't execute the line directly; instead, perform history expansion.
setopt HIST_VERIFY
# Print job notifications in the long format by default.
setopt LONG_LIST_JOBS
# If set, parameter expansion, command substitution and arithmetic expansion are performed in prompts.
setopt PROMPT_SUBST
# Don't push multiple copies of the same directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS
# Exchanges the meanings of + and - when used with a number to specify a directory in the stack.
setopt PUSHD_MINUS
# This option both imports new commands from the history file, and also causes your typed commands to be appended to the history file.
setopt SHARE_HISTORY
