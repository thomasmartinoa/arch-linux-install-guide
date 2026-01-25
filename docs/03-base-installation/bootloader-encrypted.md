# 🔐 Encrypted LVM Bootloader Installation

> GRUB setup for **LUKS Encryption with LVM**.

![GRUB Bootloader](../../images/grub-bootloader.png)

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Step 1: Create EFI Directory](#step-1-create-efi-directory)
- [Step 2: Install GRUB](#step-2-install-grub)
- [Step 3: Configure GRUB for Encryption](#step-3-configure-grub-for-encryption)
- [Step 4: Generate Configuration](#step-4-generate-configuration)
- [Step 5: Final Steps](#step-5-final-steps)
- [What Happens at Boot](#-what-happens-at-boot)
- [Troubleshooting](#-troubleshooting)

---

## ✅ Prerequisites

Ensure you have completed:

- [ ] [Encrypted Base Installation](base-install-encrypted.md)
- [ ] mkinitcpio configured with `encrypt lvm2` hooks
- [ ] Still in chroot environment

**Verify critical setup:**
```bash
# Check packages
pacman -Q grub efibootmgr lvm2

# Verify encrypt and lvm2 hooks in mkinitcpio.conf
grep "HOOKS" /etc/mkinitcpio.conf
# Should show: ... block encrypt lvm2 filesystems ...
```

> ⚠️ If you don't see `encrypt lvm2` in HOOKS, go back to [Step 9 of Encrypted Base Installation](base-install-encrypted.md#step-9-configure-mkinitcpio-critical)

---

## 💡 Encrypted Boot Process

```
Power On → UEFI → GRUB → Kernel loads initramfs
                              ↓
                         ┌─────────────────────────────┐
                         │  "Enter passphrase for      │
                         │   /dev/nvme0n1p3:"          │
                         │                             │
                         │  You type password          │
                         └─────────────────────────────┘
                              ↓
                         encrypt hook decrypts LUKS
                              ↓
                         lvm2 hook activates volumes
                              ↓
                         Root mounted → System boots
```

---

## Step 1: Create EFI Directory

### Check Current Mounts

```bash
ls /boot
ls /boot/EFI
```

For encrypted setups, you typically have:
- `/boot` - ext4 partition (unencrypted, contains kernel)
- `/boot/EFI` - FAT32 partition (EFI system partition)

### Mount EFI Partition (if needed)

```bash
mkdir -p /boot/EFI
mount /dev/nvme0n1p1 /boot/EFI
```

> 📝 Replace `/dev/nvme0n1p1` with your EFI partition

---

## Step 2: Install GRUB

### Reload systemd

```bash
systemctl daemon-reload
```

### Install GRUB to EFI

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub_uefi --recheck
```

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

## Step 3: Configure GRUB for Encryption

> ⚠️ **This step is CRITICAL for encrypted systems!**

### Edit GRUB Defaults

```bash
nvim /etc/default/grub
```

### Find Your Encrypted Partition

You need to know your LUKS partition. Find it:

```bash
lsblk -f
```

Look for the partition with `crypto_LUKS`:
```
nvme0n1p3   crypto_LUKS   xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Add cryptdevice Parameter

Find this line:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
```

Find this line (or add it):
```bash
GRUB_CMDLINE_LINUX=""
```

**Add your encrypted device:**
```bash
GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:lvm"
```

> 📝 Replace `/dev/nvme0n1p3` with YOUR encrypted partition!

### Using UUID (More Reliable)

For maximum reliability, use UUID instead of device path:

**Get the UUID:**
```bash
blkid /dev/nvme0n1p3
```

Output:
```
/dev/nvme0n1p3: UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" TYPE="crypto_LUKS"
```

**Use UUID in GRUB:**
```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:lvm"
```

### Complete GRUB Configuration

Your `/etc/default/grub` should look like:

```bash
# Default boot entry
GRUB_DEFAULT=0

# Timeout
GRUB_TIMEOUT=5

# Kernel parameters
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"

# ENCRYPTION - CRITICAL!
GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:lvm"

# Or with UUID (recommended):
# GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:lvm"

# Disable submenu
GRUB_DISABLE_SUBMENU=y

# Enable os-prober
GRUB_DISABLE_OS_PROBER=false
```

### Parameter Breakdown

| Parameter | Meaning |
|-----------|---------|
| `cryptdevice=` | Tell kernel which device to decrypt |
| `/dev/nvme0n1p3` | Your LUKS encrypted partition |
| `:lvm` | Name to map it to (`/dev/mapper/lvm`) |

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

### Verify Encryption Parameters

```bash
grep "cryptdevice" /boot/grub/grub.cfg
```

You should see your cryptdevice parameter in the boot entries:
```
linux /vmlinuz-linux root=/dev/mapper/volgroup0-lv_root ... cryptdevice=/dev/nvme0n1p3:lvm
```

---

## Step 5: Final Steps

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

## 🔓 What Happens at Boot

### 1. GRUB Menu Appears

You'll see the GRUB menu with your Linux entries.

### 2. Password Prompt

After selecting an entry, you'll see:
```
A password is required to access the lvm volume:
Enter passphrase for /dev/nvme0n1p3: _
```

### 3. Enter Your LUKS Password

- Type your encryption password
- Characters won't show (that's normal)
- Press Enter

### 4. Decryption Success

```
lvm: key slot 0 opened
```

Then boot continues normally.

### 5. Login Prompt

You'll reach the login prompt. Use your user credentials (not LUKS password).

---

## ✅ Quick Reference Summary

```bash
# Create EFI directory (if needed)
mkdir -p /boot/EFI
mount /dev/nvme0n1p1 /boot/EFI

# Install GRUB
systemctl daemon-reload
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Configure GRUB for encryption
nvim /etc/default/grub
# Add: GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:lvm"

# Generate config
grub-mkconfig -o /boot/grub/grub.cfg

# Verify
grep "cryptdevice" /boot/grub/grub.cfg

# Exit and reboot
exit
umount -a
reboot
```

---

## 🔧 Troubleshooting

### "No key available with this passphrase"

Wrong LUKS password. Try again (usually 3 attempts).

### "Slot 0 opened" Then System Hangs

The `encrypt` or `lvm2` hook is missing from mkinitcpio.

**Fix from live USB:**
```bash
# Decrypt and mount
cryptsetup open /dev/nvme0n1p3 lvm
mount /dev/mapper/volgroup0-lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/EFI
mount /dev/mapper/volgroup0-lv_home /mnt/home

# Chroot and fix
arch-chroot /mnt

# Edit mkinitcpio.conf
nvim /etc/mkinitcpio.conf
# Ensure: HOOKS=(... block encrypt lvm2 filesystems ...)

# Regenerate
mkinitcpio -P

# Exit and reboot
exit
reboot
```

### "device /dev/nvme0n1p3 not found"

Device path changed. Use UUID instead:

```bash
# Get UUID
blkid /dev/nvme0n1p3

# Edit GRUB
nvim /etc/default/grub
# Change to: GRUB_CMDLINE_LINUX="cryptdevice=UUID=your-uuid-here:lvm"

# Regenerate
grub-mkconfig -o /boot/grub/grub.cfg
```

### "Volume group not found" After Password

LVM not activated. Ensure `lvm2` hook is AFTER `encrypt` in mkinitcpio.

### Boot Drops to Emergency Shell

```bash
# At the emergency prompt, try:
cryptsetup open /dev/nvme0n1p3 lvm
vgchange -ay
mount /dev/mapper/volgroup0-lv_root /sysroot
exit
```

### GRUB Not in UEFI Menu

```bash
# From live USB, chroot and reinstall GRUB
arch-chroot /mnt
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
```

---

## 🔐 Security Notes

### Password Entry

- Your LUKS password is entered BEFORE your user password
- Failed LUKS attempts may lock you out temporarily
- There's no password recovery - keep your password safe!

### Boot Partition Security

Your `/boot` partition is **NOT encrypted**. This contains:
- Kernel images
- initramfs
- GRUB files

Someone with physical access could potentially tamper with these. For higher security, consider:
- UEFI Secure Boot
- Encrypted /boot (advanced topic)
- Physical security measures

---

## ➡️ Next Steps

After rebooting successfully:

→ [First Boot](../04-post-installation/first-boot.md)

---

<div align="center">

[← Base Installation](base-install-encrypted.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
