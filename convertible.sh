#!/bin/bash

# since my scripts need a monitor-sensor, as well as having other common definitions,
# this approach has them all running in parallel as functions

# Parts based based on https://wiki.postmarketos.org/wiki/Auto-rotation
# added support for only working if in tablet mode
# extended to enable/disable keyboard and touchpad
# dependencies:
# "psmisc", "libinput-tools","xrandr", "xinput", "inotify-tools" and "iio-sensor-proxy"
#
# user needs to be in the input group:
#    sudo gpasswd --add $username input
# then logout and login again


# use flock to ensure a single instance is running
FNAME=${0##*/}
LOCKFILE="/tmp/$FNAME.lock"


# Remove stale lock files or exit if another instance is running
if [[ -e "$LOCKFILE" ]]; then
    PID=$(cat "$LOCKFILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && eval kill -0 "$PID" 2>/dev/null ; then
            echo "Another instance of this script is already running (PID: $PID). Exiting."
            exit 1
        
    fi
    echo "Removing stale lock file: $LOCKFILE"
    rm -f "$LOCKFILE"
fi

# Try to acquire the lock
exec 221>"$LOCKFILE"  # Open the lock file with a specific file descriptor (221)
if ! flock -n 221; then
    echo "Could not lock the lockfile $LOCKFILE. Exiting."
    exit 1
fi

# Write the script's PID to the lock file (optional but useful for debugging)
echo $$ > "$LOCKFILE"

# lock is automatically release upon exit

trap mortalWound EXIT  # Ensure the lock file is deleted on exit

# edit the following for your specific system events and devices
# use "libinput list-devices" to identify the touchscreen device, keyboard, etc
# "xinput --list" does not list switches
touchScreen="Elan Touchscreen"
touchPad="Elan Touchpad"
modeSwitch="Tablet Mode Switch"
keyBoard="AT Translated Set 2 keyboard"
vkeyBoard="keyd virtual keyboard"
# This query should return your lcd screen - verify in your terminal
sName=$(xrandr |grep "\sconnected"|cut -d" " -f1 | head -1)
# sName="eDP" # If the query doesn't work for you, just hardcode the lcd screen name


# use "xinput list" to obtain id and master id for keyboard and touchpad
# master ids are only needed if using float/reattach instead of enable/disable
# eg - 
# Elan Touchpad                           	id=9	[slave  pointer  (2)]
#
tpadID=9
#tpadMaster=2
#
# AT Translated Set 2 keyboard            	id=11	[slave  keyboard (3)]
# keyd virtual keyboard                   	id=12	[slave  keyboard (3)]
# if you're using the keyd keymap as suggested from 
# https://docs.chrultrabook.com/docs/installing/distros.html
# the keyboard is "keyd", if not it is the "AT Translated"
#
kbdID=11
#kbdMaster=3


# use "libinput --list-devices" to identify the tablet mode switch. 
# if you get "permission denied" errors, you forgot to add your
# user to the input group
# The output usually will include like this:
# Device:           Tablet Mode Switch
# Kernel:           /dev/input/event4
tabModeSwitch="/dev/input/event4"

# this function assumes you use Onboard as on-screen keyboard,
# and uses dbus to enable/disable its auto-show
mode_switch() {
    libinput debug-events --device "$tabModeSwitch" | while read line; do
        mode=$(echo "$line" | grep -o 'state [0-9]' | awk '{print $2}')
        if [ "$mode" = "1" ]; then
            #	echo "tablet"
            # disable keyboard
            xinput disable $kbdID
            # disable touchpad
            xinput disable $tpadID
	        dbus-send --type=method_call --print-reply --dest=org.onboard.Onboard /org/onboard/Onboard/Keyboard org.freedesktop.DBus.Properties.Set string:"org.onboard.Onboard.Keyboard" string:"AutoShowPaused" variant:boolean:"false" &>/dev/null
        else 
            # 	echo "laptop"
            # enable keyboard
            xinput enable $kbdID
            # enable touchpad
            xinput enable $tpadID
	    #pause onboard auto-show.
	        dbus-send --type=method_call --print-reply --dest=org.onboard.Onboard /org/onboard/Onboard/Keyboard org.freedesktop.DBus.Properties.Set string:"org.onboard.Onboard.Keyboard" string:"AutoShowPaused" variant:boolean:"true" &>/dev/null
    fi
    done
}

auto_rotate() {
    while inotifywait -e modify /dev/shm/sensor.log; do

    ORIENTATION=$(tail /dev/shm/sensor.log | grep 'orientation' | tail -1 | grep -oE '[^ ]+$')

        case "$ORIENTATION" in

                normal)
                xrandr --output $sName --rotate normal
                xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
                ;;
            left-up)
                xrandr --output $sName --rotate left
                xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
                ;;
            bottom-up)
                xrandr --output $sName --rotate inverted
                xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
                ;;
            right-up)
                xrandr --output $sName --rotate right
                xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
                ;;
        esac
    done
}

cleanExit() {
    mortalWound
#    rm -f "$LOCKFILE"
#    killall monitor-sensor
}

mortalWound() {
    #all for one - if one subprocess died, kill everyone and cleanup
    echo "wounded"
    pkill -P $$
    rm -f "$LOCKFILE"
    exit 0
}

# Launch all processes
setAllUp() {
    killall monitor-sensor
    monitor-sensor > /dev/shm/sensor.log 2>&1 &
    mode_switch &
    auto_rotate &
    # catch any subprocess death
    trap mortalWound CHLD
}

setAllUp

# Loop forever
# ensures we don't release the lock and don't have multiple invocations. 
# Traps catch if any process died and do the exit
while true; do true
done

