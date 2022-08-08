#!/usr/bin/env bash
set -e

function initialise() {
    timedatectl set-ntp true
    systemctl stop reflector.service
}

function prepare_disk() {
    parted -s /dev/sda mklabel msdos mkpart primary ext4 512MiB 100% set 1 boot on
    partprobe -s /dev/sda
    mkfs.ext4 -L root /dev/sda1
    mount /dev/sda1 /mnt
}

function run_pacstrap() {
    rm -rf /etc/pacman.d/gnupg

    # kill all gpg-agent process if running any
    killall gpg-agent

    # initialize the key database
    pacman-key --init

    # populate the archlinux keyring
    pacman-key --populate archlinux

    pacstrap /mnt base linux linux-firmware
    # enable parallel downloads *after* pacstrap to avoid keyring errors
    sed -i "s/#ParallelDownloads/ParallelDownloads/g" /etc/pacman.conf
}

function configure() {
    genfstab -U /mnt >> /mnt/etc/fstab

    arch-chroot /mnt ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    arch-chroot /mnt hwclock --systohc

    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=dvorak" > /mnt/etc/vconsole.conf # Others may want to change this to 'us'

    sed -i "s/#ParallelDownloads/ParallelDownloads/g" /mnt/etc/pacman.conf
    arch-chroot /mnt locale-gen
}

install_tools_services() {
    arch-chroot /mnt pacman -Syu --noconfirm git vim tmux grub dhcpcd openssh wget curl whois sudo dnsutils base-devel python-pip cloud-init parted inetutils

    cat >> /etc/ssh/sshd_config <<EOF
KbdInteractiveAuthentication no
PermitRootLogin no
EOF

    arch-chroot /mnt systemctl enable dhcpcd.service
    arch-chroot /mnt systemctl enable sshd.service
    arch-chroot /mnt systemctl disable systemd-resolved.service
    arch-chroot /mnt systemctl enable cloud-init-local.service
    arch-chroot /mnt systemctl enable cloud-init.service
    arch-chroot /mnt systemctl enable cloud-config.service
    arch-chroot /mnt systemctl enable cloud-final.service
    arch-chroot /mnt ssh-keygen -A
    arch-chroot /mnt sshd -t

    sed -i "s/MODULES=()/MODULES=(hv_vmbus hv_netvsc hv_storvsc)/g" /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -p linux
}

configure_boot() {
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g" /mnt/etc/default/grub

    arch-chroot /mnt grub-install --target=i386-pc /dev/sda
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

azure_agent() {
    # Install MS Azure Linux Agent
    # https://aur.archlinux.org/packages/walinuxagent (2.2.53-1) is too outdated and does not support Python 3.9
    arch-chroot /mnt bash -c 'curl https://codeload.github.com/Azure/WALinuxAgent/tar.gz/refs/tags/v2.3.1.1 | tar xz && cd ./WALinuxAgent-2.3.1.1 && python3 ./setup.py install --register-service'
    arch-chroot /mnt rm -rf ./WALinuxAgent-2.3.1.1

    # Configure swap disk that will be added by Azure
    arch-chroot /mnt sed -i -e "s/EnableSwap=n/EnableSwap=y/g" \
      -e "s/SwapSizeMB=0/SwapSizeMB=8192/g" /etc/waagent.conf
    arch-chroot /mnt mkdir /mnt/resource

    # Enable Agent
    arch-chroot /mnt systemctl enable waagent.service
}

deprovision() {
    # Deprovision the VM for Azure
    arch-chroot /mnt rm -f ~/.bash_history
    rm /mnt/etc/resolv.conf
    arch-chroot /mnt waagent -force -deprovision
}

initialise
prepare_disk
run_pacstrap
configure
install_tools_services
configure_boot
azure_agent
deprovision

echo "All done!"