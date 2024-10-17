#!/bin/bash

echo -e "Log Out\0icon\x1fsystem-log-out"
echo -e "Restart\0icon\x1fsystem-reboot"
echo -e "Shut Down\0icon\x1fsystem-shutdown"

case $1 in
    "Log Out")
        i3-msg exit
        ;;
    "Restart")
        systemctl reboot
        ;;
    "Shut Down")
        systemctl poweroff
        ;;
esac
