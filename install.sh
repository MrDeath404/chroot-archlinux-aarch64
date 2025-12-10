success() {
    echo -e "[\033[32mSUCCESS\033[0m] - $1"
}

info(){
    echo -e "[\033[34mINFO\033[0m] - $1"
}

error(){
    echo -e "[\033[31mERROR\033[0m] - $1" >&2
}

info "Installing ArchLinux manager for Termux"
if [ -f "./archlinux" ]; then
    rm -f "./archlinux"
fi
curl -L -o archlinux "https://raw.githubusercontent.com/MrDeath404/chroot-archlinux-aarch64/main/archlinux"
chmod +x ./archlinux
mv ./archlinux $HOME/../usr/bin

if archlinux; then
    success "ArchLinux manager was successfully installed"
    info "You can access ArchLinux Manager \"archlinux\" anywhere in your Termux"
    info "Now you can setup enviroment by \"archlinux setup\""
else
    error "Failed to install manager. Try again"
    exit 1
fi