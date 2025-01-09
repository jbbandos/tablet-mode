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
