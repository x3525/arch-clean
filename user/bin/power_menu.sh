#!/bin/bash

echo -e "Sign out\0icon\x1fsystem-log-out"
echo -e "Restart\0icon\x1fsystem-reboot"
echo -e "Shut down\0icon\x1fsystem-shutdown"

case $1 in
    "Sign out")
        i3-msg exit
        ;;
    "Restart")
        systemctl reboot
        ;;
    "Shut down")
        systemctl poweroff
        ;;
esac
