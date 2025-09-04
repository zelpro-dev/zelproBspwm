#!/bin/sh

ip_target=$(cat ~/.config/bin/target | awk '{print $1}')
name_target=$(cat ~/.config/bin/target | awk '{print $2}')

if [ $ip_target ] && [ $name_target ]; then
	echo "%{F#FFFFFF} $ip_target - $name_target"
elif [ $(cat ~/.config/bin/target | wc -w) -eq 1 ]; then
	echo "%{F#FFFFFF}什$ip_target"
else
	echo "%{F#FFFFFF}ﲅ %{u-} No target"
fi

