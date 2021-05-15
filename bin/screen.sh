#!/bin/bash

if xrandr | egrep -q "^DP1 connected"; then
    xrandr --output eDP1 --off --output DP1 --primary --mode 3840x2160 --pos 0x0 --rotate normal --output DP2 --off --output DP3 --off --output DP4 --off --output VIRTUAL1 --off
else
    xrandr --output eDP1 --primary --mode 2560x1600 --pos 0x0 --rotate normal --output DP1 --off --output DP2 --off --output DP3 --off --output DP4 --off --output VIRTUAL1 --off
fi

awesome-client 'awesome.restart()'

