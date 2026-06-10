#!/bin/bash

echo -en "systemctl poweroff\0permanent\x1ftrue\x1ficon\x1fsystem-shut-down\x1fdisplay\x1fShut Down\n"
echo -en "systemctl reboot\0permanent\x1ftrue\x1ficon\x1fsystem-restart\x1fdisplay\x1fRestart\n"
echo -en "i3-msg exit\0permanent\x1ftrue\x1ficon\x1fsystem-log-out\x1fdisplay\x1fLog Out\n"

[ -z "$1" ] || coproc ($1 &> /dev/null)
