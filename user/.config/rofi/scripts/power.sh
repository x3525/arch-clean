#!/bin/bash

echo -en "Sign out\0icon\x1fsystem-log-out\n"
echo -en "Restart\0icon\x1fsystem-reboot\n"
echo -en "Shut down\0icon\x1fsystem-shutdown\n"

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
