# LVM Bootloader Installation

> GRUB setup for **LVM** partitioning (without encryption).

![GRUB Bootloader](../../images/grub-bootloader.png)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Verify Boot/EFI Partition](#step-1-verify-bootefi-partition)
- [Step 2: Install GRUB](#step-2-install-grub)
- [Step 3: Configure GRUB](#step-3-configure-grub)
- [Step 4: Generate Configuration](#step-4-generate-configuration)
- [Step 5: Dual Boot (Optional)](#step-5-dual-boot-optional)
- [Step 6: Final Steps](#step-6-final-steps)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Ensure you have completed:

- [ ] [LVM Base Installation](base-install-lvm.md)
- [ ] mkinitcpio configured with `lvm2` hook
- [ ] Still in chroot environment

**Verify critical setup:**
```bash
# Check packages
pacman -Q grub efibootmgr lvm2

# Verify lvm2 hook in mkinitcpio.conf
grep "HOOKS" /etc/mkinitcpio.conf
# Should show: ... block lvm2 filesystems ...
```

---

## What is a Bootloader?

A bootloader is the first program that runs when you turn on your computer.

**LVM Boot Process:**
```
Power On → UEFI → GRUB → Linux Kernel → initramfs → LVM activation → System
                                             ↑
                                      lvm2 hook activates
                                      your volume group
```

---

## Step 1: Verify Boot/EFI Partition

### Check if Already Mounted

```bash
ls /boot
```

If you see `vmlinuz-linux` and other boot files, the boot partition is already mounted.

> **Note:** In LVM setup, the EFI partition is mounted directly at `/boot`, so it serves as BOTH the boot directory AND the EFI System Partition.

### Mount Boot Partition (if needed)

```bash
mount /dev/sda1 /boot
```

> Replace `/dev/sda1` with your EFI partition

---

## Step 2: Install GRUB

### Reload systemd

```bash
systemctl daemon-reload
```

### Install GRUB to EFI

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
```

**Command breakdown:**
| Part | Meaning |
|------|---------|
| `grub-install` | GRUB installation command |
| `--target=x86_64-efi` | 64-bit UEFI target |
| `--efi-directory=/boot` | Path to EFI System Partition |
| `--bootloader-id=grub_uefi` | Name in UEFI boot menu |
| `--recheck` | Recheck device map |

**Expected output:**
```
Installing for x86_64-efi platform.
Installation finished. No error reported.
```

### Copy Locale File

```bash
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
```

---

## Step 3: Configure GRUB

### Edit GRUB Defaults

```bash
nvim /etc/default/grub
```

### Recommended Settings for LVM

```bash
# Default menu entry (0 = first)
GRUB_DEFAULT=0

# Boot timeout in seconds
GRUB_TIMEOUT=5

# Kernel parameters
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"

# Additional parameters (leave empty for LVM without encryption)
GRUB_CMDLINE_LINUX=""

# Disable submenu
GRUB_DISABLE_SUBMENU=y

# Enable os-prober (for dual boot)
GRUB_DISABLE_OS_PROBER=false
```

> 💡 **Note:** LVM without encryption doesn't need special kernel parameters. The `lvm2` hook in mkinitcpio handles everything.

### Save and Exit

In nvim: Press `Esc`, type `:wq`, press `Enter`

---

## Step 4: Generate Configuration

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

**Expected output:**
```
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-linux
Found initrd image: /boot/initramfs-linux.img
Found fallback initrd image: /boot/initramfs-linux-fallback.img
Found linux image: /boot/vmlinuz-linux-lts
Found initrd image: /boot/initramfs-linux-lts.img
Found fallback initrd image: /boot/initramfs-linux-lts-fallback.img
done
```

### Verify LVM Root Detection

```bash
grep -i "root=" /boot/grub/grub.cfg | head -3
```

You should see your LVM volume:
```
linux /vmlinuz-linux root=/dev/mapper/volgroup0-lv_root ...
```

---

## Step 5: Dual Boot (Optional)

If you have Windows installed:

### Enable os-prober

Ensure this is in `/etc/default/grub`:
```bash
GRUB_DISABLE_OS_PROBER=false
```

### Run os-prober

```bash
os-prober
```

### Regenerate GRUB Config

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Step 6: Final Steps

### Exit Chroot

```bash
exit
```

### Unmount All Partitions

```bash
umount -a
```

> ⚠️ You may see "target is busy" warnings - that's normal.

### Reboot

```bash
reboot
```

> 💡 **Remove the USB drive when the system restarts!**

---

## Quick Reference Summary

```bash
# Mount boot partition (if needed)
mount /dev/sda1 /boot

# Install GRUB
systemctl daemon-reload
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Configure GRUB
nvim /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit and reboot
exit
umount -a
reboot
```

---

## Troubleshooting

### GRUB Not Found in UEFI

```bash
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
```

### "Volume group not found" at Boot

The `lvm2` hook is missing or not working.

**Boot from live USB and fix:**
```bash
# Mount partitions
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/sda1 /mnt/boot
mount /dev/mapper/volgroup0-lv_home /mnt/home

# Chroot
arch-chroot /mnt

# Verify hook
grep "HOOKS" /etc/mkinitcpio.conf
# Should have: ... block lvm2 filesystems ...

# If missing, edit and add lvm2
nvim /etc/mkinitcpio.conf

# Regenerate
mkinitcpio -p linux
mkinitcpio -p linux-lts
```

### System Hangs After "Loading Initial Ramdisk"

1. mkinitcpio hooks are incorrect
2. Boot from live USB
3. Check and fix `/etc/mkinitcpio.conf`
4. Regenerate initramfs

### Error: "device /dev/mapper/volgroup0-lv_root not found"

```bash
# From live USB, activate LVM
modprobe dm-mod
vgscan
vgchange -ay

# Then mount and fix
```

---

## LVM Boot Verification

After successful boot, verify LVM is working:

```bash
# Check volume groups
vgs

# Check logical volumes
lvs

# Check mounts
lsblk
```

**Expected output:**
```
NAME                   SIZE TYPE  MOUNTPOINT
sda                    500G disk  
├─sda1                 512M part  /boot
└─sda2               499.5G part  
  ├─volgroup0-lv_root   50G lvm   /
  ├─volgroup0-lv_swap    8G lvm   [SWAP]
  └─volgroup0-lv_home  441G lvm   /home
```

---

## Next Steps

After rebooting successfully:

→ [First Boot](../04-post-installation/first-boot.md)

---

<div align="center">

[← Base Installation](base-install-lvm.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
