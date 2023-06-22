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

ln -sf "/usr/share/zoninfo/${TIME_ZONE_INFO}" "/etc/localtime"
hwclock --systohc

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
