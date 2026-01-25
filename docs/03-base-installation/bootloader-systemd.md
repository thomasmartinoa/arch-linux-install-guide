# systemd-boot Installation

> A simple, fast bootloader alternative to GRUB for UEFI systems.

![systemd-boot](../../images/systemd-boot.png)

## Table of Contents

- [Why systemd-boot?](#why-systemd-boot)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Adding Boot Entries](#adding-boot-entries)
- [Dual Boot Setup](#dual-boot-setup)
- [Updating systemd-boot](#updating-systemd-boot)
- [Troubleshooting](#troubleshooting)

---

## Why systemd-boot?

systemd-boot (formerly gummiboot) is a simple UEFI boot manager.

### Comparison with GRUB

| Feature | systemd-boot | GRUB |
|---------|--------------|------|
| **Simplicity** | Very simple | Complex |
| **Speed** | Fast | Slower |
| **Config** | Plain text | Script-based |
| **UEFI Only** | Yes | Supports BIOS too |
| **Theming** | Limited | Extensive |
| **LUKS Support** | No direct | Built-in |
| **Dual Boot** | Auto-detect | Auto-detect |

### When to Use systemd-boot

- UEFI system (not legacy BIOS)
- Simple, single-OS setup
- Want faster boot times
- Prefer plain text configuration
- Don't use LUKS encryption (use GRUB for that)
- Don't need legacy BIOS support

> **Note:** For encrypted root, GRUB is recommended as it can prompt for the LUKS password. systemd-boot requires an unencrypted /boot.

---

## Prerequisites

Ensure you have:

- [ ] UEFI system (not legacy BIOS)
- [ ] EFI System Partition (ESP) mounted at `/boot`
- [ ] Completed base installation
- [ ] Still in chroot environment

**Check UEFI mode:**
```bash
ls /sys/firmware/efi
```
If this directory exists, you're in UEFI mode.

---

## Installation

### Step 1: Install systemd-boot

```bash
bootctl install
```

**What this does:**
- Installs systemd-boot to ESP
- Creates `/boot/EFI/systemd/` directory
- Adds UEFI boot entry

**Expected output:**
```
Created "/boot/EFI/systemd".
Created "/boot/EFI/BOOT".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/EFI/systemd/systemd-bootx64.efi".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi" to "/boot/EFI/BOOT/BOOTX64.EFI".
Created EFI boot entry "Linux Boot Manager".
```

### Step 2: Verify Installation

```bash
bootctl status
```

---

## Configuration

### Loader Configuration

```bash
nvim /boot/loader/loader.conf
```

**Recommended configuration:**
```ini
default  arch.conf
timeout  3
console-mode max
editor   no
```

**Options explained:**

| Option | Value | Meaning |
|--------|-------|---------|
| `default` | `arch.conf` | Default boot entry |
| `timeout` | `3` | Menu timeout in seconds |
| `console-mode` | `max` | Use highest resolution |
| `editor` | `no` | Disable boot entry editing (security) |

> 💡 Set `timeout 0` to skip menu entirely (boot default immediately).

---

## Adding Boot Entries

### Step 3: Create Arch Linux Entry

```bash
nvim /boot/loader/entries/arch.conf
```

**For Standard Installation:**
```ini
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=xxxx-xxxx rw
```

> 📝 Replace `intel-ucode.img` with `amd-ucode.img` for AMD CPUs.

### For Btrfs with Subvolumes

If you used the Btrfs partitioning guide with subvolumes, add `rootflags`:

```ini
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=xxxx-xxxx rw rootflags=subvol=@
```

> ⚠️ **Btrfs Users:** The `rootflags=subvol=@` is REQUIRED if you created subvolumes!

### Get Your PARTUUID

```bash
blkid -s PARTUUID -o value /dev/sdX2
```

Or use the full command:
```bash
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) rw" >> /boot/loader/entries/arch.conf
```

### Using UUID Instead

```ini
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=xxxx-xxxx-xxxx-xxxx rw
```

Get UUID:
```bash
blkid -s UUID -o value /dev/sdX2
```

### Step 4: Create Fallback Entry

```bash
nvim /boot/loader/entries/arch-fallback.conf
```

```ini
title   Arch Linux (fallback)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options root=PARTUUID=xxxx-xxxx rw
```

### Step 5: LTS Kernel Entry (Optional)

If you installed `linux-lts`:

```bash
nvim /boot/loader/entries/arch-lts.conf
```

```ini
title   Arch Linux (LTS)
linux   /vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /initramfs-linux-lts.img
options root=PARTUUID=xxxx-xxxx rw
```

---

## LVM Configuration

For LVM installations (without encryption):

```bash
nvim /boot/loader/entries/arch.conf
```

```ini
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=/dev/mapper/volgroup0-lv_root rw
```

---

## Dual Boot Setup

### Windows Dual Boot

systemd-boot automatically detects Windows if:
- Windows EFI files are on the same ESP
- Or accessible from the ESP

**Check if Windows is detected:**
```bash
bootctl list
```

**Manual Windows Entry (if not auto-detected):**
```bash
nvim /boot/loader/entries/windows.conf
```

```ini
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
```

### Other Linux Distributions

```bash
nvim /boot/loader/entries/other-linux.conf
```

```ini
title   Other Linux
linux   /vmlinuz-other
initrd  /initramfs-other.img
options root=PARTUUID=xxxx-xxxx rw
```

---

## Updating systemd-boot

### Automatic Updates with Pacman Hook

Create a hook to update systemd-boot when systemd is upgraded:

```bash
sudo mkdir -p /etc/pacman.d/hooks
sudo nvim /etc/pacman.d/hooks/95-systemd-boot.hook
```

```ini
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
```

### Manual Update

```bash
sudo bootctl update
```

### Update After Kernel Install

Unlike GRUB, you don't need to run any command after kernel updates. The kernel files are installed directly to `/boot/`.

---

## Additional Options

### Kernel Parameters

Add to the `options` line in your entry:

```ini
options root=PARTUUID=xxxx rw quiet splash
```

Common parameters:

| Parameter | Purpose |
|-----------|---------|
| `quiet` | Suppress boot messages |
| `splash` | Show splash screen (if configured) |
| `loglevel=3` | Only show errors |
| `nowatchdog` | Disable watchdog (faster shutdown) |
| `nvidia-drm.modeset=1` | NVIDIA DRM for Wayland |

### Console Font

```ini
options root=PARTUUID=xxxx rw vconsole.font=ter-v16n
```

### Different Root Filesystem

For Btrfs:
```ini
options root=PARTUUID=xxxx rw rootflags=subvol=@
```

---

## Verification

### Check Boot Entries

```bash
bootctl list
```

**Expected output:**
```
Boot Loader Entries:
        title: Arch Linux
           id: arch.conf
       source: /boot/loader/entries/arch.conf
        linux: /vmlinuz-linux
       initrd: /intel-ucode.img
               /initramfs-linux.img
      options: root=PARTUUID=xxxx-xxxx rw
```

### Check Status

```bash
bootctl status
```

### Test Boot

```bash
exit
umount -R /mnt
reboot
```

---

## Troubleshooting

### systemd-boot Not Showing

```bash
# Check EFI entry
efibootmgr -v

# Re-add entry
bootctl install
```

### Wrong Entry Boots

Check `/boot/loader/loader.conf`:
```bash
default arch.conf  # Make sure this matches your entry filename
```

### "No Bootable Device"

1. Enter BIOS
2. Look for "Linux Boot Manager" in boot options
3. Set it as first boot device

### Boot Entry Not Found

Verify files exist:
```bash
ls /boot/vmlinuz-linux
ls /boot/initramfs-linux.img
ls /boot/loader/entries/
```

### Mount ESP

If you need to fix from live USB:
```bash
mount /dev/sda1 /mnt    # Mount ESP
bootctl --esp-path=/mnt install
```

---

## Quick Reference

```bash
# Install
bootctl install

# Configure loader
nvim /boot/loader/loader.conf

# Create boot entry
nvim /boot/loader/entries/arch.conf

# Verify
bootctl status
bootctl list

# Update
bootctl update

# Reinstall
bootctl install --force
```

---

## Migration from GRUB

If you're switching from GRUB:

```bash
# Install systemd-boot
bootctl install

# Create entries (see above)
nvim /boot/loader/loader.conf
nvim /boot/loader/entries/arch.conf

# Remove GRUB (optional)
sudo pacman -Rns grub

# Clean up GRUB files
sudo rm -rf /boot/grub

# Reboot and test
reboot
```

---

## Next Steps

After bootloader setup:

→ [First Boot](../04-post-installation/first-boot.md)

---

<div align="center">

[← Base Installation](base-install-standard.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
