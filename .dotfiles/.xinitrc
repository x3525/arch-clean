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
        if [ -x /usr/bin/cpp ]
        then
            xrdb "$f" -merge
        else
            xrdb "$f" -merge -nocpp
        fi
    fi
done

for f in /etc/X11/xinit/.Xmodmap "$HOME/.Xmodmap"
do
    if [ -f "$f" ]
    then
        xmodmap "$f"
    fi
done

if [ -d /etc/X11/xinit/xinitrc.d/ ]
then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh
    do
        if [ -x "$f" ]
        then
            . "$f"
        fi
    done
fi

numlockx on

exec i3
