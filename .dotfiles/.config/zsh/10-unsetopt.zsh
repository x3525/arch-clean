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
