#!/bin/bash
# PATH: Standard (ext4)
# MIRRORS: docs/02-partitioning/basic-partitioning.md
#          docs/03-base-installation/base-install-standard.md
#          docs/03-base-installation/bootloader-standard.md
set -euo pipefail

# archiso runs script= from the tty1 autologin shell, so stdout would never reach the
# serial port the harness watches. Redirect everything to ttyS0.
exec > /dev/ttyS0 2>&1

BASE="$(sed -n 's|.*script=\(http://[^/]*\)/.*|\1|p' /proc/cmdline)"
source <(curl -fsSL "$BASE/lib/common.sh")
trap 'echo "ARCHTEST: ERROR: failed at line $LINENO"; sleep 2; poweroff -f' ERR

D=/dev/vda
wait_net

log "partitioning $D  (ESP 1G + root + 4G swap)"
sgdisk --zap-all "$D"
sgdisk -n1:0:+1G   -t1:ef00 -c1:ESP  "$D"
sgdisk -n2:0:-4G   -t2:8300 -c2:root "$D"
sgdisk -n3:0:0     -t3:8200 -c3:swap "$D"
partprobe "$D"; sleep 2

mkfs.fat -F32 "${D}1"
mkfs.ext4 -F  "${D}2"
mkswap        "${D}3"

mount "${D}2" /mnt
mkdir -p /mnt/boot
mount "${D}1" /mnt/boot
swapon "${D}3"
lsblk -f

install_base ""                        # Step 6.2: no extras
gen_fstab
configure_system
install_kernels_and_gpu
set_hooks "base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck"
install_grub /boot
assert_grub_entries
finish
