#!/bin/bash

# based on https://wiki.postmarketos.org/wiki/Auto-rotation
# added support for only working if in tablet mode
# extended to enable/disable keyboard and touchpad
# dependencies:
# "xrandr", "xinput", "inotify-tools" and "iio-sensor-proxy"
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
    if [ -n "$PID" ] && $(kill -0 $PID 2>/dev/null) ; then
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

trap "rm -f $LOCKFILE" EXIT  # Ensure the lock file is deleted on exit

# edit the following for your specific system events and devices
# use "xinput --list" to identify the touchscreen device, keyboard, etc
touchScreen="Elan Touchscreen"

while inotifywait -e modify /dev/shm/sensor.log; do

  ORIENTATION=$(tail /dev/shm/sensor.log | grep 'orientation' | tail -1 | grep -oE '[^ ]+$')

  case "$ORIENTATION" in

    normal)
      xrandr -o normal
      xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
      ;;
    left-up)
      xrandr -o left
      xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
      ;;
    bottom-up)
      xrandr -o inverted
      xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
      ;;
    right-up)
      xrandr -o right
      xinput set-prop "$touchScreen" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
      ;;

  esac
done
