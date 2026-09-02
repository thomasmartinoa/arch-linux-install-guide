# Path Notes: LUKS + LVM

> Extras for the **encrypted LVM** path — LUKS container holding an LVM volume group.

Partitioning: [LVM with Encryption](../../02-partitioning/lvm-encryption.md)

---

## Your two branch answers

| Branch point | Your answer |
|--------------|-------------|
| Step 6.2 — extra packages | `lvm2 cryptsetup` |
| Step 9 — HOOKS | `... block `**`encrypt lvm2`**` filesystems fsck` |

```bash
pacman -S lvm2 cryptsetup
```

> ### 🔴 `cryptsetup` is the one people forget
>
> The `encrypt` hook is shipped by `mkinitcpio`, so it *looks* available — but the hook's job is
> to copy the `cryptsetup` **binary** into your initramfs. If the package is missing,
> `mkinitcpio -P` stops with `file not found: cryptsetup` and builds an initramfs that cannot
> unlock your disk. The install appears to succeed and the machine never boots again.

---

## Kernel parameters

The initramfs needs to be told *which* device to unlock. Edit `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptlvm"
```

Get the UUID of the **LUKS partition itself** (the one with `TYPE="crypto_LUKS"`, not the
volumes inside it):

```bash
blkid -s UUID -o value /dev/nvme0n1p3
```

| Part | Meaning |
|------|---------|
| `cryptdevice=` | Tells the `encrypt` hook what to unlock |
| `UUID=...` | The LUKS partition. Use the UUID — device paths like `/dev/nvme0n1p3` change when you add a disk |
| `:cryptlvm` | The name it gets after unlocking, i.e. `/dev/mapper/cryptlvm` |

> **`GRUB_CMDLINE_LINUX`, not `GRUB_CMDLINE_LINUX_DEFAULT`.** The `_DEFAULT` variant is only
> applied to normal boot entries. Put `cryptdevice=` there and your recovery entries have no way
> to unlock the disk — exactly when you need them most.

The name after the colon must match what you used with `cryptsetup open`. If you followed the
partitioning guide, that is `cryptlvm`.

---

## Verify before you reboot

```bash
grep -c cryptdevice /boot/grub/grub.cfg     # must be > 0
grep '^HOOKS' /etc/mkinitcpio.conf          # encrypt before lvm2
lsinitcpio /boot/initramfs-linux.img | grep -c 'bin/cryptsetup'   # must be 1
```

That last check is the one that catches the missing-`cryptsetup` failure while you can still fix
it from the chroot.

---

## Back up your LUKS header

The header holds the encrypted master key. If it is corrupted, **every byte on the disk is
permanently unrecoverable** — your passphrase alone cannot rebuild it.

```bash
cryptsetup luksHeaderBackup /dev/nvme0n1p3 --header-backup-file luks-header.img
```

Store it somewhere off the machine. Treat the file as equivalent to the disk itself: anyone
holding it and your passphrase has your data.

Add a second passphrase, so a typo in one does not lock you out permanently:

```bash
cryptsetup luksAddKey /dev/nvme0n1p3
```

---

## Hibernation (optional)

Suspending to disk writes RAM into swap, so the initramfs has to unlock the disk *and* find the
swap volume before the kernel can resume. Add the `resume` hook after `lvm2`:

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 resume filesystems fsck)
```

and point the kernel at the swap volume:

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptlvm resume=/dev/volgroup0/lv_swap"
```

```bash
mkinitcpio -P && grub-mkconfig -o /boot/grub/grub.cfg
```

Your swap volume must be at least as large as your RAM. Without both the hook and the parameter
hibernation fails silently — the machine powers off and boots fresh, losing your session.

---

<div align="center">

[← Base Installation](../base-install-common.md) | [Back to Main Guide](../../../README.md)

</div>
