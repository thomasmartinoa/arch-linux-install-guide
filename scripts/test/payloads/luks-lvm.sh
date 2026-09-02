#!/bin/bash
# PATH: LUKS + LVM
# MIRRORS: docs/02-partitioning/lvm-encryption.md
#          docs/03-base-installation/base-install-common.md   (LUKS + LVM row)
#          docs/03-base-installation/deltas/luks-lvm.md
#          docs/03-base-installation/bootloader-encrypted.md
set -euo pipefail

# archiso runs script= from the tty1 autologin shell, so stdout would never reach the
# serial port the harness watches. Redirect everything to ttyS0.
exec > /dev/ttyS0 2>&1

BASE="$(sed -n 's|.*script=\(http://[^/]*\)/.*|\1|p' /proc/cmdline)"
source <(curl -fsSL "$BASE/lib/common.sh")
trap 'echo "ARCHTEST: ERROR: failed at line $LINENO"; sleep 2; poweroff -f' ERR

D=/dev/vda
wait_net

log "partitioning $D  (ESP 1G + /boot 1G + LUKS)"
sgdisk --zap-all "$D"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP  "$D"
sgdisk -n2:0:+1G -t2:8300 -c2:boot "$D"
sgdisk -n3:0:0   -t3:8309 -c3:luks "$D"
partprobe "$D"; sleep 2

mkfs.fat -F32 "${D}1"
mkfs.ext4 -F  "${D}2"

log "LUKS format + open as cryptlvm"
echo -n "$LUKS_PASS" | cryptsetup luksFormat --type luks2 --batch-mode "${D}3" -
echo -n "$LUKS_PASS" | cryptsetup open "${D}3" cryptlvm -
LUKS_UUID=$(blkid -s UUID -o value "${D}3")
log "LUKS UUID = $LUKS_UUID"

pvcreate -ff -y /dev/mapper/cryptlvm
vgcreate volgroup0 /dev/mapper/cryptlvm
lvcreate -y -L 15G      volgroup0 -n lv_root
lvcreate -y -L 4G       volgroup0 -n lv_swap
lvcreate -y -l 100%FREE volgroup0 -n lv_home
modprobe dm_mod; vgscan; vgchange -ay

mkfs.ext4 -F /dev/volgroup0/lv_root
mkfs.ext4 -F /dev/volgroup0/lv_home
mkswap       /dev/volgroup0/lv_swap

mount /dev/volgroup0/lv_root /mnt
mkdir -p /mnt/boot /mnt/home /mnt/efi
mount "${D}2" /mnt/boot
mount "${D}1" /mnt/efi
mount /dev/volgroup0/lv_home /mnt/home
swapon /dev/volgroup0/lv_swap
lsblk -f

install_base "lvm2 cryptsetup"         # Step 6.2: lvm2 AND cryptsetup
gen_fstab
configure_system
set_hooks "base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck"
assert_cryptsetup_in_initramfs
install_grub /efi "--boot-directory=/boot" "cryptdevice=UUID=${LUKS_UUID}:cryptlvm"
arch-chroot /mnt grep -q "cryptdevice=UUID=${LUKS_UUID}:cryptlvm" /boot/grub/grub.cfg \
    || die "cryptdevice missing from grub.cfg"
finish
