#!/bin/sh

messageSleep="0.2"
renderSleep="0.1"

termuxBin="/data/data/com.termux/files/usr/bin"
termuxHome="/data/data/com.termux/files/home"
managerPath="$termuxHome/.archlinux-manager"
archPath=""
tmpPath=""
zipPath=""
zipName="ArchLinuxARM-aarch64-latest.tar.gz"

termux_setup="0"
archlinux_setup="0"
container_path="/data/local/container"
default_account="root"
mount_sdcard="1"

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

warning() {
    sleep "$messageSleep"
    printf "[\e[0;33mWARNING\e[0m] - %s\n" "$1"
}

success() {
    sleep "$messageSleep"
    printf "[\e[0;32mSUCCESS\e[0m] - %s\n" "$1"
}

info() {
    sleep "$messageSleep"
    printf "[\e[0;34mINFO\e[0m] - %s\n" "$1"
}

error() {
    sleep "$messageSleep"
    printf "[\e[0;31mERROR\e[0m] - %s\n" "$1" >&2
}

pause() {
    if [ -z "$1" ]; then
        info "Press any key to continue"
    else 
        info "$1"
    fi
    read -rsn1
}

save_archlinux_config() {
   cat <<EOF | tee "$termuxHome/.archlinux-manager/config.config" >/dev/null
termux_setup="$termux_setup"
archlinux_setup="$archlinux_setup"
container_path="$container_path"
default_account="$default_account"
mount_sdcard="$mount_sdcard"
EOF
}

load_archlinux_config() {
    if ! test -f "$termuxHome/.archlinux-manager/config.config"; then
        save_archlinux_config
    fi
    . "$termuxHome/.archlinux-manager/config.config"
    if [ -z "$container_path" ]; then
        error "Failed to read config file"
        printf "Do you want to reset configs to fix this problem? (Y/N): "
        read opt
        case "$opt" in
            [yYtT])
                su -c "rm -f \"$termuxHome/.archlinux-manager/config.config\""
                load_archlinux_config
            ;;
            *)
            error "Failed to parse config file"
            exit 1
            ;;
        esac
    fi
    archPath="$container_path/arch"
    tmpPath="$container_path/tmp"
    zipPath="$tmpPath/$zipName"
}

is_arch_booted() {
    (
        set -e
        mountpoint -q "$archPath/proc"
        mountpoint -q "$archPath/sys"
        mountpoint -q "$archPath/dev"
        mountpoint -q "$archPath/dev/pts"
    ) > /dev/null 2>&1 || {
        return 1
    }
}

get_arch_status() {
    if ! su -c "test -d \"$archPath\"" >/dev/null 2>&1 || [ -z "$(su -c "ls -A \"$archPath\"" 2>/dev/null)" ]; then
        echo "UNAVAILABLE"
        return 2
    fi
    is_arch_booted
}

arch_boot() {
    if [ "$(get_arch_status)" == "UNAVAILABLE" ]; then
        warning "ArchLinux is not installed on this device."
        exit 0
    fi
    info "Booting ArchLinux"
    if is_arch_booted; then
        warning "ArchLinux is already running"
        return 0
    fi
    if ! mount -o remount,dev,suid /data > /dev/null 2>&1; then
        error "Failed to remount /data"
        return 1
    fi
    success "Remounted /data"
    if ! mount --bind /dev "$archPath/dev" > /dev/null 2>&1; then
        error "Failed to bind /dev"
        return 1
    fi
    success "Mounted /dev"
    if ! mount --bind /sys "$archPath/sys" > /dev/null 2>&1; then
        error "Failed to bind /sys"
        return 1
    fi
    success "Mounted /sys"
    if ! mount --bind /proc "$archPath/proc" > /dev/null 2>&1; then
        error "Failed to bind /proc"
        return 1
    fi
    success "Mounted /proc"
    if ! mount --bind /dev/pts "$archPath/dev/pts" > /dev/null 2>&1; then
        error "Failed to bind /dev/pts"
        return 1
    fi
    success "Mounted /dev/pts"
    if [ "$mount_sdcard" == "1" ]; then
        if ! test -d "$archPath/media/sdcard" > /dev/null 2>&1; then
            warning "Cannot find /media/sdcard"
            if ! mkdir -p "$archPath/media/sdcard" > /dev/null 2>&1; then
                error "Failed to create /media/sdcard"
            fi
            success "Created /media/sdcard"
        fi
        if ! mount --bind /sdcard "$archPath/media/sdcard" > /dev/null 2>&1; then
            error "Failed to bind /dev"
            exit 1
        fi
        success "Mounted /media/sdcard"
    fi
}

