#!/bin/sh

DRIVE_PATH="/dev/sda"
BOOT_PARTITION_PATH="${DRIVE_PATH}1"
ROOT_PARTITION_PATH="${DRIVE_PATH}2"

CRYPT_MAPPING="cryptlvm2"
CRYPT_MAPPING_PATH="/dev/mapper/${CRYPT_MAPPING}"

VOLUME_GROUP="MyVolGroup2"
VOLUME_GROUP_PATH="/dev/${VOLUME_GROUP}"

SWAP_PERCENTAGE_OF_MEMORY=100
MEMORY=$(awk '/MemTotal/{print $2}' /proc/meminfo)
SWAP=$(($MEMORY*$SWAP_PERCENTAGE_OF_MEMORY))
SWAP=$(($SWAP/100))
ROOT_PERCENTAGE=10
HOME_PERCENTAGE=10
DEV_PERCENTAGE=1

INSTALL_PACKAGES="neovim man info man-db man-pages texinfo networkmanger sudo lvm2 ntfs-3g make"

IFS= read -r -p 'Please enter your user login: ' USER_LOGIN

#IFS= read -r -s -p 'Please enter your passphrase: ' PASSPHRASE
#echo 
#IFS= read -r -s -p 'Please verify your passphrase: ' VERIFY
#echo
#
#while [[ "$PASSPHRASE" != "$VERIFY" ]]
#do
#    echo
#    echo "Passphrase does not match. Please try again."
#
#    IFS= read -r -s -p 'Please enter your passphrase: ' PASSPHRASE
#    echo 
#    IFS= read -r -s -p 'Please verify your passphrase: ' VERIFY
#    echo
#done

#
#parted -sf "$DRIVE_PATH" mklabel gpt
#parted -sf "$DRIVE_PATH" mkpart boot linux-swap 0GB 1GB
#parted -sf "$DRIVE_PATH" mkpart cryptlvm 1GB 100%
#
#
#printf "$PASSPHRASE" | cryptsetup luksFormat "$ROOT_PARTITION_PATH"
#printf "$PASSPHRASE" | cryptsetup open "$ROOT_PARTITION_PATH" "$CRYPT_MAPPING"
#
#pvcreate "$CRYPT_MAPPING_PATH"
#vgcreate "$VOLUME_GROUP" 

lvcreate -L "$SWAP" "$VOLUME_GROUP" -n swap
lvcreate -L "${ROOT_PERCENTAGE}%" "$VOLUME_GROUP" -n root
lvcreate -L "${HOME_PERCENTAGE}%" "$VOLUME_GROUP" -n "$USER_LOGIN"
lvcreate -L "${DEV_PERCENTAGE}%" "$VOLUME_GROUP" -n dev

mkfs.ext4 "${VOLUME_GROUP_PATH}/root"
mkfs.ext4 "${VOLUME_GROUP_PATH}/${USER_LOGIN}"
mkfs.ext4 "${VOLUME_GROUP_PATH}/dev"
mkswap "${VOLUME_GROUP_PATH}/swap"

mount "${VOLUME_GROUP_PATH}/root" /mnt
mount --mkdir "${VOLUME_GROUP_PATH}/${USER_LOGIN}" "/mnt/home/${USER_LOGIN}"
mount --mkdir "${VOLUME_GROUP_PATH}/dev" "/mnt/home/${USER_LOGIN}/dev"
swapon "${VOLUME_GROUP_PATH}/swap"

mkfs.fat -F32 "$BOOT_PARTITION_PATH"
mount --mkdir "$BOOT_PARTITION_PATH" /mnt/boot

pacstrap - K /mnt base linux linux-firmware "$INSTALL_PACKAGES"

genfstab - U /mnt >> /mnt/etc/fstab

mkdir /mnt/scripts
cp  ./arch-chroot-script.sh /mnt/scripts
chmod +x /mnt/scripts/arch-chroot-script.sh

arch-chroot /mnt .//mnt/scripts/arch-chroot-script.sh
