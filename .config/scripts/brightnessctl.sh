#!/bin/zsh

brightness_value=$(brightnessctl g)
brightness_max=$(brightnessctl m)
brightness=$(($brightness_value * 100 / $brightness_max))

echo " $brightness %"
