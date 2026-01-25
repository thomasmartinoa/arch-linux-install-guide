# Boot Problems

> Solutions for boot failures, GRUB errors, black screens, and kernel panics.

![Boot Problems](../../images/boot-problems.png)

## Table of Contents

- [No Bootable Device](#no-bootable-device)
- [GRUB Rescue Mode](#grub-rescue-mode)
- [Black Screen After GRUB](#black-screen-after-grub)
- [Kernel Panic](#kernel-panic)
- [Wrong OS Boots](#wrong-os-boots)
- [Encrypted Volume Not Unlocking](#encrypted-volume-not-unlocking)
- [Reinstalling GRUB](#reinstalling-grub)

---

## No Bootable Device

### Symptoms
- "No bootable device found"
- "Boot device not found"
- System goes straight to BIOS

### Causes
1. UEFI boot entry was deleted
2. EFI partition not properly configured
3. Wrong boot order in BIOS

### Solutions

#### Check BIOS Boot Order

1. Enter BIOS (usually F2, F12, Del, or Esc)
2. Go to Boot settings
3. Ensure your disk is first in boot order
4. Make sure UEFI mode is enabled (not Legacy/CSM)

#### Recreate UEFI Boot Entry

Boot from Live USB:

```bash
# Mount your partitions
mount /dev/sdX2 /mnt        # Root partition
mount /dev/sdX1 /mnt/boot   # EFI partition

# Chroot
arch-chroot /mnt

# Reinstall GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck

# Regenerate config
grub-mkconfig -o /boot/grub/grub.cfg

# Exit and reboot
exit
umount -R /mnt
reboot
```

#### Use efibootmgr to Add Entry

```bash
# Check existing entries
efibootmgr

# Add new entry manually
efibootmgr --create --disk /dev/sda --part 1 --loader /EFI/grub_uefi/grubx64.efi --label "Arch Linux"
```

---

## GRUB Rescue Mode

### Symptoms
- `grub rescue>` prompt appears
- "error: unknown filesystem"
- "error: no such partition"

### Cause
GRUB can't find its configuration or modules.

### Solution 1: Boot Manually from GRUB Rescue

```bash
# List available partitions
grub rescue> ls

# Find your boot partition (look for one that works)
grub rescue> ls (hd0,gpt1)/
grub rescue> ls (hd0,gpt2)/

# Set root and prefix
grub rescue> set root=(hd0,gpt2)
grub rescue> set prefix=(hd0,gpt2)/grub

# Load normal module
grub rescue> insmod normal
grub rescue> normal
```

### Solution 2: Reinstall GRUB from Live USB

```bash
# Boot Live USB
# Mount partitions
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot

# Chroot and reinstall
arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
exit
reboot
```

---

## Black Screen After GRUB

### Symptoms
- GRUB menu appears, you select Arch
- Screen goes black
- No login prompt, nothing happens

### Cause 1: GPU Driver Issue

Common with NVIDIA cards.

#### Temporary Fix (Boot with nomodeset)

1. At GRUB menu, press `e` to edit
2. Find the line starting with `linux`
3. Add `nomodeset` at the end:
   ```
   linux /vmlinuz-linux root=/dev/sdX2 rw quiet nomodeset
   ```
4. Press `Ctrl+X` or `F10` to boot

#### Permanent Fix

After booting with nomodeset:

```bash
# For NVIDIA, install proper drivers
sudo pacman -S nvidia nvidia-utils

# Regenerate initramfs
sudo mkinitcpio -P

# Regenerate GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Cause 2: Display Manager Not Starting

```bash
# Check if display manager is enabled
systemctl status gdm    # or sddm, lightdm

# Enable it
sudo systemctl enable gdm
sudo systemctl start gdm
```

### Cause 3: Wrong Display Output

Try switching outputs:
- Press `Ctrl+Alt+F2` for TTY
- Login and check `xrandr --listmonitors`

---

## Kernel Panic

### Symptoms
- "Kernel panic - not syncing"
- System freezes with error messages

### Common Causes

1. **Corrupted initramfs**
2. **Wrong mkinitcpio hooks**
3. **Missing kernel modules**
4. **Root partition not found**

### Solution: Regenerate Initramfs

Boot from Live USB:

```bash
# Mount system
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot
arch-chroot /mnt

# Regenerate initramfs
mkinitcpio -P

# If LVM, check hooks
nvim /etc/mkinitcpio.conf
# Ensure: HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)

# Regenerate again
mkinitcpio -P

exit
reboot
```

### Check fstab

```bash
# Verify fstab is correct
cat /etc/fstab

# Regenerate if needed (from live USB after mounting)
genfstab -U /mnt >> /mnt/etc/fstab
```

---

## Wrong OS Boots

### Symptoms
- Windows boots instead of Arch
- Wrong Linux distro boots

### Solution: Update GRUB

```bash
# Ensure os-prober is installed
sudo pacman -S os-prober

# Enable os-prober in GRUB config
sudo nvim /etc/default/grub
# Add: GRUB_DISABLE_OS_PROBER=false

# Regenerate GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Set default boot entry
sudo nvim /etc/default/grub
# Change: GRUB_DEFAULT=0  (0 = first entry)
```

### Check Boot Order in BIOS

Windows updates sometimes change UEFI boot order:

1. Enter BIOS
2. Set "grub_uefi" or "Arch Linux" as first boot option

---

## Encrypted Volume Not Unlocking

### Symptoms
- "No key available with this passphrase"
- System hangs asking for password
- Can't type password (keyboard not working)

### Solution 1: Keyboard Not Working

The `keyboard` hook must come BEFORE `encrypt`:

```bash
# Boot Live USB
cryptsetup open /dev/nvme0n1p3 lvm
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
arch-chroot /mnt

# Edit mkinitcpio
nvim /etc/mkinitcpio.conf

# Correct order:
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)

# Regenerate
mkinitcpio -P
exit
reboot
```

### Solution 2: Wrong cryptdevice in GRUB

```bash
# Check GRUB config
nvim /etc/default/grub

# Ensure cryptdevice is correct
GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:lvm"

# Or use UUID (more reliable)
GRUB_CMDLINE_LINUX="cryptdevice=UUID=your-uuid-here:lvm"

# Regenerate
grub-mkconfig -o /boot/grub/grub.cfg
```

### Solution 3: Forgotten Password

> ⚠️ **If you forgot your LUKS password, your data is unrecoverable.** LUKS encryption is designed this way.

---

## Reinstalling GRUB

### Complete GRUB Reinstallation

```bash
# Boot from Live USB
# Mount your system (adjust for your setup)

# Standard:
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot

# LVM:
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/sdX1 /mnt/boot

# Encrypted:
cryptsetup open /dev/nvme0n1p3 lvm
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/EFI

# Chroot
arch-chroot /mnt

# Remove and reinstall GRUB
pacman -S grub efibootmgr

# Install GRUB
# For standard/LVM (EFI at /boot):
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck

# For encrypted (EFI at /boot/EFI):
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub_uefi --recheck

# Copy locale
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Generate config
grub-mkconfig -o /boot/grub/grub.cfg

# Exit and reboot
exit
umount -R /mnt
reboot
```

---

## Boot Diagnostic Commands

```bash
# Check EFI entries
efibootmgr -v

# Check GRUB config
cat /boot/grub/grub.cfg | grep menuentry

# Check kernel parameters
cat /proc/cmdline

# View boot log
journalctl -b

# Check for boot errors
journalctl -b -p err
```

---

## Still Having Issues?

- [Network Issues](network-issues.md) - If you can boot but have no network
- [Driver Problems](driver-problems.md) - If you have display issues
- [System Recovery](system-recovery.md) - For major system problems

---

<div align="center">

[← Troubleshooting Index](README.md) | [Back to Main Guide](../../README.md) | [Next: Network Issues →](network-issues.md)

</div>
