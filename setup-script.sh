#!/bin/sh

USER_LOGIN="idiot"
TIMEDATECTL_LOCAL_RTC=1

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu

echo ""
echo "PACMAN"
echo ""
# Apparently these are required by a lot of things. Need them to be installed first or it asks to pick and fails.
# Need to find a way to replace pipewire-media-session with wireplumber that doesn't break pulseaudio.
INSTALL_PACKAGES="pipewire-jack pipewire-media-session noto-fonts"
pacman -S --needed --noconfirm $INSTALL_PACKAGES

echo ""
echo "PACMAN"
echo ""
INSTALL_PACKAGES="ntfs-3g ufw xf86-video-amdgpu mesa lib32-mesa nvidia nvidia-utils lib32-nvidia-utils sddm firefox git"
pacman -S --needed --noconfirm $INSTALL_PACKAGES

echo ""
echo "PACMAN"
echo ""
# have to confirm xorg group.
INSTALL_PACKAGES="xorg"
pacman -S --needed --noconfirm $INSTALL_PACKAGES

echo ""
echo "PACMAN"
echo ""
# have to make choices for plasma group.
INSTALL_PACKAGES="plasma phonon-qt5-vlc"
pacman -S --needed --noconfirm $INSTALL_PACKAGES

echo ""
echo "PACMAN"
echo ""
# have to make choices for kde-applications group.
INSTALL_PACKAGES="kde-applications python-pyqt5 fcron tesseract-data-eng"
pacman -S --needed --noconfirm $INSTALL_PACKAGES


systemctl enable ufw.service
ufw enable
ufw default deny
ufw allow from 192.168.0.0/24
ufw limit ssh

timedatectl set-local-rtc "$TIMEDATECTL_LOCAL_RTC"

mkdir "/etc/sddm.conf.d"
echo "[Autologin]"                              >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Relogin=true"                             >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Session=plasma"                           >> "/etc/sddm.conf.d/kde_settings.conf"
echo "User=idiot"                               >> "/etc/sddm.conf.d/kde_settings.conf"
echo ""                                         >> "/etc/sddm.conf.d/kde_settings.conf"
echo "[General]"                                >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Haltcommand=/usr/bin/systemctl poweroff"  >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Numlock=on"                               >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Rebootcommand=/usr/bin/systemctl reboot"  >> "/etc/sddm.conf.d/kde_settings.conf"
echo ""                                         >> "/etc/sddm.conf.d/kde_settings.conf"
echo "[Theme]"                                  >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Current=breeze"                           >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Cursortheme=breeze_cursors"               >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Font=Noto Sans,11,-1,5,50,0,0,0,0,0"      >> "/etc/sddm.conf.d/kde_settings.conf"

systemctl enable sddm.service

mkdir -p "/home/${USER_LOGIN}/.config"
echo "[Layout]"         >> "/home/${USER_LOGIN}/.config/kxkbrc"
echo "LayoutList=gb"    >> "/home/${USER_LOGIN}/.config/kxkbrc"
echo "Use=true"         >> "/home/${USER_LOGIN}/.config/kxkbrc"

echo "[Keyboard]"	>> "/home/${USER_LOGIN}/.config/kcminputrc"
echo "NumLock=0"	>> "/home/${USER_LOGIN}/.config/kcminputrc"

#sudo swapoff /dev/MyVolGroup2/swap && sudo fuser -km /mnt && sudo umount -R /mnt && sudo vgchange -a n MyVolGroup2 && sudo cryptsetup close cryptlvm2
