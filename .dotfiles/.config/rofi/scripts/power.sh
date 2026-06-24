#!/bin/bash

if [ -n "$1" ]
then
    coproc { systemctl "$1" >& /dev/null; }
    exit
fi

echo -e "poweroff\0icon\x1fsystem-shut-down\x1fpermanent\x1ftrue"
echo -e "reboot\0icon\x1fsystem-restart\x1fpermanent\x1ftrue"
