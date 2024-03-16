#!/bin/bash

#github:Mesflit

# Root erişimini kontrol et
if [ "$(id -u)" -ne 0 ]; then
  echo "Bu scripti çalıştırmak için root yetkilerine ihtiyacınız var."
  exit 1
fi

echo "KDE plasma kurmak istiyorsanız lütfen 15 saniye bekleyin"
sleep 15

# make.conf dosyasında var olan USE satırını alıp değişkene atayın
EXISTING_USE=$(grep '^USE=' /etc/portage/make.conf)

# Var olan USE satırına gles2 ve wayland bayraklarını ekleyin
echo "${EXISTING_USE} gles2 wayland kde qt5 gpg curl http2" > /etc/portage/make.conf


echo ">=kde-plasma/kwin-5.27.11 lock
>=kde-frameworks/kconfig-5.115.0 qml
>=x11-libs/gtk+-3.24.41 -wayland
>=dev-qt/qtgui-5.15.12-r2 wayland
>=media-libs/mesa-24.0.2 wayland
>=kde-frameworks/prison-5.115.0 qml
>=kde-frameworks/kitemmodels-5.115.0 qml" | sudo tee -a /etc/portage/package.use/plasma

clear
read -p "Kullanıcı adınızı girin: " USERNAME
gpasswd -a ${USERNAME} video
clear
echo "KDE kurulumu başlatılıyor..."

sudo emerge --sync
sudo emerge -uDN @world
sudo emerge kde-plasma/plasma-meta

# KDE Apps isteğe bağlı olarak indir
read -p "KDE uygulamalarını kurmak istiyor musunuz? (E/H): " CHOICE_KAPPS
if [[ "${CHOICE_KAPPS^^}" == "E" ]]; then
    sudo emerge kde-apps/kde-apps-meta
    echo "KDE uygulamaları kuruldu."
else
    echo "KDE uygulamaları kurulmadı."
fi

# SDDM'yi isteğe bağlı olarak indir
read -p "SDDM'yi kurmak istiyor musunuz? (E/H): " CHOICE_SDDM
if [[ "${CHOICE_SDDM^^}" == "E" ]]; then
    sudo emerge x11-misc/sddm
    sudo 
    echo "SDDM kuruldu."
else
    echo "SDDM kurulmadı."
fi

# SDDM ayarları
sudo usermod -a -G video sddm
mkdir -p /etc/sddm.conf.d
echo "[X11]
DisplayCommand=/etc/sddm/scripts/Xsetup" | sudo tee -a /etc/sddm.conf.d/override.conf
mkdir -p /etc/sddm/scripts
touch /etc/sddm/scripts/Xsetup
chmod a+x /etc/sddm/scripts/Xsetup
echo "setxkbmap tr" | sudo tee -a /etc/sddm/scripts/Xsetup
sudo emerge gui-libs/display-manager-init
echo "DISPLAYMANAGER=\"sddm\"" | sudo tee -a /etc/conf.d/display-manager
sudo rc-update add display-manager default
echo "KDE kurulumu tamamlandı. 10 saniye sonra Sistem yeniden başlatılacak. github:Mesflit"
sleep 10
sudo reboot
