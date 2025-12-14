#!/bin/bash

termuxBin="/data/data/com.termux/files/usr/bin"
managerPath="$HOME/.archlinux-manager"
messageSleep="0.2"

arch_logo() {
    printf "\e[36m                  ▄
                 ▄█▄
                ▄███▄
               ▄█████▄
              ▄███████▄
             ▄ ▀▀██████▄
            ▄██▄▄ ▀█████▄
           ▄█████████████▄
          ▄███████████████▄
         ▄█████████████████▄
        ▄███████████████████▄
       ▄█████████▀▀▀▀████████▄
      ▄████████▀      ▀███████▄
     ▄█████████        ████▀▀██▄
    ▄██████████        █████▄▄▄
   ▄██████████▀        ▀█████████▄
  ▄██████▀▀▀              ▀▀██████▄
 ▄███▀▀                       ▀▀███▄
▄▀▀                               ▀▀▄\e[0m\n\n"
}

success() {
    sleep "$messageSleep"
    printf "[\e[32mSUCCESS\e[0m] - %s\n" "$1"
}

info() {
    sleep "$messageSleep"
    printf "[\e[34mINFO\e[0m] - %s\n" "$1"
}

error() {
    sleep "$messageSleep"
    printf "[\e[31mERROR\e[0m] - %s\n" "$1" >&2
}

clear
arch_logo
info "Installing ArchLinux manager for Termux"

if [ -f "$managerPath/archlinux-manager.sh" ]; then
    rm -f "$managerPath/archlinux-manager.sh"
fi

if [ -f "$termuxBin/archlinux" ]; then
    rm -f "$termuxBin/archlinux"
fi

(
    set -e
    curl -L --progress-bar -o "$termuxBin/archlinux" "https://raw.githubusercontent.com/MrDeath404/chroot-archlinux-aarch64/main/archlinux"
    chmod +x "$termuxBin/archlinux"
    mkdir -p "$managerPath"
    curl -L --progress-bar -o "$managerPath/archlinux-manager.sh" "https://raw.githubusercontent.com/MrDeath404/chroot-archlinux-aarch64/main/archlinux-manager.sh"
    chmod +x "$managerPath/archlinux-manager.sh"
) || {
    error "Failed to install manager. Try again"
    exit 1
}

success "ArchLinux manager was successfully installed"
info "You can access ArchLinux Manager \"archlinux\" anywhere in your Termux"