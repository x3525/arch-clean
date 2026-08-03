# If a command is issued that can't be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory.
unsetopt AUTO_CD
# Perform textual history expansion, csh-style, treating the character "!" specially.
unsetopt BANG_HIST
# If this option is unset, output flow control via start/stop characters (usually assigned to ^S/^Q) is disabled in the shell's editor.
unsetopt FLOW_CONTROL
# Allow comments even in interactive shells.
unsetopt INTERACTIVE_COMMENTS
# Allow the character sequence "''" to signify a single quote within singly quoted strings.
unsetopt RC_QUOTES
# Use single-line command line editing instead of multi-line.
unsetopt SINGLE_LINE_ZLE
