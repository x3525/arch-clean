#!/bin/bash

echo -e "poweroff\0icon\x1fsystem-shut-down\x1fpermanent\x1ftrue"
echo -e "reboot\0icon\x1fsystem-restart\x1fpermanent\x1ftrue"

[ -z "$1" ] || coproc { systemctl "$1" &> /dev/null; }
