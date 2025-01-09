#!/bin/bash
#
# Dependencies:
# libinput-tools, xinput, iio-sensor-proxy

# use flock to ensure a single instance is running
LOCKFILE="/tmp/$FNAME.lock"

FNAME=${0##*/}
# Remove stale lock files or exit if another instance is running
if [[ -e "$LOCKFILE" ]]; then
    PID=$(cat "$LOCKFILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && $(kill -0 $PID 2>/dev/null) ; then
            echo "Another instance of this script is already running (PID: $PID). Exiting."
            exit 1
        
    fi
    echo "Removing stale lock file: $LOCKFILE"
    rm -f "$LOCKFILE"
fi


# Try to acquire the lock
exec 212>"$LOCKFILE"  # Open the lock file with a specific file descriptor (212)
if ! flock -n 212; then
    echo "Could not lock the lockfile $LOCKFILE. Exiting."
    exit 1
fi

# Write the script's PID to the lock file (optional but useful for debugging)
echo $$ > "$LOCKFILE"

# lock is automatically release upon exit

trap "rm -f $LOCKFILE" EXIT  # Ensure the lock file is deleted on exit

# use "libinput --list-events" to identify the tablet mode switch. 
# usually it will be something like this:
# Device:           Tablet Mode Switch
# Kernel:           /dev/input/event3
tabModeSwitch="/dev/input/event3"

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
kbdID=12
#kbdMaster=3

#Check if it's in tablet mode

killall monitor-sensor
monitor-sensor > /dev/shm/sensor.log 2>&1 &
prevmode="0"

libinput debug-events --device "$tabModeSwitch" | while read line; do
mode=$(echo "$line" | grep -o 'state [0-9]' | awk '{print $2}')
if [ "$mode" = "1" ]; then
#	echo "tablet"
# disable keyboard
xinput disable $kbdID
# disable touchpad
xinput disable $tpadID
else 
# 	echo "laptop"
# enable keyboard
xinput enable $kbdID
# enable touchpad
xinput enable $tpadID

fi
prevmode=$mode
done