arch_shutdown() {
    info "Shutting down ArchLinux"
    if ! is_arch_booted; then
        warning "ArchLinux is already disabled"
        return 0
    fi
    # TODO: make faster finder
    for p in /proc/[0-9]*/exe; do
        exe=$(readlink "$p" 2>/dev/null) || continue

        case "$exe" in
            "$archPath"/*)
                pid=${p#/proc/}
                pid=${pid%/exe}

                if kill -9 "$pid" > /dev/null 2>&1; then
                    success "Killed process PID $pid"
                else
                    error "Failed to kill process PID $pid"
                fi
            ;;
        esac
    done
    if umount -l "$archPath/media/sdcard" > /dev/null 2>&1; then
        success "Unmounted /media/sdcard"
    fi
    if umount -l "$archPath/dev/pts" > /dev/null 2>&1; then
        success "Unmounted /dev/pts"
    fi
    if umount -l "$archPath/proc" > /dev/null 2>&1; then
        success "Unmounted /proc"
    fi
    if umount -l "$archPath/sys" > /dev/null 2>&1; then
        success "Unmounted /sys"
    fi
    if umount -l "$archPath/dev" > /dev/null 2>&1; then
        success "Unmounted /dev"
    fi
    if mount -o remount,nodev,nosuid /data > /dev/null 2>&1; then
        success "Remounted /data"
    fi
}

arch_setup() {
    info "Now first boot setup process will run"
    info "After that just login afterward"
    chroot "$archPath" /bin/bash -lc '
        set -e
        groupadd -f -g 3001 aid_bt       2>/dev/null || true
        groupadd -f -g 3002 aid_bt_net   2>/dev/null || true
        groupadd -f -g 3003 aid_inet     2>/dev/null || true
        groupadd -f -g 3004 aid_net_raw  2>/dev/null || true
        groupadd -f -g 3005 aid_admin    2>/dev/null || true
        groupadd -f storage 2>/dev/null || true
        groupadd -f wheel   2>/dev/null || true
        usermod -a -G aid_bt,aid_bt_net,aid_inet,aid_net_raw,aid_admin,storage root
        rm -f /etc/hosts
        cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
EOF
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
EOF
        sed -i "/^[[:space:]]*CheckSpace/s/^/#/" /etc/pacman.conf
        pacman-key --init
        pacman-key --populate archlinuxarm
        pacman-key --refresh-keys
        pacman -Sy --noconfirm sudo
        sed -i "s/^[[:space:]]*#[[:space:]]*\\(%wheel[[:space:]]\\+ALL=(ALL:ALL)[[:space:]]\\+ALL\\)/\\1/" /etc/sudoers
    ' || {
        error "Failed to setup ArchLinux permissions"
        warning "This can make the ArchLinux environment unusable on your device"
        pause
        return 1
    }
    archlinux_setup="1"
    save_archlinux_config
    success "ArchLinux was successfully setup"
}

arch_login() {
    unset LD_PRELOAD
    export PATH="/bin:/sbin:/usr/bin:/usr/sbin"
    export TERM="$TERM"
    export TMPDIR="/tmp"
    if [ "$archlinux_setup" == "0" ]; then
        arch_setup
    else
        info "Logging in as $default_account"
        chroot "$archPath" /bin/su - "$default_account"
    fi
}

download_zip() {
    info "Downloading ArchLinux Generic Zip for aarch64(arm64)"
    if curl -L --progress-bar -o "$zipPath" "http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"; then
        success "ArchLinux Generic Zip was downloaded successfully"
        info "File is located at $zipPath"
    else 
        error "Unknown error while downloading ArchLinux Generic Zip"
        rm -rf "$archPath"
        rm -rf "$zipPath"
        exit 1
    fi
}

arch_install() {
    info "Installing ArchLinux at $archPath"
    if [ "$(get_arch_status)" != "UNAVAILABLE" ]; then
        warning "ArchLinux is already install on this device. If you want you can use \"reinstall\" option"
        exit 0
    else
        info "Creating ArchLinux container at $archPath"
        mkdir -p "$archPath"
    fi
    if ! test -d "$tmpPath"; then
        mkdir -p "$tmpPath"
    fi
    if test -f "$zipPath"; then
        info "ArchLinux Generic Zip was found at $tmpPath"
    else
        warning "ArchLinux Generic Zip was not found"
        download_zip
    fi
    info "Unpacking ArchLinux Generic Zip to $archPath"
    if "$termuxBin/tar" -xpf "$zipPath" -C "$archPath" > /dev/null 2>&1; then
        success "Archive was successfully unpacked to $archPath"
    else
        error "Failed to unpack archive"
        rm -rf "$archPath"
        exit 1
    fi
}

arch_uninstall() {
    if is_arch_booted; then
        info "ArchLinux is booted"
        arch_shutdown
    fi
    info "Uninstalling ArchLinux from $archPath"
    archlinux_setup="0"
    save_archlinux_config
    if ! rm -rf "$archPath" > /dev/null 2>&1; then
        error "Failed to uninstall ArchLinux"
        exit 1
    fi
    success "ArchLinux was successfully uninstalled"
}

arch_reinstall() {
    info "Reinstaling your ArchLinux"
    (
        arch_uninstall
    )
    arch_install
}

arch_clean_zip() {
    info "Removing $zipName file from $tmpPath"
        if ! test -f "$zipPath"; then
        warning "Zip was already removed"
        exit 0
    fi
    if ! rm -f "$zipPath" > /dev/null 2>&1; then
        error "Failed to remove Zip file"
        exit 1
    fi
    success "Zip file was successfully removed"
}

arch_clean_all() {
    info "Removing every file releated to ArchLinux on this device"
    (
        set -e
        arch_uninstall
        (
            arch_clean_zip
        )
        rm -rf "$container_path" > /dev/null 2>&1
    ) || {
        error "Failed to remove every file"
        exit 1
    }
    success "All files releated with ArchLinux were removed from this device"
}

load_archlinux_config
case "$1" in
    boot)
        clear
        arch_logo
        arch_boot
        ;;
    shutdown)
        clear
        arch_logo
        arch_shutdown
        ;;
    login)
        clear
        arch_logo
        if ! is_arch_booted; then
            if ! arch_boot; then
                pause
            fi
            sleep 1s
        fi
        clear
        arch_logo
        arch_login
        if is_arch_booted; then
            clear
            arch_logo
            if ! arch_shutdown; then
                pause
            fi
        fi
        ;;
    install)
        clear
        arch_logo
        arch_install
        ;;
    uninstall)
        clear
        arch_logo
        arch_uninstall
        ;;
    reinstall)
        clear
        arch_logo
        arch_reinstall
        ;;
    clean_all)
        clear
        arch_logo
        arch_clean_all
        ;;
    clean_zip)
        clear
        arch_logo
        arch_clean_zip
        ;;
esac