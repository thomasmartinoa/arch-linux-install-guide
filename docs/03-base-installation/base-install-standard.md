# 📄 Standard Base Installation

> For users with **Basic** or **Advanced** partitioning (no LVM, no encryption).

![Base Installation](../../images/base-install.png)

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Step 1: Verify Mounts](#step-1-verify-mounts)
- [Step 2: Install Base System](#step-2-install-base-system)
- [Step 3: Generate fstab](#step-3-generate-fstab)
- [Step 4: Enter Chroot](#step-4-enter-chroot)
- [Step 5: System Configuration](#step-5-system-configuration)
- [Step 6: Install Packages](#step-6-install-packages)
- [Step 7: Install Kernel and Microcode](#step-7-install-kernel-and-microcode)
- [Step 8: Regenerate initramfs](#step-8-regenerate-initramfs)
- [Step 9: GPU Drivers](#step-9-gpu-drivers)
- [Step 10: Enable Services](#step-10-enable-services)
- [Next: Bootloader](#-next-bootloader)

---

## ✅ Prerequisites

Before proceeding, ensure:

- [ ] Partitions are created and formatted
- [ ] Partitions are mounted at `/mnt`
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

### Expected Output (Basic Partitioning)

```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   500G  0 disk
├─sda1   8:1    0   512M  0 part /mnt/boot
├─sda2   8:2    0 491.5G  0 part /mnt
└─sda3   8:3    0     8G  0 part [SWAP]
```

### Expected Output (Advanced with Separate /home)

```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   500G  0 disk
├─sda1   8:1    0   512M  0 part /mnt/boot
├─sda2   8:2    0    50G  0 part /mnt
├─sda3   8:3    0 441.5G  0 part /mnt/home
└─sda4   8:4    0     8G  0 part [SWAP]
```

> ⚠️ If mounts don't look right, go back to [Partitioning](../02-partitioning/)

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

**What gets installed:**
- Core system utilities
- Package manager (pacman)
- Basic filesystem tools
- System libraries

Wait for installation to complete (5-15 minutes depending on your internet).

---

## Step 3: Generate fstab

The fstab file tells Linux which partitions to mount at boot.

```bash
genfstab -U -p /mnt >> /mnt/etc/fstab
```

**Command breakdown:**
| Part | Meaning |
|------|---------|
| `genfstab` | Generate fstab entries |
| `-U` | Use UUIDs (more reliable than device names) |
| `-p` | Exclude pseudofs mounts |
| `>>` | Append to file |

**Verify the result:**
```bash
cat /mnt/etc/fstab
```

**Expected output:**
```
# /dev/sda2
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  /        ext4   rw,relatime  0 1

# /dev/sda1
UUID=xxxx-xxxx                             /boot    vfat   rw,relatime  0 2

# /dev/sda3
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  none     swap   defaults     0 0
```

---

## Step 4: Enter Chroot

Chroot changes the apparent root directory to your new system.

```bash
arch-chroot /mnt
```

**What this does:**
- Changes root to `/mnt`
- Your prompt changes to `[root@archiso /]#`
- You're now "inside" your new system

> 💡 From this point, all commands affect your new installation, not the live USB.

---

## Step 5: System Configuration

### 5.1 Set Hostname

```bash
echo "archpc" > /etc/hostname
```

Replace `archpc` with your preferred computer name.

**Rules for hostname:**
- Lowercase letters, numbers, hyphens only
- No spaces or special characters
- Examples: `myarch`, `desktop-pc`, `arch-laptop`

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

> 📝 Replace `archpc` with your hostname from step 5.1

### 5.3 Set Root Password

```bash
passwd
```

- Enter a strong password
- You'll be prompted to type it twice
- Characters won't show while typing (that's normal)

### 5.4 Set Timezone

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

**Examples:**
```bash
# India
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

# US Eastern
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# UK
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
```

**Find your timezone:**
```bash
ls /usr/share/zoneinfo/
ls /usr/share/zoneinfo/Asia/
```

### 5.5 Configure Locale

```bash
nvim /etc/locale.gen
```

Find and uncomment (remove `#` from) your locale:
```
en_US.UTF-8 UTF-8
```

Generate locale:
```bash
locale-gen
```

Set system language:
```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 5.6 Console Configuration (Optional)

Configure keyboard layout and font for the virtual console (TTY):

```bash
nvim /etc/vconsole.conf
```

Add:
```
KEYMAP=us
```

> 💡 This sets the keyboard layout for the console before GUI loads. Change `us` to your layout if needed (e.g., `uk`, `de`, `fr`).

### 5.7 Create Your User

```bash
useradd -m -g users -G wheel username
passwd username
```

**Command breakdown:**
| Part | Meaning |
|------|---------|
| `useradd` | Create user |
| `-m` | Create home directory |
| `-g users` | Primary group |
| `-G wheel` | Add to wheel group (for sudo) |
| `username` | Your username |

> 📝 Replace `username` with your preferred username (lowercase, no spaces)

---

## Step 6: Install Packages

### Essential Packages

```bash
pacman -S base-devel dosfstools grub efibootmgr mtools \
vim neovim networkmanager openssh os-prober sudo
```

**Package descriptions:**
| Package | Purpose |
|---------|---------|
| `base-devel` | Development tools (gcc, make, etc.) |
| `dosfstools` | FAT filesystem utilities |
| `grub` | Bootloader |
| `efibootmgr` | EFI boot manager |
| `mtools` | DOS disk utilities |
| `vim` / `neovim` | Text editors |
| `networkmanager` | Network connection manager |
| `openssh` | SSH server/client |
| `os-prober` | Detect other operating systems |
| `sudo` | Run commands as root |

### Filesystem-Specific Packages

**If using Btrfs:** (Required!)
```bash
pacman -S btrfs-progs
```

**If using LVM:** (Already covered in LVM guide)
```bash
pacman -S lvm2
```

> ⚠️ **Btrfs Users:** You MUST install `btrfs-progs` or your system won't boot!

### Configure Sudo

```bash
EDITOR=nvim visudo
```

Find this line:
```
# %wheel ALL=(ALL:ALL) ALL
```

Remove the `#` to uncomment:
```
%wheel ALL=(ALL:ALL) ALL
```

This allows users in the `wheel` group to use sudo.

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
| `linux-headers` | Kernel headers (for building modules) |
| `linux-lts` | Long-term support kernel (backup) |
| `linux-lts-headers` | LTS kernel headers |
| `linux-firmware` | Firmware for common hardware |

> 💡 Installing both kernels gives you a fallback if one has issues.

---

## Step 8: Regenerate initramfs

After installing the kernel, regenerate the initial ramdisk:

```bash
mkinitcpio -P
```

**Alternative (specific presets):**
```bash
mkinitcpio -p linux
mkinitcpio -p linux-lts
```

**What this does:**
| Command | Meaning |
|---------|---------|
| `mkinitcpio -P` | Regenerate **all** presets (recommended) |
| `mkinitcpio -p linux` | Regenerate only linux preset |
| `mkinitcpio -p linux-lts` | Regenerate only linux-lts preset |

> 💡 Use `-P` (capital P) to regenerate all kernels at once - modern and convenient!

**Expected output:**
```
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'default'
...
==> Image generation successful
```

---

## Step 9: GPU Drivers

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

> 📝 For NVIDIA with both kernels, install drivers for both.

### Integrated + Dedicated GPU (Hybrid)

```bash
# Intel + NVIDIA
pacman -S mesa intel-media-driver nvidia nvidia-lts nvidia-utils

# AMD + NVIDIA  
pacman -S mesa libva-mesa-driver nvidia nvidia-lts nvidia-utils
```

---

## Step 10: Enable Services

Enable services to start at boot:

```bash
systemctl enable NetworkManager
systemctl enable sshd
```

**What this does:**
| Service | Purpose |
|---------|---------|
| `NetworkManager` | Automatic network connection |
| `sshd` | SSH daemon (remote access) |

---

## ✅ Quick Reference Summary

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

# Install packages
pacman -S base-devel dosfstools grub efibootmgr mtools vim neovim networkmanager openssh os-prober sudo
pacman -S linux linux-headers linux-lts linux-lts-headers linux-firmware
pacman -S intel-ucode  # or amd-ucode for AMD CPUs
pacman -S mesa intel-media-driver  # or your GPU driver

# Configure sudo
EDITOR=nvim visudo

# Regenerate initramfs
mkinitcpio -P

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
```

---

## ➡️ Next: Bootloader

Continue to bootloader installation:

→ [Standard Bootloader Installation](bootloader-standard.md)

---

<div align="center">

[← Partitioning](../02-partitioning/) | [Back to Main Guide](../../README.md) | [Next: Bootloader →](bootloader-standard.md)

</div>
