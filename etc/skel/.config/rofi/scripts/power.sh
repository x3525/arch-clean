#!/bin/bash

echo -en "poweroff\0permanent\x1ftrue\x1ficon\x1fsystem-shut-down\x1fdisplay\x1fShut Down\x1finfo\x1fsystemctl\n"
echo -en "reboot\0permanent\x1ftrue\x1ficon\x1fsystem-restart\x1fdisplay\x1fRestart\x1finfo\x1fsystemctl\n"
echo -en "exit\0permanent\x1ftrue\x1ficon\x1fsystem-log-out\x1fdisplay\x1fLog Out\x1finfo\x1fi3-msg\n"

[ -z "$ROFI_INFO" ] || coproc ( "$ROFI_INFO" "$1" &> /dev/null )
