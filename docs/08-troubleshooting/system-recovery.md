# System Recovery

Guide for recovering a broken Arch Linux system, fixing packages, and performing rollbacks.

## Table of Contents

- [Chroot Recovery](#chroot-recovery)
- [Broken Packages](#broken-packages)
- [Partial Upgrades](#partial-upgrades)
- [Broken Dependencies](#broken-dependencies)
- [Corrupted Database](#corrupted-database)
- [Kernel Issues](#kernel-issues)
- [Rollback with Btrfs](#rollback-with-btrfs)
- [Reinstalling Without Data Loss](#reinstalling-without-data-loss)

---

## Chroot Recovery

The chroot (change root) method allows you to access your broken system from a live environment.

### Step 1: Boot Live USB

Download and boot the latest Arch Linux ISO.

### Step 2: Mount Your System

**Standard Installation:**
```bash
mount /dev/sdX2 /mnt          # Root partition
mount /dev/sdX1 /mnt/boot     # Boot/EFI partition
```

**LVM Installation:**
```bash
# Activate LVM
modprobe dm_mod
vgscan
vgchange -ay

# Mount
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/sdX1 /mnt/boot
mount /dev/mapper/volgroup0-lv_home /mnt/home
```

**Encrypted LVM Installation:**
```bash
# Decrypt
cryptsetup open /dev/nvme0n1p3 cryptlvm

# Activate LVM
vgscan
vgchange -ay

# Mount
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/efi
mount /dev/mapper/volgroup0-lv_home /mnt/home
```

### Step 3: Chroot Into System

```bash
arch-chroot /mnt
```

You now have full access to your installed system!

### Step 4: Fix Issues

Run whatever commands needed to fix your system.

### Step 5: Exit and Reboot

```bash
exit
umount -R /mnt
reboot
```

---

## Broken Packages

### Reinstall a Package

```bash
sudo pacman -S <package_name>
```

### Reinstall All Packages

```bash
sudo pacman -Qqn | sudo pacman -S -
```

### Remove Broken Package

```bash
# Force remove
sudo pacman -Rdd <package_name>

# Reinstall
sudo pacman -S <package_name>
```

### Fix Package File Conflicts

```bash
# If pacman complains about file exists
sudo pacman -S --overwrite '*' <package_name>

# Or remove the conflicting file first
sudo rm /path/to/conflicting/file
sudo pacman -S <package_name>
```

---

## Partial Upgrades

> ⚠️ Arch does not support partial upgrades. Always run full system update.

### Symptoms
- "unable to satisfy dependency"
- Library version mismatches
- Programs crash with "symbol not found"

### Fix: Full System Update

```bash
sudo pacman -Syu
```

### If Update Fails

```bash
# Refresh package database
sudo pacman -Syy

# Update keyring first
sudo pacman -S archlinux-keyring

# Then full update
sudo pacman -Syu
```

### Downgrade Package (Temporary Fix)

```bash
# Install downgrade tool
sudo pacman -S downgrade

# Downgrade specific package
sudo downgrade <package_name>
```

---

## Broken Dependencies

### Find and Fix Broken Dependencies

```bash
# Check for broken dependencies
sudo pacman -Dk

# Check for missing files
sudo pacman -Qk
```

### Rebuild AUR Packages After Update

```bash
# Using yay
yay -Sua

# Rebuild specific package
yay -S --rebuild <package_name>
```

### Fix "unable to satisfy dependency"

```bash
# Update package database
sudo pacman -Syy

# Try installing missing dependency
sudo pacman -S <missing_package>

# If that fails, check if it's provided by another package
pacman -F <missing_file>
```

---

## Corrupted Database

### Symptoms
- "database is inconsistent"
- "could not find database"
- Package operations fail

### Fix Database

```bash
# Remove lock file if exists
sudo rm /var/lib/pacman/db.lck

# Rebuild package database
sudo pacman -Syy

# Check database
sudo pacman -Dk
```

### Restore Database from Backup

```bash
# Check if backup exists
ls /var/lib/pacman/local/

# Restore from filesystem
sudo pacman -Qk 2>/dev/null | grep -v '0 missing files'
```

### Rebuild Database from Scratch

```bash
# Remove corrupted database
sudo rm -r /var/lib/pacman/sync

# Refresh
sudo pacman -Syy
```

### Fix Foreign Package Database

```bash
# List foreign packages (AUR)
pacman -Qm

# Reinstall from AUR
yay -S <package_name>
```

---

## Kernel Issues

### Boot into Fallback Kernel

At GRUB menu, select "Arch Linux, with Linux linux (fallback initramfs)".

### Install LTS Kernel as Backup

```bash
sudo pacman -S linux-lts linux-lts-headers

# For NVIDIA
sudo pacman -S nvidia-open-lts

# Regenerate GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Reinstall Current Kernel

```bash
sudo pacman -S linux linux-headers
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Fix Missing initramfs

```bash
# Chroot from live USB
arch-chroot /mnt

# Regenerate all initramfs
mkinitcpio -P

# Regenerate GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Rollback with Btrfs

If you're using Btrfs with snapshots, you can easily rollback.

### Using Snapper

```bash
# List snapshots
sudo snapper list

# Rollback to snapshot
sudo snapper rollback <number>
sudo reboot
```

### Using Timeshift

```bash
# List snapshots
sudo timeshift --list

# Restore snapshot
sudo timeshift --restore --snapshot '2024-01-01_00-00-00'
```

### Manual Btrfs Rollback

```bash
# Boot from live USB
mount /dev/sdX2 /mnt

# List subvolumes
btrfs subvolume list /mnt

# Replace current with snapshot
mv /mnt/@ /mnt/@_broken
mv /mnt/@snapshots/XXXX/snapshot /mnt/@

# Reboot
umount /mnt
reboot
```

---

## Reinstalling Without Data Loss

If all else fails, you can reinstall Arch while keeping your data.

### Method 1: Reinstall Base System Only

```bash
# Boot live USB
# Mount partitions (don't format!)
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot

# Backup important configs
cp /mnt/etc/fstab /mnt/root/
cp -r /mnt/etc/NetworkManager /mnt/root/

# Reinstall base
pacstrap -K /mnt base linux linux-firmware

# Restore configs
cp /mnt/root/fstab /mnt/etc/
cp -r /mnt/root/NetworkManager /mnt/etc/

# Chroot and reconfigure
arch-chroot /mnt
# Reinstall bootloader, etc.
```

### Method 2: Keep /home Partition

If you have separate /home partition:

1. Format only root partition
2. Install fresh
3. Mount existing /home
4. Your user data is preserved

### Method 3: Backup and Restore Package List

**Before disaster (save this somewhere safe!):**
```bash
pacman -Qqe > pkglist.txt
pacman -Qqm > aurlist.txt
```

**After fresh install:**
```bash
# Install official packages
sudo pacman -S --needed - < pkglist.txt

# Install AUR packages
yay -S --needed - < aurlist.txt
```

---

## Recovery Diagnostic Commands

```bash
# Check filesystem
sudo fsck /dev/sdX2

# Check disk health
sudo smartctl -a /dev/sda

# Check systemd failures
systemctl --failed

# Check journal for errors
journalctl -p err -b

# Check for orphan packages
pacman -Qdt

# Check for broken symlinks
find /usr -xtype l

# Verify all package files
sudo pacman -Qkk
```

---

## Emergency Contacts

If you can't fix the issue:

- **Arch Wiki**: https://wiki.archlinux.org/
- **Arch Forums**: https://bbs.archlinux.org/
- **r/archlinux**: https://reddit.com/r/archlinux
- **Arch IRC**: #archlinux on Libera.Chat

When asking for help, include:
- Output of `journalctl -b -p err`
- What you changed before the issue
- Your hardware specs

---

<div align="center">

[← Audio Issues](audio-issues.md) | [Back to Main Guide](../../README.md)

</div>
