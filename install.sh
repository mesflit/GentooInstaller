#!/bin/bash

CONF_DIR="/mnt/gentoo/etc/portage/make.conf"

# Include gentoo_config.cfg file
source gentoo_config.cfg

echo "Starting Gentoo automated installation..."

# Disk
# Configure swap
if [ "${SWAP}" = "On" ]; then
  echo -e "n\n1\n\n+${EFI_SIZE}\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nn\n3\n\n\nw" | fdisk /dev/${DISK_NAME}
  mkfs.${FLT} /dev/${DISK_NAME}p3
  mkswap /dev/${DISK_NAME}p2
  swapon /dev/${DISK_NAME}p2
  mkfs.fat /dev/${DISK_NAME}p1
  mount /dev/${DISK_NAME}p3 /mnt/gentoo
  cd /mnt/gentoo
  chronyd -q
  wget ${GENTOO_BASE} -O /mnt/gentoo/stage3.tar.xz
  tar xpvf /mnt/gentoo/stage3.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo/
  rm /mnt/gentoo/stage3.tar.xz
  sed -i 's/^COMMON_FLAGS="\(.*\)"/COMMON_FLAGS="\1 -march=native"/' >> ${CONF_DIR}
  echo 'INPUT_DEVICES="libinput"' >> ${CONF_DIR}
  echo 'MAKEOPTS="${MAKE_OPTS}"' >> ${CONF_DIR}
  echo 'USE=${USE}' >> ${CONF_DIR}
  echo 'ACCEPT_LICENSE="${ACCEPT_LICENSE}"' >> ${CONF_DIR}
  echo 'ACCEPT_KEYWORDS="${ACCEPT_KEYWORDS}"' >> ${CONF_DIR}
  echo 'LC_MESSAGES=C.utf8' >> ${CONF_DIR}
  echo 'GRUB_PLATFORMS="${GRUB_PLATFORMS}"' >> ${CONF_DIR}
  ${CONF}
  mkdir /efi
  mount /dev/${DISK_NAME}p1 /efi
  emerge-webrsync
  emerge --sync
  eselect profile set ${PROFILE}
  emerge --verbose --update --deep --newuse @world
  echo "${TIMEZONE}" > /etc/timezone
  emerge --config sys-libs/timezone-data
  echo "${LOCALE}" > /etc/locale.gen
  locale-gen
  eselect locale set ${LOCALE% *}
  env-update && source /etc/profile
  ${KERINST}
  echo '/dev/nvme0n1p1        /efi    vfat    defaults    0 2' | tee -a /etc/fstab
  echo '/dev/nvme0n1p3        /    ${FLT}    noatime,discard        0 1' | tee -a /etc/fstab
  echo '/dev/nvme0n1p2        none    swap    sw        0 0' | tee -a /etc/fstab
  echo "${HOSTNAME}" > /etc/conf.d/hostname
  echo "127.0.0.1    ${HOSTNAME} localhost" >> /etc/hosts
  echo "root:${ROOT_PASSWORD}" | chpasswd
  sed -i '/^keymap=/s/US/${KEYMAP}/' /etc/conf.d/keymaps
  ${BOOTLOADER}
  useradd -m -G users,wheel,audio -s /bin/bash ${USERNAME}
  echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
  ${OPT_PACKS}
  emerge sudo
  echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
  ${REBOOT}


else
  echo -e "n\n1\n\n+${EFI_SIZE}\nt\n1\nn\n2\n\n\nw" | fdisk /dev/${DISK_NAME}
  mkfs.${FLT} /dev/${DISK_NAME}p2
  mkfs.fat /dev/${DISK_NAME}p1
  mount /dev/${DISK_NAME}p2 /mnt/gentoo
  cd /mnt/gentoo
  chronyd -q
  wget ${GENTOO_BASE} -O /mnt/gentoo/stage3.tar.xz
  tar xpvf /mnt/gentoo/stage3.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo/
  rm /mnt/gentoo/stage3.tar.xz
  sed -i 's/^COMMON_FLAGS="\(.*\)"/COMMON_FLAGS="\1 -march=native"/' >> ${CONF_DIR}
  echo 'INPUT_DEVICES="libinput"' >> ${CONF_DIR}
  echo 'MAKEOPTS="${MAKE_OPTS}"' >> ${CONF_DIR}
  echo 'USE=${USE}' >> ${CONF_DIR}
  echo 'ACCEPT_LICENSE="${ACCEPT_LICENSE}"' >> ${CONF_DIR}
  echo 'ACCEPT_KEYWORDS="${ACCEPT_KEYWORDS}"' >> ${CONF_DIR}
  echo 'LC_MESSAGES=C.utf8' >> ${CONF_DIR}
  echo 'GRUB_PLATFORMS="${GRUB_PLATFORMS}"' >> ${CONF_DIR}
  ${CONF}
  mkdir /efi
  mount /dev/${DISK_NAME}p1 /efi
  emerge-webrsync
  emerge --sync
  eselect profile set ${PROFILE}
  emerge --verbose --update --deep --newuse @world
  echo "${TIMEZONE}" > /etc/timezone
  emerge --config sys-libs/timezone-data
  echo "${LOCALE}" > /etc/locale.gen
  locale-gen
  eselect locale set ${LOCALE% *}
  env-update && source /etc/profile
  ${KERINST}
  echo '/dev/nvme0n1p1        /efi    vfat    defaults    0 2' | tee -a /etc/fstab
  echo '/dev/nvme0n1p2        /    ${FLT}    noatime,discard        0 1' | tee -a /etc/fstab
  echo "${HOSTNAME}" > /etc/conf.d/hostname
  echo "127.0.0.1    ${HOSTNAME} localhost" >> /etc/hosts
  echo "root:${ROOT_PASSWORD}" | chpasswd
  sed -i '/^keymap=/s/US/${KEYMAP}/' /etc/conf.d/keymaps
  ${BOOTLOADER}
  useradd -m -G users,wheel,audio -s /bin/bash ${USERNAME}
  echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
  ${OPT_PACKS}
  emerge sudo
  echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
  ${REBOOT}


fi

