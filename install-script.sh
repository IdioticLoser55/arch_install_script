#!/bin/sh

DRIVE_PATH="/dev/nvme0n1"
BOOT_PATH="${DRIVE_PATH}p1"
CRYPT_PATH="${DRIVE_PATH}p2"

CRYPT_MAPPING="cryptlvm"
CRYPT_MAPPING_PATH="/dev/mapper/${CRYPT_MAPPING}"

VOLUME_GROUP="MyVolGroup"
VOLUME_GROUP_PATH="/dev/${VOLUME_GROUP}"
SWAP_PATH="${VOLUME_GROUP_PATH}/swap"
ROOT_PATH="${VOLUME_GROUP_PATH}/root"
HOME_PATH="${VOLUME_GROUP_PATH}/${USER_LOGIN}"
DEV_PATH="${VOLUME_GROUP_PATH}/dev"

SWAP_PERCENTAGE_OF_MEMORY=100
MEMORY=$(awk '/MemTotal/{print $2}' /proc/meminfo)
SWAP=$(($MEMORY*$SWAP_PERCENTAGE_OF_MEMORY))
SWAP=$(($SWAP/100))

ROOT_PERCENTAGE=30
HOME_PERCENTAGE=30
DEV_PERCENTAGE=05

INSTALL_PACKAGES="neovim man man-db man-pages texinfo networkmanager make sudo lvm2 grub efibootmgr amd-ucode os-prober"

loadkeys uk

USER_LOGIN="dumb"
USER_PASSWORD="dumb"
PASSPHRASE="dumber"

#IFS= read -r -p 'Please enter your user login: ' USER_LOGIN
#
#IFS= read -r -s -p 'Please enter your password: ' USER_PASSWORD
#echo 
#IFS= read -r -s -p 'Please verify your password: ' VERIFY
#echo
#
#while [[ "$USER_PASSWORD" != "$VERIFY" ]]
#do
#    echo
#    echo "Password does not match. Please try again."
#
#    IFS= read -r -s -p 'Please enter your password: ' USER_PASSWORD
#    echo 
#    IFS= read -r -s -p 'Please verify your password: ' VERIFY
#    echo
#done
#
#IFS= read -r -s -p 'Please enter your drive passphrase: ' PASSPHRASE
#echo 
#IFS= read -r -s -p 'Please verify your passphrase: ' VERIFY
#echo
#
#while [[ "$PASSPHRASE" != "$VERIFY" ]]
#do
#    echo
#    echo "Passphrase does not match. Please try again."
#
#    IFS= read -r -s -p 'Please enter your drive passphrase: ' PASSPHRASE
#    echo 
#    IFS= read -r -s -p 'Please verify your passphrase: ' VERIFY
#    echo
#done

HOME_PATH="${VOLUME_GROUP_PATH}/${USER_LOGIN}"

parted -sf "$DRIVE_PATH" mklabel gpt
parted -sf "$DRIVE_PATH" mkpart esp fat32 0GB 1GB
parted -sf "$DRIVE_PATH" mkpart cryptlvm 1GB 100%

printf "$PASSPHRASE" | cryptsetup luksFormat "$CRYPT_PATH"
printf "$PASSPHRASE" | cryptsetup open "$CRYPT_PATH" "$CRYPT_MAPPING"

CRYPT_UUID=$(blkid -s UUID -o value ${CRYPT_PATH})
echo ""
echo "CRYPT_UUID=$CRYPT_UUID"
echo ""

pvcreate "$CRYPT_MAPPING_PATH"
vgcreate "$VOLUME_GROUP" "$CRYPT_MAPPING_PATH"

lvcreate -L "$SWAP"k "$VOLUME_GROUP" -n swap
lvcreate -l "${ROOT_PERCENTAGE}%VG" "$VOLUME_GROUP" -n root
lvcreate -l "${HOME_PERCENTAGE}%VG" "$VOLUME_GROUP" -n "$USER_LOGIN"
lvcreate -l "${DEV_PERCENTAGE}%VG" "$VOLUME_GROUP" -n dev

mkfs.ext4 "$ROOT_PATH"
mkfs.ext4 "$HOME_PATH"
mkfs.ext4 "$DEV_PATH"
mkswap "$SWAP_PATH"

mount "$ROOT_PATH" /mnt
mount --mkdir "$HOME_PATH" "/mnt/home/${USER_LOGIN}"
mount --mkdir "$DEV_PATH" "/mnt/home/${USER_LOGIN}/dev"
swapon "$SWAP_PATH"

mkfs.fat -F 32 "$BOOT_PATH"
mount --mkdir "$BOOT_PATH" /mnt/boot

pacstrap -K /mnt base linux linux-firmware $INSTALL_PACKAGES

genfstab -U /mnt >> /mnt/etc/fstab

mkdir /mnt/scripts
cp ./arch-chroot-script.sh /mnt/scripts
chmod +x /mnt/scripts/arch-chroot-script.sh

arch-chroot /mnt /bin/bash -- << EOCHROOT 
    
    USER_LOGIN="${USER_LOGIN}" USER_PASSWORD="${USER_PASSWORD}" CRYPT_UUID="${CRYPT_UUID}" SWAP_PATH="${SWAP_PATH}" ROOT_PATH="${ROOT_PATH}" /scripts/arch-chroot-script.sh

EOCHROOT


#./install-script.sh 2>&1 | tee results.txt
#sudo swapoff /dev/MyVolGroup2/swap && sudo fuser -km /mnt && sudo umount -R /mnt && sudo vgchange -a n MyVolGroup2 && sudo cryptsetup close cryptlvm2
