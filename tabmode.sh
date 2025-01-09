#!/bin/bash
#
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
