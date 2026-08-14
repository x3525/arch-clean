if [[ $- != *i* ]]
then
    return
fi

# The name of the file to which the command history is saved.
unset HISTFILE

# The primary prompt string.
PS1='\w\$ '
