# Encrypted LVM Base Installation

> For users with **LUKS Encryption + LVM**.

![Base Installation](../../images/base-install.png)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Verify Mounts](#step-1-verify-mounts)
- [Step 2: Install Base System](#step-2-install-base-system)
- [Step 3: Generate fstab](#step-3-generate-fstab)
- [Step 4: Enter Chroot](#step-4-enter-chroot)
- [Step 5: System Configuration](#step-5-system-configuration)
- [Step 6: Install Packages](#step-6-install-packages)
- [Step 7: Install Kernel](#step-7-install-kernel)
- [Step 8: GPU Drivers](#step-8-gpu-drivers)
- [Step 9: Configure mkinitcpio](#step-9-configure-mkinitcpio-critical)
- [Step 10: Enable Services](#step-10-enable-services)
- [Next: Bootloader](#next-bootloader)

---

## Prerequisites

Before proceeding, ensure:

- [ ] LUKS container is created and opened
- [ ] LVM volumes are created inside the encrypted container
- [ ] Volumes are formatted and mounted at `/mnt`
- [ ] Internet connection is working

**Quick verification:**
```bash
# Check mounts
lsblk

# Check internet
ping -c 3 archlinux.org
```

---

## Step 1: Verify Mounts

```bash
lsblk
```

### Expected Output

```
NAME                      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
nvme0n1                   259:0    0     1T  0 disk  
├─nvme0n1p1               259:1    0   512M  0 part  /mnt/boot/EFI
├─nvme0n1p2               259:2    0     1G  0 part  /mnt/boot
└─nvme0n1p3               259:3    0   998G  0 part  
  └─lvm                   254:0    0   998G  0 crypt           ← Encrypted!
    ├─volgroup0-lv_root   254:1    0   200G  0 lvm   /mnt
    ├─volgroup0-lv_swap   254:2    0    40G  0 lvm   [SWAP]
    └─volgroup0-lv_home   254:3    0   500G  0 lvm   /mnt/home
```

**Key things to verify:**
- `TYPE` shows `crypt` for your encrypted container
- `TYPE` shows `lvm` for your logical volumes inside
- Root, home, boot, and EFI are all mounted
- Swap shows `[SWAP]`

> If mounts don't look right, go back to [LVM Encryption](../02-partitioning/lvm-encryption.md)

---

## Step 2: Install Base System

```bash
pacstrap -K /mnt base
```

**What this does:**
| Part | Meaning |
|------|--------|
| `pacstrap` | Install packages to new root |
| `-K` | Initialize pacman keyring in target |
| `/mnt` | Target mount point |
| `base` | Base system meta-package |

Wait for installation to complete (5-15 minutes).

---

## Step 3: Generate fstab

```bash
genfstab -U -p /mnt >> /mnt/etc/fstab
```

**Verify the result:**
```bash
cat /mnt/etc/fstab
```

**Expected output (Encrypted LVM):**
```
# /dev/mapper/volgroup0-lv_root
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /         ext4   rw,relatime  0 1

# /dev/nvme0n1p2
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /boot     ext4   rw,relatime  0 2

# /dev/nvme0n1p1
UUID=xxxx-xxxx                             /boot/EFI vfat   rw,relatime  0 2

# /dev/mapper/volgroup0-lv_home
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /home     ext4   rw,relatime  0 2

# /dev/mapper/volgroup0-lv_swap
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  none      swap   defaults     0 0
```

> 💡 The encrypted container itself is NOT in fstab - it's handled by initramfs

---

## Step 4: Enter Chroot

```bash
arch-chroot /mnt
```

Your prompt changes to `[root@archiso /]#` - you're now "inside" your new system!

---

## Step 5: System Configuration

### 5.1 Set Hostname

```bash
echo "archpc" > /etc/hostname
```

Replace `archpc` with your preferred computer name.

### 5.2 Configure Hosts File

```bash
nvim /etc/hosts
```

Add these lines:
```
127.0.0.1   localhost
::1         localhost
127.0.1.1   archpc.localdomain archpc
```

### 5.3 Set Root Password

```bash
passwd
```

Enter a strong password.

### 5.4 Set Timezone

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

**Example:**
```bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
```

### 5.5 Configure Locale

```bash
nvim /etc/locale.gen
```

Uncomment:
```
en_US.UTF-8 UTF-8
```

Generate locale:
```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 5.6 Console Configuration (Optional)

```bash
nvim /etc/vconsole.conf
```

Add:
```
KEYMAP=us
FONT=ter-132n
```

### 5.7 Create Your User

```bash
useradd -m -g users -G wheel username
passwd username
```

Replace `username` with your preferred username.

---

## Step 6: Install Packages

### Essential Packages (Including LVM!)

```bash
pacman -S base-devel dosfstools grub efibootmgr lvm2 mtools \
vim neovim networkmanager openssh os-prober sudo
```

> ⚠️ **CRITICAL:** The `lvm2` package is **required** for encrypted LVM systems!

**Package descriptions:**
| Package | Purpose |
|---------|---------|
| `base-devel` | Development tools |
| `dosfstools` | FAT filesystem utilities |
| `grub` | Bootloader |
| `efibootmgr` | EFI boot manager |
| **`lvm2`** | **LVM tools (REQUIRED!)** |
| `mtools` | DOS disk utilities |
| `networkmanager` | Network connection manager |
| `openssh` | SSH server/client |
| `os-prober` | Detect other operating systems |
| `sudo` | Run commands as root |

### Configure Sudo

```bash
EDITOR=nvim visudo
```

Find and uncomment:
```
%wheel ALL=(ALL:ALL) ALL
```

---

## Step 7: Install Kernel and Microcode

```bash
pacman -S linux linux-headers linux-lts linux-lts-headers linux-firmware
```

### Install CPU Microcode (Important!)

**For Intel CPU:**
```bash
pacman -S intel-ucode
```

**For AMD CPU:**
```bash
pacman -S amd-ucode
```

> 💡 Microcode provides CPU stability and security patches. Install the one matching your CPU!

**Package descriptions:**
| Package | Purpose |
|---------|---------|
| `linux` | Latest kernel |
| `linux-headers` | Kernel headers |
| `linux-lts` | Long-term support kernel |
| `linux-lts-headers` | LTS kernel headers |
| `linux-firmware` | Firmware for hardware |

---

## Step 8: GPU Drivers

### Intel GPU

```bash
pacman -S mesa intel-media-driver
```

### AMD GPU

```bash
pacman -S mesa libva-mesa-driver
```

### NVIDIA GPU

```bash
pacman -S nvidia nvidia-lts nvidia-utils
```

---

## Step 9: Configure mkinitcpio (CRITICAL!)

> ⚠️ **This step is ABSOLUTELY REQUIRED for encrypted systems!**

The initramfs needs to:
1. Decrypt the LUKS container (`encrypt` hook)
2. Activate LVM volumes (`lvm2` hook)

Without these hooks, your system **WILL NOT BOOT**!

### Edit mkinitcpio.conf

```bash
nvim /etc/mkinitcpio.conf
```

### Find the HOOKS Line

Look for this line:
```
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
```

### Add encrypt and lvm2 Hooks

**Add `keyboard`, `encrypt`, and `lvm2` in the correct order:**

```
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)
```

> ⚠️ **IMPORTANT:** `keyboard` must come BEFORE `block` so you can type your encryption password!

**Visual comparison:**

| Before | After |
|--------|-------|
| `... autodetect modconf block filesystems keyboard fsck` | `... autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck` |

> ⚠️ **ORDER MATTERS!** 
> - `keyboard` MUST come BEFORE `block` (so you can type password)
> - `encrypt` MUST come BEFORE `lvm2` (decrypt before activating LVM)

### Why This Order Matters

```
Boot Process:
┌──────┐   ┌──────────┐   ┌─────────┐   ┌──────────┐   ┌───────┐
│ GRUB │ → │ initramfs│ → │ encrypt │ → │   lvm2   │ → │ mount │
│      │   │  loads   │   │  hook   │   │   hook   │   │ root  │
└──────┘   └──────────┘   └─────────┘   └──────────┘   └───────┘
                              ↓              ↓
                         Decrypts        Activates
                         LUKS            LVM volumes
                         container       inside
```

1. `encrypt` hook decrypts the LUKS container
2. `lvm2` hook activates the LVM volumes inside
3. Then root can be mounted

If reversed, LVM would try to activate before decryption = **fail**!

### Regenerate initramfs

```bash
mkinitcpio -P
```

**Or for specific presets:**
```bash
mkinitcpio -p linux
mkinitcpio -p linux-lts
```

**Expected output:**
```
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
  -> -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf -g /boot/initramfs-linux.img
==> Starting build: 6.x.x-arch1-1
  -> Running build hook: [base]
  -> Running build hook: [udev]
  -> Running build hook: [autodetect]
  -> Running build hook: [modconf]
  -> Running build hook: [kms]
  -> Running build hook: [keyboard]      ← Keyboard hook (for password entry)
  -> Running build hook: [keymap]
  -> Running build hook: [consolefont]
  -> Running build hook: [block]
  -> Running build hook: [encrypt]       ← Encryption hook runs
  -> Running build hook: [lvm2]          ← LVM hook runs
  -> Running build hook: [filesystems]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating gzip-compressed initcpio image: /boot/initramfs-linux.img
==> Image generation successful
```

> ✅ **Verify `[keyboard]` comes before `[block]`, and both `[encrypt]` and `[lvm2]` hooks are listed!**

---

## Step 10: Enable Services

```bash
systemctl enable NetworkManager
systemctl enable sshd
```

---

## Quick Reference Summary

```bash
# Install base system
pacstrap -K /mnt base

# Generate fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Enter chroot
arch-chroot /mnt

# Configure system
echo "archpc" > /etc/hostname
nvim /etc/hosts
passwd
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
nvim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf  # Set console keymap

# Create user
useradd -m -g users -G wheel username
passwd username

# Install packages (INCLUDE lvm2!)
pacman -S base-devel dosfstools grub efibootmgr lvm2 mtools vim neovim networkmanager openssh os-prober sudo
pacman -S linux linux-headers linux-lts linux-lts-headers linux-firmware
pacman -S intel-ucode  # or amd-ucode for AMD CPUs
pacman -S mesa intel-media-driver  # or your GPU driver

# Configure sudo
EDITOR=nvim visudo

# CRITICAL: Add keyboard, encrypt, lvm2 to mkinitcpio HOOKS
nvim /etc/mkinitcpio.conf
# Change: HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)
mkinitcpio -P

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
```

---

## Encryption Notes

### What Happens at Boot

1. GRUB loads the kernel and initramfs
2. Initramfs prompts for your LUKS password
3. Password decrypts the container
4. LVM volumes become available
5. Root is mounted and boot continues

### Password Prompt

At boot, you'll see:
```
A password is required to access the lvm volume:
Enter passphrase for /dev/nvme0n1p3:
```

Type your LUKS password (characters won't show).

### Wrong Password

If you enter the wrong password:
```
No key available with this passphrase.
```

You can try again (usually 3 attempts before dropping to emergency shell).

---

## Next: Bootloader

Continue to encrypted bootloader installation:

→ [Encrypted Bootloader Installation](bootloader-encrypted.md)

---

<div align="center">

[← LVM Encryption](../02-partitioning/lvm-encryption.md) | [Back to Main Guide](../../README.md) | [Next: Bootloader →](bootloader-encrypted.md)

</div>
