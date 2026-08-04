# If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word.
setopt ALWAYS_TO_END
# Make cd push the old directory onto the directory stack.
setopt AUTO_PUSHD
# When the last character resulting from a completion is a slash and the next character typed is a slash, remove the slash.
setopt AUTO_REMOVE_SLASH
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
# When listing files that are possible completions, show the type of each file with a trailing identifying mark.
setopt LIST_TYPES
# Print job notifications in the long format by default.
setopt LONG_LIST_JOBS
# Print a carriage return just before printing a prompt in the line editor.
setopt PROMPT_CR
# Attempt to preserve a partial line that would otherwise be covered up by the command prompt due to the PROMPT_CR option.
setopt PROMPT_SP
# If set, parameter expansion, command substitution and arithmetic expansion are performed in prompts.
setopt PROMPT_SUBST
# Don't push multiple copies of the same directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS
# Exchanges the meanings of "+" and "-" when used with a number to specify a directory in the stack.
setopt PUSHD_MINUS
# This option both imports new commands from the history file, and also causes your typed commands to be appended to the history file.
setopt SHARE_HISTORY
