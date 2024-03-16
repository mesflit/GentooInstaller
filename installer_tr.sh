#!/bin/bash

#github:Mesflit

# Kullanıcı girdilerini al
read -p "Root kullanıcı parolası: " ROOT_PASSWORD
read -p "Kullanıcı adı: " USERNAME
read -p "Kullanıcı parolası: " USER_PASSWORD

read -p "Swap alanı ne kadar olsun örneğin 8G veya 512M. Varsayılan 4G (boş bırakarak varsayılanı kullanın): " SWAP_SIZE

if [ -z "$SWAP_SIZE" ]; then
    SWAP_SIZE="4G"  # Varsayılan swap alanı değeri
    echo "Swap alanı belirtilmedi. Varsayılan olarak 4G seçildi."
    echo "10 saniye bekleyiniz"
    sleep 10
fi

clear
echo "Lütfen grafik sürücüsü seçin:"
echo "1. AMD Drivers"
echo "2. NVIDIA Drivers"
read -p "Seçiminizi yapın (1/2): " CHOICEGD

case $CHOICEGD in
    1)
        GRAP_DRIVERS="amdgpu radeonsi radeon"
        ;;
    2)
        GRAP_DRIVERS="nouveau"
        ;;
    *)
        echo "Geçersiz seçim! Varsayılan olarak AMD Drivers seçildi."
        GRAP_DRIVERS="amdgpu radeonsi radeon"
	echo "10 saniye bekleyiniz"
	sleep 10
	;;
esac

clear
lsblk
read -p "Disk adını girin.Genellikle 'nvme0n1' olur:  " DISK_NAME
clear
eselect profile list | head -n 15
read -p "Portage Profili seçin 'systemd olanları seçmeyin' KDE istiyorsanız plasma seçin. Sadece sayı değerini girin. Örneğin 8 gibi: " PROFILE
clear
echo "Seçilen Root kullanıcı parolası: ${ROOT_PASSWORD}
Seçilen Kullanıcı adı: ${USERNAME}
Seçilen Kullanıcı parolası: ${USER_PASSWORD}
Seçilen SWAP alanı: ${SWAP_SIZE}
Seçilen Grafik Sürücüleri: ${GRAP_DRIVERS}
Seçilen Disk adı: ${DISK_NAME}
Seçilen Portage Profili: ${PROFILE}
Kurulum işlemi 10 saniye sonra başlayacak
"
sleep 10

# EFI bölümü oluşturma
echo "EFI bölümü oluşturuluyor..."
echo -e "n\n1\n\n+1G\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nn\n3\n\n\nw" | fdisk /dev/nvme0n1

# Dosya sistemleri oluşturma ve bağlama
echo "Dosya sistemleri oluşturuluyor..." 
mkfs.ext4 /dev/${DISK_NAME}p3
mkfs.fat /dev/${DISK_NAME}p1
mkswap /dev/${DISK_NAME}p2
swapon /dev/${DISK_NAME}p2
mount /dev/${DISK_NAME}p3 /mnt/gentoo

#Tarih Ayarlanıyor
chronyd -q

# Temel sistem kurulumu
echo "Temel sistem kuruluyor..."
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
echo "Temel sistem yapılandırılıyor..."
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
echo "Turkey" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "tr_TR.UTF-8 UTF-8" >> /etc/locale.gen
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
sed -i '/^keymap=/s/US/TRQ/' /etc/conf.d/keymaps
emerge sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers
emerge sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
echo "Kurulum tamamlandı. Eğer Masaüstü ortamı istiyorsanız GentooInstaller/desktops'taki scriptlerden istediğinizi kurabilirsiniz. 10 saniye sonra yeniden başlatılacak... Github:Mesflit"
sleep 10 
reboot
EOF

