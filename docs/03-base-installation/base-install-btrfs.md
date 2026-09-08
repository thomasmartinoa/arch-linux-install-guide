# Base Installation — Btrfs

> For **Btrfs with subvolumes** (no encryption).

This guide is complete on its own. Follow it top to bottom — every command here applies to
your setup, and there is nothing to pick or skip.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Verify Your Mounts](#step-1-verify-your-mounts)
- [Step 2: Install the Base System](#step-2-install-the-base-system)
- [Step 3: Generate fstab](#step-3-generate-fstab)
- [Step 4: Enter the New System](#step-4-enter-the-new-system)
- [Step 5: Configure the System](#step-5-configure-the-system)
- [Step 6: Install Packages](#step-6-install-packages)
- [Step 7: Kernel and Microcode](#step-7-kernel-and-microcode)
- [Step 8: GPU Drivers](#step-8-gpu-drivers)
- [Step 9: Build the initramfs](#step-9-build-the-initramfs)
- [Step 10: Enable Services](#step-10-enable-services)
- [Quick Reference](#quick-reference)
- [Next Step](#next-step)

---

## Prerequisites

You should have just finished **[Btrfs Setup](../02-partitioning/btrfs-setup.md)**
.

- [ ] Partitions created, formatted and mounted under `/mnt`
- [ ] Internet connection working in the live environment

```bash
lsblk                      # check your mounts
ping -c 3 archlinux.org    # check your connection
```

If the ping fails, go back to
[Live Environment Setup](../01-pre-installation/live-environment.md#connecting-to-the-internet).
Everything below needs to download packages.

---

## Step 1: Verify Your Mounts

```bash
lsblk -f
```

**You should see something like this:**

```
NAME   FSTYPE LABEL MOUNTPOINTS
vda
├─vda1 vfat         /mnt/boot
└─vda2 btrfs  arch  /mnt/swap
                    /mnt/var/cache
                    /mnt/var/log
                    /mnt/.snapshots
                    /mnt/home
                    /mnt
```

One partition carrying many mount points is exactly right — those are your subvolumes.
Use `lsblk -f` (with `-f`) to see this view.

> ⚠️ **Do not continue until this looks right.** Every step below writes into `/mnt`. A wrong
> mount here means reinstalling later, and it is far cheaper to fix now.

---

## Step 2: Install the Base System

```bash
pacstrap -K /mnt base linux linux-firmware vim
```

**What each part does:**

| Part | Meaning |
|------|---------|
| `pacstrap` | Install packages into your new system at `/mnt` |
| `-K` | Create a fresh pacman keyring in the target |
| `base` | The minimal Arch base system |
| `linux` | The kernel |
| `linux-firmware` | Firmware for common hardware (Wi-Fi, GPU, etc.) |
| `vim` | A text editor |

> **Why the kernel and an editor are on this line.** The `base` package contains neither.
> Without `linux` you would have no kernel to boot. Without an editor, the very next step —
> editing `/etc/hosts` — fails with `command not found`. Many older guides install `base` alone
> and leave you stuck.

This downloads a few hundred megabytes and takes 5–15 minutes.

---

## Step 3: Generate fstab

`fstab` is the list of filesystems your system mounts at every boot. Generating it from what is
currently mounted is why Step 1 mattered.

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

| Part | Meaning |
|------|---------|
| `-U` | Identify filesystems by UUID, so they still work if drive letters change |
| `>>` | **Append.** A single `>` would wipe the file — always use two |

**Check the result:**

```bash
cat /mnt/etc/fstab
```

```
# /dev/vda2 LABEL=arch
UUID=xxxx  /            btrfs  rw,noatime,compress=zstd,subvol=/@           0 0
UUID=xxxx  /home        btrfs  rw,noatime,compress=zstd,subvol=/@home       0 0
UUID=xxxx  /.snapshots  btrfs  rw,noatime,compress=zstd,subvol=/@snapshots  0 0
UUID=xxxx  /var/log     btrfs  rw,noatime,compress=zstd,subvol=/@var_log    0 0
UUID=xxxx  /var/cache   btrfs  rw,noatime,compress=zstd,subvol=/@var_cache  0 0
UUID=xxxx  /swap        btrfs  rw,noatime,subvol=/@swap                     0 0

# /dev/vda1
UUID=XXXX-XXXX  /boot   vfat   rw,relatime  0 2

# swap file
/swap/swapfile  none    swap   defaults     0 0
```

> Every Btrfs line must carry a `subvol=` option, and `/swap` must **not** have `compress`.
> If either is wrong, fix it now — this file is what mounts your system at every boot.

If a filesystem is missing, mount it and re-run `genfstab` — but delete the duplicate lines
afterwards.

---

## Step 4: Enter the New System

```bash
arch-chroot /mnt
```

Your prompt changes to `[root@archiso /]#`. From here on you are working *inside* your new
installation, not the live USB.

---

## Step 5: Configure the System

### 5.1 Hostname

Your computer's name on the network.

```bash
echo "archpc" > /etc/hostname
```

Use lowercase letters, digits and hyphens. Replace `archpc` with whatever you like.

### 5.2 Hosts File

```bash
vim /etc/hosts
```

Add these three lines:

```
127.0.0.1   localhost
::1         localhost
127.0.1.1   archpc.localdomain archpc
```

> Use the same name you chose in 5.1. In vim: press `i` to type, then `Esc`, then `:wq` and
> `Enter` to save.

### 5.3 Root Password

```bash
passwd
```

Nothing appears as you type — that is normal, not a broken keyboard.

### 5.4 Time Zone

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

Find yours with `ls /usr/share/zoneinfo/`, then `ls /usr/share/zoneinfo/Asia/`.

### 5.5 Language

```bash
vim /etc/locale.gen
```

Find your locale and delete the `#` in front of it:

```
en_US.UTF-8 UTF-8
```

Then generate it:

```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 5.6 Keyboard Layout

```bash
echo "KEYMAP=us" > /etc/vconsole.conf
```

Change `us` to `uk`, `de`, `fr` and so on if needed.

> **On console fonts:** you can also set `FONT=` here, but only if that font's package is
> installed. Setting `FONT=ter-132n` without installing `terminus-font` makes every future
> `mkinitcpio` run print a warning.

### 5.7 Create Your User

Day-to-day work should not happen as root.

```bash
useradd -m -G wheel username
passwd username
```

| Part | Meaning |
|------|---------|
| `-m` | Create `/home/username` |
| `-G wheel` | Add to the `wheel` group, which gets `sudo` access in Step 6 |

> Replace `username` everywhere. Lowercase, no spaces.

---

## Step 6: Install Packages

### 6.1 Core packages

```bash
pacman -S base-devel grub efibootmgr dosfstools mtools \
          networkmanager openssh sudo os-prober
```

| Package | Purpose |
|---------|---------|
| `base-devel` | Compilers and build tools — needed later for AUR packages |
| `grub` | The bootloader |
| `efibootmgr` | Writes the UEFI boot entry |
| `dosfstools` | FAT tools — GRUB needs these to write to the ESP |
| `mtools` | More FAT utilities |
| `networkmanager` | Networking after you reboot |
| `openssh` | SSH client and server |
| `sudo` | Run single commands as root |
| `os-prober` | Detects other operating systems for dual boot |

### 6.2 Packages this setup requires

```bash
pacman -S btrfs-progs
```

| Package | Why you need it |
|---------|-----------------|
| `btrfs-progs` | Btrfs tools — `mkfs`, `scrub`, `subvolume`, and the fsck helper the boot process calls |

> ### 🔴 `btrfs-progs` is mandatory
>
> Your root filesystem **is** Btrfs. Without these tools the installed system cannot check or
> mount its own root. Nothing warns you at install time — it simply fails to boot.

### 6.3 Enable sudo

```bash
EDITOR=vim visudo
```

Find this line and delete the leading `#`:

```
%wheel ALL=(ALL:ALL) ALL
```

That grants `sudo` to everyone in the `wheel` group — including the user you made in 5.7.

> Always use `visudo`, never a plain editor. It checks the syntax before saving. A broken
> sudoers file disables `sudo` completely, and fixing it needs a root shell you may not have.

---

## Step 7: Kernel and Microcode

You already have the `linux` kernel from Step 2. Adding the LTS kernel gives you a second,
slower-moving kernel to boot from if an update ever breaks the main one.

```bash
pacman -S linux-headers linux-lts linux-lts-headers
```

| Package | Purpose |
|---------|---------|
| `linux-headers` | Needed to build extra kernel modules (NVIDIA, VirtualBox, DKMS) |
| `linux-lts` | Long-term-support kernel — your rescue option |
| `linux-lts-headers` | Headers for that kernel |

### CPU microcode

Microcode carries CPU bug fixes and security mitigations, loaded before the kernel starts.

```bash
pacman -S intel-ucode      # Intel CPUs
pacman -S amd-ucode        # AMD CPUs
```

Not sure which you have?

```bash
lscpu | grep "Model name"
```

> Install only the one matching your CPU. GRUB picks it up automatically when you generate its
> config in the next guide.

---

## Step 8: GPU Drivers

Install the set matching your graphics hardware. Check with `lspci | grep -i vga`.

### Intel

```bash
pacman -S mesa vulkan-intel intel-media-driver
```

### AMD

```bash
pacman -S mesa vulkan-radeon
```

> **Note:** `libva-mesa-driver` and `mesa-vdpau` no longer exist — they were merged into `mesa`.
> Older guides still list them and the command fails with `target not found`.

### NVIDIA — RTX 20-series and newer

```bash
pacman -S nvidia-open nvidia-open-lts nvidia-utils nvidia-settings
```

`nvidia-open` matches the `linux` kernel and `nvidia-open-lts` matches `linux-lts`. Install both
so either kernel gives you working graphics.

### NVIDIA — GTX 10-series and older

The old `nvidia` and `nvidia-lts` packages have been **removed from the official repositories**.
These cards need a legacy driver from the AUR, which you cannot install until after the first
reboot. Install `mesa` for now — the open-source `nouveau` driver will get you to a desktop —
and add the legacy driver later from
[Drivers](../04-post-installation/drivers.md#nvidia-graphics).

```bash
pacman -S mesa
```

---

## Step 9: Build the initramfs

The initramfs is a small system that runs before your real root filesystem is available. Its one
job is to make root reachable, then hand over.

On this path it needs no changes at all — the default configuration already does everything
required.

```bash
grep '^HOOKS' /etc/mkinitcpio.conf
```

Confirm it matches:

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
```

> **Why no Btrfs hook?** Unlike LVM or LUKS, Btrfs needs no special hook. The standard
> `filesystems` hook loads the Btrfs driver on its own — as long as `btrfs-progs` is installed,
> which you did in Step 6.

### Build it

```bash
mkinitcpio -P
```

`-P` rebuilds the images for **every** kernel you installed — both `linux` and `linux-lts`.

### Read the output

It should end with `Image generation successful` for each kernel.

You will almost certainly see this, and it is harmless:

```
==> WARNING: consolefont: no font found in configuration
```

That is just the `consolefont` hook noting you set no `FONT=` in Step 5.6. It skips itself.

**`WARNING` is fine. `ERROR` is not.** Any line starting with `==> ERROR:` means the initramfs
is broken and the system will not boot. Fix it now, while you still have a working shell.

---

## Step 10: Enable Services

```bash
systemctl enable NetworkManager
systemctl enable sshd
```

| Service | Purpose |
|---------|---------|
| `NetworkManager` | Brings up networking after reboot — **without this you have no internet** |
| `sshd` | SSH server. Skip it if you do not want remote logins |

> These only take effect after you reboot. That is expected.

---

## Quick Reference

The whole guide, condensed:

```bash
# Install the base system
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
pacman -S btrfs-progs
pacman -S linux-headers linux-lts linux-lts-headers
pacman -S intel-ucode                              # or amd-ucode
pacman -S mesa vulkan-intel intel-media-driver     # or your GPU's packages
EDITOR=vim visudo                                  # uncomment %wheel

# initramfs
# HOOKS need no changes on this path
mkinitcpio -P

# Services
systemctl enable NetworkManager
systemctl enable sshd
```

---

## Next Step

Your system is installed but cannot boot yet — nothing knows how to start it. That is the
bootloader's job, and it is the last step before you reboot.

→ **[GRUB Bootloader for Btrfs](bootloader-btrfs.md)**

---

<div align="center">

[← Btrfs Setup](../02-partitioning/btrfs-setup.md) | [Back to Main Guide](../../README.md) | [Next: GRUB Bootloader for Btrfs →](bootloader-btrfs.md)

</div>
