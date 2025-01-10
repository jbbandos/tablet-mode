## ChromeUltrabook scripts

Scripts to automate stuff on chromebooks converted to ultrabooks.  
If you followed the documentation from [CHRULTRABOOK](https://docs.chrultrabook.com), you hopefully now have a fully working linux laptop.   
These scripts are to enable a couple of things that were missing on mine:  

Standalone scripts, no longer maintained:
- auto-rotate_screen.sh - as  the name indicates, enables auto-rotation  
- tabmode.sh - switches between tablet and laptop mode automatically, disabling keyboard and touchpad when in tablet mode  

Integrated script:
- convertible.sh - Includes auto-rotate and tablet mode support. If you have Onboard on-screen keyboard installed, it will enable it to auto-show in tablet mode. Full daemon mode, detects if another instance is running, dies if any of the child process die.

The script needs to be run from a terminal or at startup of your X session. My preferred approach is to copy the script to /usr/local/bin, make it executable, and add it to the session startup (depends on window manager).
Your user should be in the input group - do the following command, replacing $username with your username:
```
sudo gpasswd --add $username input
```
then logout and log back in.

Dependencies:
You'll need the following packages (or equivalent for your distribution) installed:
    - "psmisc", "libinput-tools","xrandr", "xinput", "inotify-tools" and "iio-sensor-proxy"
