# GRUB Bootloader — Btrfs

> The final step for **Btrfs with subvolumes** (no encryption).

![GRUB Bootloader](../../images/grub-bootloader.png)

A bootloader is the first thing that runs when you power on. It finds your kernel, loads it, and
hands control over. Without one, your installed system cannot start.

```
Power on → UEFI firmware → GRUB → Linux kernel → your system
```

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Check Your Mounts](#step-1-check-your-mounts)
- [Step 2: Install GRUB](#step-2-install-grub)
- [Step 3: Generate the Config](#step-3-generate-the-config)
- [Step 4: Verify Before Rebooting](#step-4-verify-before-rebooting)
- [Step 5: Reboot](#step-5-reboot)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

You should have just finished
**[Base Installation — Btrfs](base-install-btrfs.md)**, and still be inside the chroot.

```bash
pacman -Q grub efibootmgr
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

## Step 3: Generate the Config

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

> **Snapshots and your kernels.** With the ESP mounted at `/boot`, your kernels live on the FAT32
> partition, outside any subvolume — so snapshots do not capture them. Rolling back a snapshot
> restores your system files but keeps the current kernel. That is normally what you want; a bad
> *kernel* update is what the LTS entry in your boot menu is for.

---

## Step 4: Verify Before Rebooting

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
### Confirm GRUB knows about your subvolume

```bash
grep -o 'rootflags=[^ ]*' /boot/grub/grub.cfg | head -1
```

It must print `rootflags=subvol=@`.

You do **not** add this by hand — `grub-mkconfig` reads your mounted layout and writes it. If it
is missing, your `@` subvolume was not mounted when you ran the command. Check with
`findmnt /`, remount if needed, and run `grub-mkconfig` again.

Without it the kernel mounts the *top level* of the filesystem instead of your root subvolume,
and the boot ends in an emergency shell.
---

## Step 5: Reboot

```bash
exit                # leave the chroot
umount -R /mnt
swapoff -a
reboot
```

> 💡 **Remove the USB drive** as the machine restarts, or it will boot the installer again.

### What you should see

1. The GRUB menu, with entries for both `linux` and `linux-lts`
2. A few seconds of boot messages
3. A text login prompt: `archpc login:`

Log in with the username and password you created in Step 5.7.

> **Seeing a text login rather than a desktop is correct.** You have not installed a desktop
> environment yet — that comes after first boot.

---

## Troubleshooting

### Getting back in

Every fix starts the same way: boot the live USB and re-enter your system.

```bash
mount -o noatime,compress=zstd,subvol=@ /dev/vda2 /mnt
mount -o noatime,compress=zstd,subvol=@home /dev/vda2 /mnt/home
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
| Boots to a `grub>` prompt | `grub.cfg` missing or `/boot` was not mounted | Mount `/boot`, re-run Step 3 |
| Kernel panic, `unable to mount root` | initramfs cannot reach root | Rebuild with `mkinitcpio -P` and re-check HOOKS |
| Boots to an emergency shell, root looks empty | `rootflags=subvol=@` missing from grub.cfg | mount `@` at `/mnt`, re-run `grub-mkconfig -o /boot/grub/grub.cfg` |
| `can't find command 'btrfs'` or cannot mount root | `btrfs-progs` was never installed | `pacman -S btrfs-progs && mkinitcpio -P` |

---

## Alternative: systemd-boot

GRUB is recommended here because it handles every layout in this guide. If you prefer something
smaller and faster, and you are not using encryption, systemd-boot is a fine choice.

→ [systemd-boot](bootloader-systemd.md)

Use one or the other, not both.
## After You Reboot: Snapshots

Btrfs snapshots are what make this path worth the extra steps, but Snapper is set up **after**
the first boot, not now.

→ [Setting up Snapper](../02-partitioning/btrfs-setup.md#snapshots)

> The one thing that trips everyone up: `snapper create-config` refuses to run while anything is
> mounted at `/.snapshots` — and yours is, from fstab. The linked section covers the exact order
> to work around it.
---

## Next Step

You have a booting Arch system. Now make it usable — users, networking, mirrors and updates.

→ **[First Boot](../04-post-installation/first-boot.md)**

---

<div align="center">

[← Base Installation — Btrfs](base-install-btrfs.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
