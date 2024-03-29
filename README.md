# GentooInstaller
written in bash by Mesflit

## Contents
1. [About The Project](about-the-project)
2. [Installation](installation)
3. [Usage](usage)
4. [Example Config](example-config)

## About The Project

The project was created to simplify the installation of Gentoo Linux.

## Installation

clone the repository first
```bash
git clone https://github.com/mesflit/GentooInstaller
cd GentooInstaller
chmod +x *.sh
```

## Usage

First you need to edit gentoo_config.cfg
Its very simple
```bash
nano gentoo_config.cfg
```

You can run the script using the following command:
```bash
./install.sh
```

## Example Config 

```bash
# gentoo_config.cfg

#Gentoo Base
	#OpenRC
	GENTOO_BASE="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-*.tar.xz"

	#SystemD
	#GENTOO_BASE="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-systemd-mergedusr/stage3-amd64-systemd-mergedusr-*.tar.xz"


#File System TYPE (for btrfs you need to install)
FLT="ext4"

#SWAP On or Off
SWAP="On"


# SWAP SIZE
SWAP_SIZE="4G"


# EFI SIZE
EFI_SIZE="1G"


#Timezone 
TIMEZONE="Europe/Berlin"


#Create Root Password
ROOT_PASSWORD="2024"


#Create User
USERNAME="David"


#Create User Password
USER_PASSWORD="2024"


#MAKE_OPTS
MAKE_OPTS="-j$(nproc) -l$(nproc)"
USE="X -systemd dracut pulseaudio pipewire alsa readline sound-server ssl v4l pam vulkan opengl dbus gtk windowmode screencast vdpau ${GRAP_DRIVERS}"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
GRUB_PLATFORMS="efi-64"


#GRAPHIC DRIVERS
GRAP_DRIVERS="nouveau" # for amd


#DISK NAME eg. sda, vda, nvme0n1
#You can see your disk name with "lsblk"
DISK_NAME="nvme0n1"


#Portage profile
#You can type "eselect profile list" to see the list
PROFILE="8"


#Hostname
HOSTNAME="gentoo"


#Locale
LOCALE="en_US.UTF-8 UTF-8"


#KEYMAP
KEYMAP="US"

#KERNEL INSTALL
KERINST=" emerge sys-kernel/linux-firmware
          emerge sys-kernel/gentoo-kernel-bin
          eselect kernel set 1"


#OPTIONAl PACKAGES
OPT_PACKS=" emerge gentoolkit
            emerge elogind
            rc-update add elogind boot
            rc-update add udev sysinit
            rc-update add dbus default
            emerge udisks
            rc-update add lvm boot
            emerge --verbose xorg-drivers
            gpasswd -a ${USERNAME} video"

#GRUB TARGET
TARGET="x86_64-efi"

#BootLoader
BOOTLOADER=" emerge --ask sys-boot/grub:2
             grub-install --target=${TARGET} --efi-directory=/efi
             grub-mkconfig -o /boot/grub/grub.cfg"

#Conf
CONF="  mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
        mkdir --parents /mnt/gentoo/etc/portage/repos.conf
        cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
        cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
        mount --types proc /proc /mnt/gentoo/proc
        mount --rbind /sys /mnt/gentoo/sys
        mount --make-rslave /mnt/gentoo/sys
        mount --rbind /dev /mnt/gentoo/dev
        mount --make-rslave /mnt/gentoo/dev
        mount --bind /run /mnt/gentoo/dev
        mount --make-slave /mnt/gentoo/run
        chroot /mnt/gentoo /bin/bash 
        source /etc/profile"


#REBOOT
REBOOT=' exit
         cd
         umount -l /mnt/gentoo/dev{/shm,/pts,}
         umount -R /mnt/gentoo
         echo "Gentoo automated installation completed successfully! If you want to download a desktop environment, go to GentooInstaller/desktops directory. Github:Mesflit" 
         echo "Restarting in 10 seconds."
         sleep 10         
         reboot'
```
