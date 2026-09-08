# GRUB Bootloader — Btrfs + LUKS

> The final step for **Btrfs subvolumes inside a LUKS container**.

![GRUB Bootloader](../../images/grub-bootloader.png)

A bootloader is the first thing that runs when you power on. It finds your kernel, loads it, and
hands control over. Without one, your installed system cannot start.

```
Power on → UEFI firmware → GRUB → Linux kernel → initramfs unlocks LUKS → your system
```

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Check Your Mounts](#step-1-check-your-mounts)
- [Step 2: Install GRUB](#step-2-install-grub)
- [Step 3: Tell the Kernel What to Unlock](#step-3-tell-the-kernel-what-to-unlock)
- [Step 4: Generate the Config](#step-4-generate-the-config)
- [Step 5: Verify Before Rebooting](#step-5-verify-before-rebooting)
- [Step 6: Reboot](#step-6-reboot)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

You should have just finished
**[Base Installation — Btrfs + LUKS](base-install-btrfs-luks.md)**, and still be inside the chroot.

```bash
pacman -Q grub efibootmgr cryptsetup
```

If that errors, you are either outside the chroot or missed Step 6. Re-enter with
`arch-chroot /mnt` from the live environment.

---

## Step 1: Check Your Mounts

```bash
findmnt /boot

```

Your ESP is mounted at `/boot`, so it holds the bootloader **and** your kernels.

```bash
ls /boot
```

You should see `vmlinuz-linux`, `vmlinuz-linux-lts` and their `initramfs-*.img` files. If `/boot`
is empty, it is not mounted — mount it before continuing or GRUB will install into thin air.

---

## Step 2: Install GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
```

| Flag | Meaning |
|------|---------|
| `--target=x86_64-efi` | Build for 64-bit UEFI |
| `--efi-directory=/boot` | Where your ESP is mounted — the `.efi` file goes here |
| `--bootloader-id=GRUB` | The name your firmware shows in its boot menu |
| `--recheck` | Rebuild the device map instead of trusting a stale one |

Expect exactly this:

```
Installing for x86_64-efi platform.
Installation finished. No error reported.
```

> Anything else — stop and fix it. A half-installed GRUB gives you a machine that will not boot
> and no obvious explanation why.

---

## Step 3: Tell the Kernel What to Unlock

Your initramfs can unlock LUKS, but it does not know *which* device to unlock. You tell it with a
kernel parameter.

### Find your LUKS UUID

```bash
blkid -t TYPE=crypto_LUKS -o value -s UUID
```

That prints the UUID of the **encrypted partition itself** — not the filesystem inside it.
Getting this wrong is the most common reason a machine hangs before ever asking for a passphrase.

### Add it to GRUB's config

```bash
vim /etc/default/grub
```

Find the `GRUB_CMDLINE_LINUX=` line and set it:

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<your-uuid>:cryptroot"
```

| Part | Meaning |
|------|---------|
| `cryptdevice=` | The parameter the `encrypt` hook reads |
| `UUID=…` | Which device to unlock. Use the UUID — `/dev/vda2` changes the moment you add a drive |
| `:cryptroot` | The name it gets once unlocked, i.e. `/dev/mapper/cryptroot` |

The name after the colon **must match** what you used with `cryptsetup open` during
partitioning. If you followed that guide, it is `cryptroot`.

> ### ⚠️ `GRUB_CMDLINE_LINUX`, not `GRUB_CMDLINE_LINUX_DEFAULT`
>
> The `_DEFAULT` variant is applied only to normal boot entries — recovery entries deliberately
> skip it. Put `cryptdevice=` there and your rescue entries cannot unlock the disk, which is
> exactly when you need them most.

While you are in this file, these are sensible:

```bash
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_DISABLE_OS_PROBER=false
```

---

## Step 4: Generate the Config

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

This scans `/boot`, finds your kernels, and writes the menu.

```
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-linux
Found initrd image: /boot/initramfs-linux.img
Found fallback initrd image: /boot/initramfs-linux-fallback.img
Found linux image: /boot/vmlinuz-linux-lts
Found initrd image: /boot/initramfs-linux-lts.img
...
done
```

> If **no** kernel images are found, `/boot` is not mounted, or Step 2 of the previous guide
> never completed. Do not reboot — fix it now.



---

## Step 5: Verify Before Rebooting

You still have a working shell. This is the cheapest possible moment to catch a mistake — after
you reboot, every fix below needs a live USB.

```bash
# Both kernels are in the menu
grep -c 'vmlinuz-linux' /boot/grub/grub.cfg          # 2 or more

# Microcode is being loaded
grep -cE '(intel|amd)-ucode\.img' /boot/grub/grub.cfg   # 1 or more

# The EFI binary exists where the firmware will look
ls /boot/EFI/GRUB/grubx64.efi
```

```bash
# Your unlock parameter made it into the generated config
grep -c 'cryptdevice=' /boot/grub/grub.cfg           # must be 1 or more

# cryptsetup is actually inside the initramfs   ← the check that matters most
lsinitcpio /boot/initramfs-linux.img | grep -c 'bin/cryptsetup'   # must be 1
```

If that last one prints `0`, your initramfs cannot unlock the disk:

```bash
pacman -S cryptsetup
mkinitcpio -P
```
### Confirm GRUB knows about your subvolume

```bash
grep -o 'rootflags=[^ ]*' /boot/grub/grub.cfg | head -1
```

It must print `rootflags=subvol=@`. `grub-mkconfig` writes this from your mounted layout — you do
not add it by hand. If it is missing, your `@` subvolume was not mounted when you ran the
command; remount it and run `grub-mkconfig` again.

Without it the kernel mounts the top level of the filesystem rather than your root subvolume, and
you land in an emergency shell **after** typing your passphrase.
---

## Step 6: Reboot

```bash
exit                # leave the chroot
umount -R /mnt
swapoff -a
reboot
```

> 💡 **Remove the USB drive** as the machine restarts, or it will boot the installer again.

### What you should see

1. The GRUB menu
2. A passphrase prompt:

```
A password is required to access the cryptroot volume:
Enter passphrase for /dev/vda2:
```

3. Type your **LUKS passphrase** — nothing appears as you type
4. Boot continues to a login prompt, where you use your **user** password

Two different passwords, in that order. Mixing them up is the most common first-boot confusion.

> **Seeing a text login rather than a desktop is correct.** You have not installed a desktop
> environment yet — that comes after first boot.

---

## Troubleshooting

### Getting back in

Every fix starts the same way: boot the live USB and re-enter your system.

```bash
cryptsetup open /dev/vda2 cryptroot
mount -o noatime,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mount -o noatime,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount /dev/vda1 /mnt/boot
arch-chroot /mnt
```

Make your fix, then rebuild whatever you changed before rebooting:

```bash
mkinitcpio -P                            # if you changed HOOKS or packages
grub-mkconfig -o /boot/grub/grub.cfg     # if you changed /etc/default/grub
```

### Common failures

| What you see | Cause | Fix |
|--------------|-------|-----|
| Firmware goes straight to another OS or shows no Arch entry | UEFI boot entry not written | Re-run Step 2, then check `efibootmgr -v` |
| `error: no such device` | fstab or GRUB references a stale UUID | Re-run `grub-mkconfig`; check `blkid` matches fstab |
| Boots to a `grub>` prompt | `grub.cfg` missing or `/boot` was not mounted | Mount `/boot`, re-run Step 4 |
| Kernel panic, `unable to mount root` | initramfs cannot reach root | Rebuild with `mkinitcpio -P` and re-check HOOKS |
| No passphrase prompt at all | `encrypt` missing from HOOKS | Add it before `filesystems`, `mkinitcpio -P` |
| `ERROR: file not found: 'cryptsetup'` | `cryptsetup` not installed | `pacman -S cryptsetup && mkinitcpio -P` |
| `device not found` before any prompt | wrong `cryptdevice=` UUID | Recheck `blkid -t TYPE=crypto_LUKS -o value -s UUID` |
| `No key available with this passphrase` | wrong passphrase, Caps Lock, or a non-US keymap | See below |
| Unlocks, then drops to an emergency shell with an empty root | `rootflags=subvol=@` missing | mount `@` at `/mnt`, re-run `grub-mkconfig -o /boot/grub/grub.cfg` |
| Unlocks, then cannot mount root | `btrfs-progs` was never installed | `pacman -S btrfs-progs && mkinitcpio -P` |

### Passphrase rejected but you are certain it is right

The initramfs uses the keymap from `/etc/vconsole.conf`. If you set a non-US layout and your
passphrase contains symbols, the characters registered may not be the ones you typed — the
passphrase was *created* under the live ISO's US layout.

Test the container directly from the live USB, where you control the layout:

```bash
cryptsetup open --test-passphrase /dev/vda2 && echo "passphrase is correct"
```

If that succeeds, the passphrase is fine and the keymap is the problem. Make sure `keyboard` and
`keymap` both appear **before** `encrypt` in HOOKS, then `mkinitcpio -P`.

### Back up your LUKS header

Do this once you are booted. The header holds the encrypted master key — if it is corrupted the
disk is unrecoverable **even with the correct passphrase**.

```bash
sudo cryptsetup luksHeaderBackup /dev/vda2 --header-backup-file luks-header.img
sudo cryptsetup luksAddKey /dev/vda2     # a second passphrase, so one typo isn't fatal
```

Store the header off the machine, and treat it as sensitive as the disk itself.
## After You Reboot: Snapshots

Snapper setup is identical to the unencrypted Btrfs path — encryption sits entirely below Btrfs,
so snapshots neither know nor care that the disk is encrypted.

→ [Setting up Snapper](../02-partitioning/btrfs-setup.md#snapshots)
---

## Next Step

You have a booting Arch system. Now make it usable — users, networking, mirrors and updates.

→ **[First Boot](../04-post-installation/first-boot.md)**

---

<div align="center">

[← Base Installation — Btrfs + LUKS](base-install-btrfs-luks.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
