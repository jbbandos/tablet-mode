## ChromeUltrabook scripts

Scripts to automate stuff on chromebooks converted to ultrabooks
If you followed the documentation from [text](https://docs.chrultrabook.com),
you hopefully now have a fully working linux laptop. 
These scripts are to enable a couple of things that were missing on mine:

- auto-rotate_screen.sh - as  the name indicates, enables auto-rotation
- tabmode.sh - switches between tablet and laptop mode automatically,
disabling keyboard and touchpad when in tablet mode

Both scripts need to be run from a terminal or at startup of your X session
Your user should be in the input group - do the following command, replacing
$username with your username:
```
sudo gpasswd --add $username input
```
then logout and back in
