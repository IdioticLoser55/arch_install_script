#!/bin/sh

systemctl enable ufw.service
ufw enable
ufw default deny
ufw allow from 192.168.0.0/24
ufw limit ssh



#sudo swapoff /dev/MyVolGroup2/swap && sudo fuser -km /mnt && sudo umount -R /mnt && sudo vgchange -a n MyVolGroup2 && sudo cryptsetup close cryptlvm2
