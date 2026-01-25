# Troubleshooting Guide

> Solutions for common Arch Linux installation and post-installation problems.

## Troubleshooting Topics

| Guide | Common Issues |
|-------|---------------|
| [Boot Problems](boot-problems.md) | GRUB errors, black screen, kernel panic |
| [Network Issues](network-issues.md) | No WiFi, no internet, DNS problems |
| [Driver Problems](driver-problems.md) | GPU issues, no display, screen tearing |
| [Audio Issues](audio-issues.md) | No sound, wrong output device |
| [System Recovery](system-recovery.md) | Chroot rescue, broken packages, rollback |

---

## Emergency Quick Reference

### Can't Boot? Start Here:

1. **Black screen after GRUB** → [Boot Problems](boot-problems.md#black-screen-after-grub)
2. **GRUB rescue prompt** → [Boot Problems](boot-problems.md#grub-rescue-mode)
3. **Kernel panic** → [Boot Problems](boot-problems.md#kernel-panic)
4. **"No bootable device"** → [Boot Problems](boot-problems.md#no-bootable-device)

### System Boots But Has Issues:

1. **No network/WiFi** → [Network Issues](network-issues.md)
2. **No display/resolution wrong** → [Driver Problems](driver-problems.md)
3. **No audio** → [Audio Issues](audio-issues.md)
4. **Broken after update** → [System Recovery](system-recovery.md)

---

## General Troubleshooting Steps

### 1. Boot from Live USB

Most fixes require booting from the Arch Live USB:

```bash
# Download latest Arch ISO
# Create bootable USB
# Boot from USB
```

### 2. Mount Your System

```bash
# For standard installation
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot

# For LVM
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/sdX1 /mnt/boot
mount /dev/mapper/volgroup0-lv_home /mnt/home

# For Encrypted LVM
cryptsetup open /dev/nvme0n1p3 lvm
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/EFI
mount /dev/mapper/volgroup0-lv_home /mnt/home
```

### 3. Chroot Into System

```bash
arch-chroot /mnt
```

### 4. Fix the Problem

Follow the specific guide for your issue.

### 5. Exit and Reboot

```bash
exit
umount -R /mnt
reboot
```

---

## Diagnostic Commands

### System Information

```bash
# Kernel and system info
uname -a
hostnamectl

# Boot messages (look for errors)
journalctl -b
journalctl -b -p err

# Hardware info
lspci
lsusb
lsblk
```

### Service Status

```bash
# Check service status
systemctl status NetworkManager
systemctl status gdm
systemctl status sddm

# List failed services
systemctl --failed
```

### Logs

```bash
# System logs
journalctl -xe

# Xorg logs (for display issues)
cat /var/log/Xorg.0.log

# Boot log
dmesg | less
```

---

<div align="center">

[← Back to Main Guide](../../README.md)

</div>
