#!/bin/bash

echo ""
echo "ARCH_CHROOT_SCRIPT"
echo ""

TIMEDATECTL_LOCAL_RTC=1
TIME_ZONE_INFO="Europe/London"

LOCALES="en_GB.UTF-8 UTF-8"
LANG="en_GB.UTF-8"
KEYMAP="uk"
HOSTNAME="IdiotsLaptop23"

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

sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=\"${CRYPT_UUID}\":cryptlvm:allow-discards root=${ROOT_PATH//\//\\/} swap=${SWAP_PATH//\//\\/} /g" "/etc/default/grub"
sed -i "s/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" "/etc/default/grub"
sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g" "/etc/default/grub"

grub-mkconfig -o /boot/grub/grub.cfg


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

echo "root:$USER_PASSWORD" | chpasswd

groupadd sudoers
echo "%sudoers ALL=(ALL:ALL) NOPASSWD: ALL" | (EDITOR="tee -a" visudo)

useradd -d "/home/${USER_LOGIN}" -M -G sudoers $USER_LOGIN
chown -R "${USER_LOGIN}:${USER_LOGIN}" "/home/${USER_LOGIN}" 	# Needs to be done after all writes to home directory.
echo "${USER_LOGIN}:${USER_PASSWORD}" | chpasswd

systemctl enable fstrim.timer
systemctl enable NetworkManager

## Need a way to get it to run ufw config on first boot.

exit
