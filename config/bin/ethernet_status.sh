#!/bin/sh
echo "%{F#FFFFFF} $(/usr/sbin/ifconfig wlan0 | grep 'inet ' | awk '{print $2}')"
