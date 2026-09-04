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
    for f in /etc/X11/xinit/xinitrc.d/?*.sh
    do
        if [ -x "$f" ]
        then
            . "$f"
        fi
    done
fi

# Set environment variables for systemd user services as well as for traditional D-Bus session services.
dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP

# Turns NumLock on in X.
numlockx on

# Automatically select a display configuration based on connected devices.
autorandr -c

# Replace the shell with i3 without creating a new process.
exec i3
