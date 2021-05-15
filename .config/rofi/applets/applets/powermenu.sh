#!/usr/bin/env bash

## Author  : Aditya Shakya
## Mail    : adi1090x@gmail.com
## Github  : @adi1090x
## Twitter : @adi1090x
@import "~/.cache/wal/colors-rofi-dark"
style="$($HOME/.config/rofi/applets/applets/style.sh)"

dir="$HOME/.config/rofi/applets/applets/configs/$style"
rofi_command="rofi -theme $dir/powermenu.rasi"

uptime=$(uptime -p | sed -e 's/up //g')
cpu=$(sh ~/.config/rofi/bin/usedcpu)
memory=$(sh ~/.config/rofi/bin/usedram)

# Options
shutdown=""
reboot=""
lock=""
suspend=""
logout=""

# Confirmation


# Variable passed to rofi
options="$logout\n$lock\n$shutdown\n$reboot\n$suspend"

chosen="$(echo -e "$options" | $rofi_command -p "UP - $uptime" -dmenu -selected-row 2)"
case $chosen in
    $shutdown)
		systemctl poweroff
	;;
    $reboot)
		systemctl reboot
	;;
    $lock)
		betterlockscreen -l blur
	;;
    $suspend)
		mpc -q pause
		amixer set Master mute
		systemctl suspend
	;;

    $logout)
		i3-msg exit
	;;
esac
