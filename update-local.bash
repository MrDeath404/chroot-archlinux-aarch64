#!/bin/bash

termuxBin="/data/data/com.termux/files/usr/bin"
termuxHome="/data/data/com.termux/files/home"

adb push archlinux /data/local/tmp/archlinux
adb push .archlinux-manager/archlinux-manager.sh /data/local/tmp/archlinux-manager.sh
adb shell su -c "mv /data/local/tmp/archlinux \"$termuxBin/archlinux\""
adb shell su -c "mkdir -p \"$termuxHome/.archlinux-manager\""
adb shell su -c "mv /data/local/tmp/archlinux-manager.sh \"$termuxHome/.archlinux-manager/archlinux-manager.sh\""