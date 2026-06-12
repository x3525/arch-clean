#!/bin/sh

for f in /etc/xprofile "$HOME/.xprofile"
do
    if [ -f "$f" ]
    then
        . "$f"
    fi
done

for f in /etc/X11/xinit/.Xresources "$HOME/.Xresources"
do
    if [ -f "$f" ]
    then
        xrdb -merge "$f"
    fi
done

for f in /etc/X11/xinit/.Xmodmap "$HOME/.Xmodmap"
do
    if [ -f "$f" ]
    then
        xmodmap "$f"
    fi
done

if [ -d /etc/X11/xinit/xinitrc.d ]
then
    for f in /etc/X11/xinit/xinitrc.d/*.sh
    do
        if [ -x "$f" ] && [ ! -d "$f" ]
        then
            . "$f"
        fi
    done
fi

numlockx on

exec dbus-run-session i3
