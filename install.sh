#!/bin/bash

success() {
    printf "[\033[32mSUCCESS\033[0m] - %s\n" "$1"
}

info() {
    printf "[\033[34mINFO\033[0m] - %s\n" "$1"
}

error() {
    printf "[\033[31mERROR\033[0m] - %s\n" "$1" >&2
}

clear
info "Installing ArchLinux manager for Termux"
if [ -f "./archlinux" ]; then
    rm -f "./archlinux"
fi
curl -L -o archlinux "https://raw.githubusercontent.com/MrDeath404/chroot-archlinux-aarch64/main/archlinux"
chmod +x ./archlinux
mv ./archlinux $HOME/../usr/bin

if archlinux; then
echo -e "\033[36m
                   -\`
                  .o+\`
                 \`ooo/
                \`+oooo:
               \`+oooooo:
               -+oooooo+:
             \`/:-:++oooo+:
            \`/++++/+++++++:
           \`/++++++++++++++:
          \`/+++ooooooooooooo/\`
         ./ooosssso++osssssso+\`
        .oossssso-\`\`\`\`/ossssss+\`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   \`/ossssso+/:-        -:/+osssso+-
  \`+sso+:-\`                 \`.-/+oso:
 \`++:.                           \`-/+/
 .\`                                 \`
\033[0m"

    success "ArchLinux manager was successfully installed"
    info "You can access ArchLinux Manager \"archlinux\" anywhere in your Termux"
    info "Now you can setup enviroment by \"archlinux setup\""
else
    error "Failed to install manager. Try again"
    exit 1
fi