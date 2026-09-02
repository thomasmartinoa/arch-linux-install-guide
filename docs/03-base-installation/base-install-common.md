# Base System Installation

> The shared installation flow for **every** path. Read it top to bottom.

This page is the same for all five installation paths. It branches in exactly two places —
**Step 6 (extra packages)** and **Step 9 (mkinitcpio hooks)** — where you pick the row that
matches the partitioning you did. Everything else is identical no matter what you chose.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Verify Mounts](#step-1-verify-mounts)
- [Step 2: Install the Base System](#step-2-install-the-base-system)
- [Step 3: Generate fstab](#step-3-generate-fstab)
- [Step 4: Enter Chroot](#step-4-enter-chroot)
- [Step 5: System Configuration](#step-5-system-configuration)
- [Step 6: Install Packages](#step-6-install-packages) ← **branches by path**
- [Step 7: Kernel and Microcode](#step-7-kernel-and-microcode)
- [Step 8: GPU Drivers](#step-8-gpu-drivers)
- [Step 9: Configure mkinitcpio](#step-9-configure-mkinitcpio) ← **branches by path**
- [Step 10: Enable Services](#step-10-enable-services)
- [Next: Bootloader](#next-bootloader)

---

## Prerequisites

- [ ] Partitions created, formatted, and mounted at `/mnt`
- [ ] Internet connection working
- [ ] You know which path you followed (Standard, LVM, LUKS+LVM, Btrfs, or Btrfs+LUKS)

```bash
lsblk                      # check mounts
ping -c 3 archlinux.org    # check internet
```

---

## Step 1: Verify Mounts

```bash
lsblk
```

Check your layout against the partitioning guide you followed. Root must be at `/mnt`, and
your ESP must be mounted (at `/mnt/boot` for most paths, `/mnt/efi` for LUKS+LVM).

If anything looks wrong, go back to [Partitioning](../02-partitioning/) — fixing it now is far
easier than fixing it after the system is installed.

---

## Step 2: Install the Base System

```bash
pacstrap -K /mnt base linux linux-firmware vim
```

**What this does:**

| Part | Meaning |
|------|---------|
| `pacstrap` | Install packages into the new root |
| `-K` | Initialise a fresh pacman keyring in the target |
| `/mnt` | Target mount point |
| `base` | Base system meta-package |
| `linux` | The kernel |
| `linux-firmware` | Firmware blobs for common hardware |
| `vim` | A text editor |

> **Why the kernel and an editor here?** The `base` package contains neither. Without `linux`
> you have no kernel to boot; without an editor, the very next step (editing `/etc/hosts`) fails
> with `command not found`. Install them now and the rest of the guide just works.

Takes 5–15 minutes depending on your connection.

---

## Step 3: Generate fstab

`fstab` tells Linux which filesystems to mount at boot.

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

| Part | Meaning |
|------|---------|
| `genfstab` | Generate fstab entries from what is currently mounted |
| `-U` | Use UUIDs instead of device names (survives disk reordering) |
| `>>` | **Append** — using `>` would overwrite the file |

**Always check the result:**

```bash
cat /mnt/etc/fstab
```

Every filesystem you mounted should appear exactly once. If you mounted something after running
`genfstab`, re-run it — but delete the duplicate lines first.

---

## Step 4: Enter Chroot

```bash
arch-chroot /mnt
```

Your prompt changes to `[root@archiso /]#`. From here on, every command affects your new
installation rather than the live USB.

---

## Step 5: System Configuration

### 5.1 Hostname

```bash
echo "archpc" > /etc/hostname
```

Lowercase letters, numbers and hyphens only. Replace `archpc` with whatever you like.

### 5.2 Hosts File

```bash
vim /etc/hosts
```

```
127.0.0.1   localhost
::1         localhost
127.0.1.1   archpc.localdomain archpc
```

> Use the same name you set in 5.1.

### 5.3 Root Password

```bash
passwd
```

Nothing appears as you type — that is normal.

### 5.4 Timezone

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

```bash
# Examples
ln -sf /usr/share/zoneinfo/Asia/Kolkata     /etc/localtime
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/London    /etc/localtime
```

Find yours with `ls /usr/share/zoneinfo/` then `ls /usr/share/zoneinfo/Asia/`.

### 5.5 Locale

```bash
vim /etc/locale.gen
```

Uncomment your locale (remove the leading `#`):

```
en_US.UTF-8 UTF-8
```

```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 5.6 Console Keymap

```bash
echo "KEYMAP=us" > /etc/vconsole.conf
```

Sets the keyboard layout for the text console. Change `us` to `uk`, `de`, `fr` etc. if needed.

> **On `FONT=`:** you can also set a console font here, but only if the font's package is
> installed. Setting `FONT=ter-132n` without installing `terminus-font` makes every
> `mkinitcpio` run fail. If you want the big font, add `terminus-font` to Step 6 first.

### 5.7 Create Your User

```bash
useradd -m -G wheel username
passwd username
```

| Part | Meaning |
|------|---------|
| `-m` | Create the home directory |
| `-G wheel` | Add to the `wheel` group, which gets sudo access in Step 6 |

> Replace `username` throughout. Lowercase, no spaces.

---

## Step 6: Install Packages

### 6.1 Common packages — everyone installs these

```bash
pacman -S base-devel grub efibootmgr dosfstools mtools \
          networkmanager openssh sudo os-prober
```

| Package | Purpose |
|---------|---------|
| `base-devel` | Compiler and build tools (needed later for AUR helpers) |
| `grub` | Bootloader |
| `efibootmgr` | Writes the UEFI boot entry |
| `dosfstools` | FAT tools — GRUB needs these to touch the ESP |
| `mtools` | DOS/FAT utilities |
| `networkmanager` | Network management after reboot |
| `openssh` | SSH client and server |
| `sudo` | Run commands as root |
| `os-prober` | Detects other operating systems for dual boot |

> **systemd-boot users:** you still want everything above except `grub`, `efibootmgr` and
> `os-prober`. `bootctl` ships inside `systemd`, which is already installed.

### 6.2 Extra packages — pick your row

> ### ⚠️ This is branch point 1 of 2. Install the extras for **your** path.

| Your path | Extra packages | Why |
|-----------|----------------|-----|
| **Standard (ext4)** | *(none)* | ext4 tools are already in `base` |
| **LVM** | `lvm2` | LVM tooling + the `lvm2` initramfs hook |
| **LUKS + LVM** | `lvm2 cryptsetup` | `cryptsetup` is **required** — see the warning below |
| **Btrfs** | `btrfs-progs` | Without it the system cannot mount its own root |
| **Btrfs + LUKS** | `btrfs-progs cryptsetup` | Both of the above |

```bash
# Example — Btrfs + LUKS
pacman -S btrfs-progs cryptsetup
```

> ### 🔴 Encrypted paths: `cryptsetup` is not optional
>
> The `encrypt` initramfs hook copies the `cryptsetup` **binary** into your initramfs
> (`/usr/lib/initcpio/install/encrypt` runs `add_binary 'cryptsetup'`). If the package is not
> installed, `mkinitcpio -P` in Step 9 fails with `file not found: cryptsetup` and you end up
> with an initramfs that cannot unlock your disk. Nothing will boot. Install it here.

Your path's page has the details specific to it:

- [Standard](deltas/standard.md) · [LVM](deltas/lvm.md) · [LUKS + LVM](deltas/luks-lvm.md) ·
  [Btrfs](deltas/btrfs.md) · [Btrfs + LUKS](deltas/btrfs-luks.md)

### 6.3 Configure Sudo

```bash
EDITOR=vim visudo
```

Find and uncomment this line by deleting the leading `#`:

```
%wheel ALL=(ALL:ALL) ALL
```

That grants sudo to everyone in the `wheel` group — including the user you made in 5.7.

> Use `visudo`, never a plain editor. It syntax-checks before saving; a broken sudoers file
> locks you out of root entirely.

---

## Step 7: Kernel and Microcode

You already have the `linux` kernel from Step 2. Adding the LTS kernel gives you a fallback to
boot from if a `linux` update ever breaks something:

```bash
pacman -S linux-headers linux-lts linux-lts-headers
```

| Package | Purpose |
|---------|---------|
| `linux-headers` | Needed to build out-of-tree modules (DKMS, VirtualBox, NVIDIA) |
| `linux-lts` | Long-term-support kernel — your rescue boot entry |
| `linux-lts-headers` | Headers for the LTS kernel |

### CPU Microcode

```bash
pacman -S intel-ucode    # Intel CPUs
pacman -S amd-ucode      # AMD CPUs
```

Microcode ships CPU bug fixes and security mitigations that load before the kernel does.
Install the one matching your CPU — check with `lscpu | grep "Model name"` if unsure.

---

## Step 8: GPU Drivers

### Intel

```bash
pacman -S mesa vulkan-intel intel-media-driver
```

### AMD

```bash
pacman -S mesa vulkan-radeon
```

> **Note:** `libva-mesa-driver` and `mesa-vdpau` no longer exist as separate packages — their
> contents were merged into `mesa`. Older guides (including earlier versions of this one) still
> tell you to install them, and the command fails with `target not found`.

### NVIDIA

**Turing (RTX 20xx) and newer:**

```bash
pacman -S nvidia-open nvidia-open-lts nvidia-utils nvidia-settings
```

`nvidia-open` builds against the `linux` kernel and `nvidia-open-lts` against `linux-lts` —
install both so either kernel boots with working graphics.

**Pre-Turing (GTX 10xx and older):** the old `nvidia` / `nvidia-lts` packages have been removed
from the official repositories. These cards now need a legacy maintenance branch from the AUR
(for example `nvidia-580xx-dkms`), which you can only install after the first reboot once you
have an AUR helper. Boot on `mesa` for now — the open `nouveau` driver will get you to a
desktop — and add the legacy driver later.

### Hybrid (laptop with integrated + NVIDIA)

```bash
pacman -S mesa nvidia-open nvidia-open-lts nvidia-utils nvidia-prime
```

Then launch individual apps on the dGPU with `prime-run <application>`.

---

## Step 9: Configure mkinitcpio

The initramfs is a small system that runs before your real root filesystem is available. Its
job is to make root reachable — decrypting a LUKS container, activating LVM, loading the right
filesystem driver — and then hand over. Which hooks you need depends on your path.

```bash
vim /etc/mkinitcpio.conf
```

Find the `HOOKS=` line. The current Arch default looks like this:

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
```

### Pick your row

> ### ⚠️ This is branch point 2 of 2. Use the HOOKS line for **your** path.

| Your path | HOOKS |
|-----------|-------|
| **Standard (ext4)** | `base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck` |
| **Btrfs** | `base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck` |
| **LVM** | `base udev autodetect microcode modconf kms keyboard keymap consolefont block `**`lvm2`**` filesystems fsck` |
| **LUKS + LVM** | `base udev autodetect microcode modconf kms keyboard keymap consolefont block `**`encrypt lvm2`**` filesystems fsck` |
| **Btrfs + LUKS** | `base udev autodetect microcode modconf kms keyboard keymap consolefont block `**`encrypt`**` filesystems fsck` |

Standard and Btrfs need no change at all — Btrfs root is handled by the `filesystems` hook, as
long as you installed `btrfs-progs` in Step 6.

### Why the order matters

Hooks run left to right, and each one depends on the last:

```
keyboard  →  block  →  encrypt  →  lvm2  →  filesystems
   │           │          │          │           │
 you can    disks      unlock     activate    mount
 type       appear     LUKS       LVs inside  root
```

- `keyboard` **before** `encrypt` — otherwise you cannot type your passphrase.
- `encrypt` **before** `lvm2` — the volume group lives *inside* the encrypted container, so
  there is nothing for `lvm2` to find until decryption has happened.

Get this order wrong and the system hangs at boot with no useful error.

### Regenerate

```bash
mkinitcpio -P
```

`-P` rebuilds every kernel preset you have installed (both `linux` and `linux-lts`).

**Read the output.** It should end in `Image generation successful` for each kernel. Any line
starting with `==> ERROR:` means the resulting initramfs is broken and will not boot — fix it
now, while you still have a working shell, rather than discovering it after a reboot.

Confirm your hooks actually ran:

```bash
grep '^HOOKS' /etc/mkinitcpio.conf
```

---

## Step 10: Enable Services

```bash
systemctl enable NetworkManager
systemctl enable sshd
```

| Service | Purpose |
|---------|---------|
| `NetworkManager` | Brings up networking after reboot — without this you have no internet |
| `sshd` | SSH server. Skip it if you do not want remote logins |

---

## Quick Reference

```bash
# Install base system (kernel + editor included)
pacstrap -K /mnt base linux linux-firmware vim
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Configure
echo "archpc" > /etc/hostname
vim /etc/hosts
passwd
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
vim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
useradd -m -G wheel username
passwd username

# Packages
pacman -S base-devel grub efibootmgr dosfstools mtools networkmanager openssh sudo os-prober
pacman -S <your path's extras>          # branch 1 — see Step 6.2
pacman -S linux-headers linux-lts linux-lts-headers
pacman -S intel-ucode                   # or amd-ucode
pacman -S mesa vulkan-intel intel-media-driver   # or your GPU's packages
EDITOR=vim visudo                       # uncomment %wheel

# initramfs
vim /etc/mkinitcpio.conf                # branch 2 — see Step 9
mkinitcpio -P

# Services
systemctl enable NetworkManager
systemctl enable sshd
```

---

## Next: Bootloader

| Your path | Bootloader guide |
|-----------|------------------|
| Standard (ext4) | [GRUB — Standard](bootloader-standard.md) or [systemd-boot](bootloader-systemd.md) |
| LVM | [GRUB — LVM](bootloader-lvm.md) |
| LUKS + LVM | [GRUB — Encrypted](bootloader-encrypted.md) |
| Btrfs | [GRUB — Standard](bootloader-standard.md) or [systemd-boot](bootloader-systemd.md) |
| Btrfs + LUKS | [GRUB — Encrypted](bootloader-encrypted.md) |

---

<div align="center">

[← Partitioning](../02-partitioning/) | [Back to Main Guide](../../README.md) | [Next: Bootloader →](README.md)

</div>
