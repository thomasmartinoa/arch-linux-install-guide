#!/bin/bash
# PATH: Btrfs
# MIRRORS: docs/02-partitioning/btrfs-setup.md
#          docs/03-base-installation/base-install-btrfs.md
#          docs/03-base-installation/bootloader-btrfs.md
set -euo pipefail

# archiso runs script= from the tty1 autologin shell, so stdout would never reach the
# serial port the harness watches. Redirect everything to ttyS0.
exec > /dev/ttyS0 2>&1

BASE="$(sed -n 's|.*script=\(http://[^/]*\)/.*|\1|p' /proc/cmdline)"
source <(curl -fsSL "$BASE/lib/common.sh")
trap 'echo "ARCHTEST: ERROR: failed at line $LINENO"; sleep 2; poweroff -f' ERR

D=/dev/vda
wait_net

log "partitioning $D  (ESP 1G + Btrfs)"
sgdisk --zap-all "$D"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP  "$D"
sgdisk -n2:0:0   -t2:8300 -c2:root "$D"
partprobe "$D"; sleep 2

mkfs.fat -F32 "${D}1"
mkfs.btrfs -f -L arch "${D}2"

log "creating subvolumes"
mount "${D}2" /mnt
for sv in @ @home @snapshots @var_log @var_cache @swap; do
    btrfs subvolume create "/mnt/$sv"
done
btrfs subvolume list /mnt
umount /mnt

O="noatime,compress=zstd"
mount -o "$O,subvol=@" "${D}2" /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}
mount -o "$O,subvol=@home"      "${D}2" /mnt/home
mount -o "$O,subvol=@snapshots" "${D}2" /mnt/.snapshots
mount -o "$O,subvol=@var_log"   "${D}2" /mnt/var/log
mount -o "$O,subvol=@var_cache" "${D}2" /mnt/var/cache
mount -o "noatime,subvol=@swap" "${D}2" /mnt/swap
mount "${D}1" /mnt/boot

log "swapfile via mkswapfile"
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile
lsblk -f

install_base "btrfs-progs"             # Step 6.2: btrfs-progs
gen_fstab
configure_system
install_kernels_and_gpu
set_hooks "base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck"
install_grub /boot
assert_grub_entries
arch-chroot /mnt grep -q 'rootflags=subvol=@' /boot/grub/grub.cfg \
    || die "grub.cfg is missing rootflags=subvol=@ — root would not mount"
finish
