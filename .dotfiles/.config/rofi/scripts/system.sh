#!/bin/bash

if [ -n "$1" ]
then
    coproc {
        systemctl "$1" >& /dev/null
    }
    exit
fi

while read -r command icon
do
    echo -e "$command\0icon\x1f$icon\x1fpermanent\x1ftrue"
done << EOF
poweroff system-shut-down
reboot system-restart
EOF
