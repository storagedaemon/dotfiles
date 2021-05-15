#!/usr/bin/env bash

## Author  : Aditya Shakya
## Mail    : adi1090x@gmail.com
## Github  : @adi1090x
## Twitter : @adi1090x

style="$($HOME/.config/rofi/applets/applets/style.sh)"

dir="$HOME/.config/rofi/applets/applets/configs/$style"
rofi_command="rofi -theme $dir/screenshot.rasi"


# Options
screen=""
area=""
window=""

# Variable passed to rofi
options="$window\n$screen\n$area"

chosen="$(echo -e "$options" | $rofi_command -p 'scrot' -dmenu -selected-row 1)"
case $chosen in
    $screen)
		sleep 1; scrot 'Screenshot_%Y-%m-%d-%S_$wx$h.png' -e 'mv $f ~/Pictures/Screenshots/ ; sxiv ~/Pictures/Screenshots/$f'
        ;;
    $area)
		scrot -s 'Screenshot_%Y-%m-%d-%S_$wx$h.png' -e 'mv $f ~/Pictures/Screenshots/ ; sxiv ~/Pictures/Screenshots/$f'

        ;;
    $window)
		sleep 1; scrot -u 'Screenshot_%Y-%m-%d-%S_$wx$h.png' -e 'mv $f ~/Pictures/Screenshots/ ; sxiv ~/Pictures/Screenshots/$f'
        ;;
esac

