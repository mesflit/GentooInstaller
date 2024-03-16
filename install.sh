#!/bin/bash

#github:Mesflit

# Kullanıcı girdilerini al
read -p "Create Root Password: " ROOT_PASSWORD
read -p "Create UserName: " USERNAME
read -p "Create User Password: " USER_PASSWORD

read -p "How much should the Swap area be, for example, 8G or 512M. Default is 4G (leave it blank to use the default).: " SWAP_SIZE

if [ -z "$SWAP_SIZE" ]; then
    SWAP_SIZE="4G"  # Varsayılan swap alanı değeri
    echo "Swap area not specified. Defaulted to 4G."
    echo "wait 10 seconds"
    sleep 10
fi

clear
echo "Please select the graphics driver:"
echo "1. AMD Drivers"
echo "2. NVIDIA Drivers"
read -p "Make your selection (1/2): " CHOICEGD

case $CHOICEGD in
    1)
        GRAP_DRIVERS="amdgpu radeonsi radeon"
        ;;
    2)
        GRAP_DRIVERS="nouveau"
        ;;
    *)
        echo "Invalid selection! Defaulted to AMD Drivers."
        GRAP_DRIVERS="amdgpu radeonsi radeon"
	echo "wait 10 seconds"
	sleep 10
	;;
esac

clear
lsblk
read -p "Enter the disk name. Usually it's 'nvme0n1': " DISK_NAME
clear
eselect profile list | head -n 15
read -p "Select Portage profile. Do not choose systemd profiles. If you want KDE, select plasma. Enter only the number value. For example, enter 8: " PROFILE
clear
echo "Selected Root user password: ${ROOT_PASSWORD}
Selected UserName: ${USERNAME}
Selected User password: ${USER_PASSWORD}
Selected SWAP area: ${SWAP_SIZE}
Selected Graphics Drivers: ${GRAP_DRIVERS}
Selected Disk name: ${DISK_NAME}
Selected Portage Profile: ${PROFILE}
The installation process will start in 10 seconds.
"
sleep 10

# EFI bölümü oluşturma
echo "Creating the EFI partition..."
echo -e "n\n1\n\n+1G\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nn\n3\n\n\nw" | fdisk /dev/${DISK_NAME}

# Dosya sistemleri oluşturma ve bağlama
echo "Creating file systems..." 
mkfs.ext4 /dev/${DISK_NAME}p3
mkfs.fat /dev/${DISK_NAME}p1
mkswap /dev/${DISK_NAME}p2
swapon /dev/${DISK_NAME}p2
mount /dev/${DISK_NAME}p3 /mnt/gentoo

#Tarih Ayarlanıyor
chronyd -q

# Temel sistem kurulumu
echo "Installing the base system..."
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-*.tar.xz -O /mnt/gentoo/stage3.tar.xz
tar xpvf /mnt/gentoo/stage3.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo/
rm /mnt/gentoo/stage3.tar.xz

#make.conf
rm /mnt/gentoo/etc/portage/make.conf
echo "COMMON_FLAGS="-march=native -O2 -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"

INPUT_DEVICES="libinput"

MAKEOPTS="-j8 -l8"
USE="X -systemd dracut pulseaudio pipewire flatpak alsa readline sound-server ssl v4l pam vulkan opengl dbus gtk modemmanager widget drun windowmode screencast vdpau ${GRAP_DRIVERS} zink"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${GRAP_DRIVERS}"
ACCEPT_KEYWORDS="~amd64"


GRUB_PLATFORMS="efi-64"

LC_MESSAGES=C.utf8" > /mnt/gentoo/etc/portage/make.conf

#Mirror
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf


mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# Temel sistem yapılandırması
echo "Configuring the base system..."
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/dev
mount --make-slave /mnt/gentoo/run
chroot /mnt/gentoo /bin/bash << EOF
source /etc/profile
export PS1="(chroot) \$PS1"
mkdir /efi
mount /dev/nvme0n1p1 /efi
emerge-webrsync
emerge --sync
eselect profile set ${PROFILE}
emerge --verbose --update --deep --newuse @world
echo "Europe/Berlin" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set 4
env-update && source /etc/profile && export PS1="(chroot) \$PS1"
emerge sys-kernel/linux-firmware
emerge sys-kernel/gentoo-kernel-bin
eselect kernel set 1
echo "/dev/${DISK_NAME}p1        /efi    vfat    defaults    0 2
/dev/${DISK_NAME}p3        /    ext4    noatime,discard        0 1
/dev/${DISK_NAME}p2        none    swap    sw        0 0" > /etc/fstab
echo "gentoo" > /etc/conf.d/hostname
echo "127.0.1.1    gentoo.localdomain    gentoo" > /etc/hosts
passwd
echo "root:${ROOT_PASSWORD}" | chpasswd
useradd -m -G users,wheel,audio -s /bin/bash ${USERNAME}
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
sed -i '/^keymap=/s/US/US/' /etc/conf.d/keymaps
emerge sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers
emerge sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
echo "Installation completed. If you want a desktop environment, you can install it using the scripts in GentooInstaller/desktops. Restarting in 10 seconds... Github:Mesflit"
sleep 10 
reboot
EOF

