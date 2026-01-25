# LVM Base Installation

> For users with **LVM Setup** (without encryption).

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
- [Step 9: Configure mkinitcpio](#step-9-configure-mkinitcpio)
- [Step 10: Enable Services](#step-10-enable-services)
- [Next: Bootloader](#next-bootloader)

---

## Prerequisites

Before proceeding, ensure:

- [ ] LVM volumes are created
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
NAME                    MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                       8:0    0   500G  0 disk  
├─sda1                    8:1    0   512M  0 part  /mnt/boot
└─sda2                    8:2    0 499.5G  0 part  
  ├─volgroup0-lv_root   254:0    0    50G  0 lvm   /mnt
  ├─volgroup0-lv_swap   254:1    0     8G  0 lvm   [SWAP]
  └─volgroup0-lv_home   254:2    0   441G  0 lvm   /mnt/home
```

**Key things to verify:**
- `TYPE` shows `lvm` for your logical volumes
- Root (`/mnt`), home (`/mnt/home`), and boot (`/mnt/boot`) are mounted
- Swap shows `[SWAP]`

> If mounts don't look right, go back to [LVM Setup](../02-partitioning/lvm-setup.md)

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

**Expected output (LVM):**
```
# /dev/mapper/volgroup0-lv_root
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /        ext4   rw,relatime  0 1

# /dev/sda1
UUID=xxxx-xxxx                             /boot    vfat   rw,relatime  0 2

# /dev/mapper/volgroup0-lv_home
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /home    ext4   rw,relatime  0 2

# /dev/mapper/volgroup0-lv_swap
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  none     swap   defaults     0 0
```

> 💡 Note: LVM volumes show as `/dev/mapper/...` in comments

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

Enter a strong password (you'll type it twice).

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

**Find your timezone:**
```bash
ls /usr/share/zoneinfo/
```

### 5.5 Configure Locale

```bash
nvim /etc/locale.gen
```

Uncomment (remove `#` from):
```
en_US.UTF-8 UTF-8
```

Generate locale:
```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 5.6 Console Configuration (Optional)

Configure keyboard layout for the virtual console:

```bash
nvim /etc/vconsole.conf
```

Add:
```
KEYMAP=us
```

> 💡 Change `us` to your keyboard layout if needed.

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

> ⚠️ **CRITICAL:** The `lvm2` package is **required** for LVM systems!

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

## Step 9: Configure mkinitcpio

> ⚠️ **This step is REQUIRED for LVM systems!**

The initramfs (initial RAM filesystem) needs to know how to handle LVM volumes before the root filesystem is mounted.

### Edit mkinitcpio.conf

```bash
nvim /etc/mkinitcpio.conf
```

### Find the HOOKS Line

Look for this line:
```
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
```

### Add lvm2 Hook

**Add `lvm2` between `block` and `filesystems`:**

```
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)
```

**Visual comparison:**

| Before | After |
|--------|-------|
| `... block filesystems ...` | `... keyboard keymap consolefont block lvm2 filesystems ...` |

### Why This Matters

```
Boot Process:
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  GRUB    │ -> │ initramfs│ -> │  lvm2    │ -> │  Mount   │
│          │    │  loads   │    │  hook    │    │  root    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                                    ↑
                          Activates LVM volumes
                          so root can be mounted
```

Without the `lvm2` hook, the system won't find your root partition!

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
  -> Running build hook: [block]
  -> Running build hook: [lvm2]          ← LVM hook runs
  -> Running build hook: [filesystems]
  -> Running build hook: [keyboard]
  -> Running build hook: [fsck]
==> Generating module dependencies
==> Creating gzip-compressed initcpio image: /boot/initramfs-linux.img
==> Image generation successful
```

> ✅ Look for `Running build hook: [lvm2]` to confirm the hook is included.

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
echo "KEYMAP=us" > /etc/vconsole.conf  # Optional: set console keymap

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

# IMPORTANT: Add lvm2 to mkinitcpio HOOKS
nvim /etc/mkinitcpio.conf
# Change: HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)
mkinitcpio -P

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
```

---

## Next: Bootloader

Continue to LVM bootloader installation:

→ [LVM Bootloader Installation](bootloader-lvm.md)

---

<div align="center">

[← LVM Setup](../02-partitioning/lvm-setup.md) | [Back to Main Guide](../../README.md) | [Next: Bootloader →](bootloader-lvm.md)

</div>
