if [ "$(id -u)" -eq 0 ]
then
    PS1='\[\e[38;5;39m\]\w\n\[\e[38;5;160m\]\u\[\e[0m\] # '
else
    PS1='\[\e[38;5;39m\]\w\n\[\e[0m\]$ '
fi