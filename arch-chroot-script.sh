#!/bin/bash

TIMEDATECTL_LOCAL_RTC=1
TIME_ZONE_INFO="Europe/London"

LOCALES="en_GB.UTF-8 UTF-8"
LANG="en_GB.UTF-8"
KEYMAP="uk"
HOSTNAME="IdiotsLaptop23"

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu

INSTALL_PACKAGES="ntfs-3g ufw xorg xf86-video-amdgpu mesa lib32-mesa nvidia nvidia-utils lib32-nvidia-utils sddm firefox"
pacman -S $INSTALL_PACKAGES

# have to make choices for plasma.
INSTALL_PACKAGES="plasma pipewire-jack wireplumber noto-fonts phonon-qt5-vlc"
pacman -S --noconfirm $INSTALL_PACKAGES

# have to make choices for kde-applications
INSTALL_PACKAGES="kde-applications python-pyqt5 fcron tesseract-data-eng"
pacman -S --noconfirm $INSTALL_PACKAGES


ln -sf "/usr/share/zoninfo/${TIME_ZONE_INFO}" "/etc/localtime"
hwclock --systohc
#timedatectl set-local-rtc "$TIMEDATECTL_LOCAL_RTC"

echo "$LOCALES" >> "/etc/locale.gen"
locale-gen

echo "LANG=${LANG}" >> "/etc/locale.conf"

echo "KEYMAP=${KEYMAP}" >> "/etc/vconsole.conf"

echo "$HOSTNAME" >> "/etc/hostname"

sed -i "s/block/keyboard keymap block encrypt lvm2/g" "/etc/mkinitcpio.conf"

mkinitcpio -P

## DON'T RUN THIS WHEN TESTING. BREAKS GRUB.

mkdir -p /boot/EFI/GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

echo "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=\"${CRYPT_UUID}\":cryptlvm:allow-discards root=${ROOT_PATH//\//\\/} swap=${SWAP_PATH//\//\\/} /g"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=\"${CRYPT_UUID}\":cryptlvm:allow-discards root=${ROOT_PATH//\//\\/} swap=${SWAP_PATH//\//\\/} /g" "/etc/default/grub"
sed -i "s/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" "/etc/default/grub"
sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g" "/etc/default/grub"

grub-mkconfig -o /boot/grub/grub.cfg


echo "root:$USER_PASSWORD" | chpasswd

groupadd sudoers
echo "%sudoers ALL=(ALL:ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

useradd -d "/home/${USER_LOGIN}" -M -G sudoers $USER_LOGIN
chown -R "${USER_LOGIN}:${USER_LOGIN}" "/home/${USER_LOGIN}"
echo "${USER_LOGIN}:${USER_PASSWORD}" | chpasswd

mkdir "/etc/sddm.conf.d"
echo "[Autologin]"                              >> "/etc/sddm.conf.d/kde_settings.conf"
echo "relogin=true"                             >> "/etc/sddm.conf.d/kde_settings.conf"
echo "session=plasma"                           >> "/etc/sddm.conf.d/kde_settings.conf"
echo "user=idiot"                               >> "/etc/sddm.conf.d/kde_settings.conf"
echo ""                                         >> "/etc/sddm.conf.d/kde_settings.conf"
echo "[general]"                                >> "/etc/sddm.conf.d/kde_settings.conf"
echo "haltcommand=/usr/bin/systemctl poweroff"  >> "/etc/sddm.conf.d/kde_settings.conf"
echo "numlock=on"                               >> "/etc/sddm.conf.d/kde_settings.conf"
echo "rebootcommand=/usr/bin/systemctl reboot"  >> "/etc/sddm.conf.d/kde_settings.conf"
echo ""                                         >> "/etc/sddm.conf.d/kde_settings.conf"
echo "[theme]"                                  >> "/etc/sddm.conf.d/kde_settings.conf"
echo "current=breeze"                           >> "/etc/sddm.conf.d/kde_settings.conf"
echo "cursortheme=breeze_cursors"               >> "/etc/sddm.conf.d/kde_settings.conf"
echo "Font=Noto Sans,11,-1,5,50,0,0,0,0,0"      >> "/etc/sddm.conf.d/kde_settings.conf"

systemctl enable sddm.service

mkdir -p "/home/${USER_LOGIN}/.config"
echo "[Layout]"         >> "/home/${USER_LOGIN}/.config/kxkbrc"
echo "LayoutList=gb"    >> "/home/${USER_LOGIN}/.config/kxkbrc"
echo "Use=true"         >> "/home/${USER_LOGIN}/.config/kxkbrc"

systemctl enable fstrim.timer

## Need a way to get it to run ufw config on first boot.

exit
