typeset -gA ZSH_HIGHLIGHT_STYLES=(
    # unknown tokens / errors
    [unknown-token]=fg=red
    # shell reserved words
    [reserved-word]=fg=yellow
    # aliases
    [alias]=fg=green
    # suffix aliases
    [suffix-alias]=none
    # global aliases
    [global-alias]=none
    # shell builtin commands
    [builtin]=fg=green
    # function names
    [function]=fg=green
    # command names
    [command]=fg=green
    # precommand modifiers
    [precommand]=fg=green
    # command separation tokens
    [commandseparator]=none
    # hashed commands
    [hashed-command]=none
    # a directory name in command position when the AUTO_CD option is set
    [autodirectory]=underline
    # existing filenames
    [path]=underline
    # path separators in filenames
    [path_pathseparator]=underline
    # prefixes of existing filenames
    [path_prefix]=underline
    # path separators in prefixes of existing filenames
    [path_prefix_pathseparator]=underline
    # globbing expressions
    [globbing]=fg=blue
    # history expansion expressions
    [history-expansion]=fg=blue
    # command substitutions
    [command-substitution]=none
    # an unquoted command substitution
    [command-substitution-unquoted]=none
    # a quoted command substitution
    [command-substitution-quoted]=none
    # command substitution delimiters
    [command-substitution-delimiter]=fg=magenta
    # an unquoted command substitution delimiters
    [command-substitution-delimiter-unquoted]=fg=magenta
    # a quoted command substitution delimiters
    [command-substitution-delimiter-quoted]=fg=magenta
    # process substitutions
    [process-substitution]=none
    # process substitution delimiters
    [process-substitution-delimiter]=fg=magenta
    # arithmetic expansion
    [arithmetic-expansion]=fg=magenta
    # single-hyphen options
    [single-hyphen-option]=none
    # double-hyphen options
    [double-hyphen-option]=none
    # backtick command substitution
    [back-quoted-argument]=none
    # unclosed backtick command substitution
    [back-quoted-argument-unclosed]=none
    # backtick command substitution delimiters
    [back-quoted-argument-delimiter]=fg=magenta
    # single-quoted arguments
    [single-quoted-argument]=fg=yellow
    # unclosed single-quoted arguments
    [single-quoted-argument-unclosed]=fg=yellow
    # double-quoted arguments
    [double-quoted-argument]=fg=yellow
    # unclosed double-quoted arguments
    [double-quoted-argument-unclosed]=fg=yellow
    # dollar-quoted arguments
    [dollar-quoted-argument]=fg=yellow
    # unclosed dollar-quoted arguments
    [dollar-quoted-argument-unclosed]=fg=yellow
    # two single quotes inside single quotes when the RC_QUOTES option is set
    [rc-quote]=none
    # parameter expansion inside double quotes
    [dollar-double-quoted-argument]=fg=cyan
    # backslash escape sequences inside double-quoted arguments
    [back-double-quoted-argument]=fg=cyan
    # backslash escape sequences inside dollar-quoted arguments
    [back-dollar-quoted-argument]=fg=cyan
    # parameter assignments
    [assign]=none
    # redirection operators
    [redirection]=fg=yellow
    # elided parameters in command position
    [comment]=none
    # named file descriptor
    [named-fd]=none
    # numeric file descriptor
    [numeric-fd]=none
    # a command word other than one of those enumerated above
    [arg0]=fg=green
    # everything else
    [default]=none
)
