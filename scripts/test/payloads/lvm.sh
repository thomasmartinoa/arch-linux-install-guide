#!/bin/bash
# PATH: LVM
# MIRRORS: docs/02-partitioning/lvm-setup.md
#          docs/03-base-installation/base-install-common.md   (LVM row)
#          docs/03-base-installation/deltas/lvm.md
#          docs/03-base-installation/bootloader-lvm.md
set -euo pipefail

# archiso runs script= from the tty1 autologin shell, so stdout would never reach the
# serial port the harness watches. Redirect everything to ttyS0.
exec > /dev/ttyS0 2>&1

BASE="$(sed -n 's|.*script=\(http://[^/]*\)/.*|\1|p' /proc/cmdline)"
source <(curl -fsSL "$BASE/lib/common.sh")
trap 'echo "ARCHTEST: ERROR: failed at line $LINENO"; sleep 2; poweroff -f' ERR

D=/dev/vda
wait_net

log "partitioning $D  (ESP 1G + LVM PV)"
sgdisk --zap-all "$D"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP "$D"
sgdisk -n2:0:0   -t2:8e00 -c2:lvm "$D"
partprobe "$D"; sleep 2

mkfs.fat -F32 "${D}1"

pvcreate -ff -y "${D}2"
vgcreate volgroup0 "${D}2"
lvcreate -y -L 15G       volgroup0 -n lv_root
lvcreate -y -L 4G        volgroup0 -n lv_swap
lvcreate -y -l 100%FREE  volgroup0 -n lv_home
modprobe dm_mod; vgscan; vgchange -ay

mkfs.ext4 -F /dev/volgroup0/lv_root
mkfs.ext4 -F /dev/volgroup0/lv_home
mkswap       /dev/volgroup0/lv_swap

mount /dev/volgroup0/lv_root /mnt
mkdir -p /mnt/boot /mnt/home
mount "${D}1" /mnt/boot
mount /dev/volgroup0/lv_home /mnt/home
swapon /dev/volgroup0/lv_swap
lsblk -f

install_base "lvm2"                    # Step 6.2: lvm2
gen_fstab
configure_system
set_hooks "base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck"
install_grub /boot
arch-chroot /mnt grep -q 'root=/dev/mapper/volgroup0-lv_root' /boot/grub/grub.cfg \
    || die "grub.cfg does not reference the LVM root volume"
finish
