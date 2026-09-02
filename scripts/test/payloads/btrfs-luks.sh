#!/bin/bash
# PATH: Btrfs + LUKS
# MIRRORS: docs/02-partitioning/btrfs-encryption.md
#          docs/03-base-installation/base-install-common.md   (Btrfs + LUKS row)
#          docs/03-base-installation/deltas/btrfs-luks.md
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

log "partitioning $D  (ESP 1G + LUKS)"
sgdisk --zap-all "$D"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP  "$D"
sgdisk -n2:0:0   -t2:8309 -c2:luks "$D"
partprobe "$D"; sleep 2

mkfs.fat -F32 "${D}1"

# NOTE: only luksFormat takes a positional [<key file>]; `open` requires --key-file=-.
#       Both use --key-file=- here so the exact same bytes are read in each case.
log "LUKS format + open as cryptroot"
printf '%s' "$LUKS_PASS" | cryptsetup luksFormat --type luks2 --batch-mode --key-file=- "${D}2"
printf '%s' "$LUKS_PASS" | cryptsetup open --key-file=- "${D}2" cryptroot
LUKS_UUID=$(blkid -s UUID -o value "${D}2")
log "LUKS UUID = $LUKS_UUID"

mkfs.btrfs -f -L arch /dev/mapper/cryptroot

log "creating subvolumes"
mount /dev/mapper/cryptroot /mnt
for sv in @ @home @snapshots @var_log @var_cache @swap; do
    btrfs subvolume create "/mnt/$sv"
done
btrfs subvolume list /mnt
umount /mnt

O="noatime,compress=zstd"
mount -o "$O,subvol=@" /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}
mount -o "$O,subvol=@home"      /dev/mapper/cryptroot /mnt/home
mount -o "$O,subvol=@snapshots" /dev/mapper/cryptroot /mnt/.snapshots
mount -o "$O,subvol=@var_log"   /dev/mapper/cryptroot /mnt/var/log
mount -o "$O,subvol=@var_cache" /dev/mapper/cryptroot /mnt/var/cache
mount -o "noatime,subvol=@swap" /dev/mapper/cryptroot /mnt/swap
mount "${D}1" /mnt/boot

log "swapfile via mkswapfile"
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile
lsblk -f

install_base "btrfs-progs cryptsetup"  # Step 6.2: btrfs-progs AND cryptsetup
gen_fstab
configure_system
set_hooks "base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck"
assert_cryptsetup_in_initramfs
install_grub /boot "" "cryptdevice=UUID=${LUKS_UUID}:cryptroot"
arch-chroot /mnt grep -q "cryptdevice=UUID=${LUKS_UUID}:cryptroot" /boot/grub/grub.cfg \
    || die "cryptdevice missing from grub.cfg"
arch-chroot /mnt grep -q 'rootflags=subvol=@' /boot/grub/grub.cfg \
    || die "grub.cfg is missing rootflags=subvol=@ — root would not mount"
finish
