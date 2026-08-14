if [[ $- != *i* ]]
then
    return
fi

# The primary prompt string.
export PS1='\w\$ '

# The name of the file to which the command history is saved.
unset HISTFILE
