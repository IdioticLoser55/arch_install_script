#!/bin/bash


TIMEDATECTL_LOCAL_RTC=1
TIME_ZONE_INFO="Europe/London"

LOCALES="en_GB.UTF-8 UTF-8"
LANG="en_GB.UTF-8"
KEYMAP="uk"
HOSTNAME="IdiotsLaptop23"

timedatectl set-local-rtc "$TIMEDATECTL_LOCAL_RTC"
ln -sf "/usr/share/zoninfo/${TIME_ZONE_INFO}" "/etc/localtime"
hwclock --systohc

echo "$LOCALES" >> "/etc/locale.gen"
locale-gen

echo "LANG=${LANG}" >> "/etc/locale.conf"

echo "KEYMAP=${KEYMAP}" >> "/etc/vconsole.conf"

echo "$HOSTNAME" >> "/etc/hostname"

sed -i "s/base/base udev/g" "/etc/mkinitcpio.conf"
sed -i "s/block/keyboard keymap block encrypt lvm2/g" "/etc/mkinitcpio.conf"


exit
