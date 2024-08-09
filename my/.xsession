xinput --set-prop "$(xinput list | grep 'Touchpad' | grep -o -P '(?<=id=)[0-9]+')" "libinput Scrolling Pixel Distance" 30
