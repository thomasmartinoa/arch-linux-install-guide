# Path Notes: Btrfs + LUKS

> Extras for the **encrypted Btrfs** path — LUKS container holding Btrfs subvolumes, no LVM.

Partitioning: [Btrfs with Encryption](../../02-partitioning/btrfs-encryption.md)

---

## Your two branch answers

| Branch point | Your answer |
|--------------|-------------|
| Step 6.2 — extra packages | `btrfs-progs cryptsetup` |
| Step 9 — HOOKS | `... block `**`encrypt`**` filesystems fsck` |

```bash
pacman -S btrfs-progs cryptsetup
```

Note there is **no `lvm2`** here. Btrfs subvolumes already give you flexible sizing and
snapshots, so LVM would be a second volume manager doing a job the first one already does. One
fewer layer means one fewer hook and one fewer thing to debug at 2am.

> ### 🔴 Both packages are mandatory
>
> `cryptsetup` — the `encrypt` hook copies its binary into the initramfs. Missing it means
> `mkinitcpio -P` fails and the disk can never be unlocked.
> `btrfs-progs` — your root filesystem is Btrfs and cannot be mounted without it.

---

## Kernel parameters

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptroot"
```

Get the UUID of the LUKS partition (`TYPE="crypto_LUKS"`):

```bash
blkid -s UUID -o value /dev/sda2
```

| Part | Meaning |
|------|---------|
| `cryptdevice=` | Tells the `encrypt` hook what to unlock |
| `UUID=...` | The LUKS partition — a UUID survives disk reordering, `/dev/sda2` does not |
| `:cryptroot` | Name after unlocking, i.e. `/dev/mapper/cryptroot` |

> **`GRUB_CMDLINE_LINUX`, not `GRUB_CMDLINE_LINUX_DEFAULT`** — `_DEFAULT` is skipped for
> recovery entries, leaving them unable to unlock the disk.

You do **not** need to add `rootflags=subvol=@` by hand. `grub-mkconfig` reads your mounted
layout and emits it. Confirm it did:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
grep -o 'cryptdevice=[^ ]*' /boot/grub/grub.cfg | head -1
grep -o 'rootflags=[^ ]*'   /boot/grub/grub.cfg | head -1
```

Both must print something. If `rootflags` is missing, your `@` subvolume was not mounted when
you ran `grub-mkconfig`.

---

## Verify before you reboot

```bash
grep '^HOOKS' /etc/mkinitcpio.conf                                # encrypt present, no lvm2
lsinitcpio /boot/initramfs-linux.img | grep -c 'bin/cryptsetup'   # must be 1
lsblk -f                                                          # crypto_LUKS then btrfs
```

---

## Back up your LUKS header

```bash
cryptsetup luksHeaderBackup /dev/sda2 --header-backup-file luks-header.img
cryptsetup luksAddKey /dev/sda2          # a second passphrase, so one typo isn't fatal
```

Store the header off the machine. If it is corrupted the disk is unrecoverable even with the
correct passphrase — the header is what holds the encrypted master key.

---

## Snapshots

Snapper setup is identical to the unencrypted Btrfs path, including the `/.snapshots` dance —
follow [Path Notes: Btrfs](btrfs.md#setting-up-snapper-after-first-boot). Encryption sits
entirely below Btrfs, so snapshots neither know nor care that the disk is encrypted.

---

## Hibernation (optional)

Hibernating to a Btrfs swapfile needs both the physical offset of the file and the `resume` hook:

```bash
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile   # prints the offset
```

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt resume filesystems fsck)
```

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptroot resume=UUID=<btrfs-fs-uuid> resume_offset=<offset>"
```

`resume=` takes the UUID of the **Btrfs filesystem** (`blkid /dev/mapper/cryptroot`), not the
LUKS partition. Regenerate both afterwards:

```bash
sudo mkinitcpio -P && sudo grub-mkconfig -o /boot/grub/grub.cfg
```

> ⚠️ The offset changes if the swapfile is ever recreated, moved, or defragmented. Re-run
> `map-swapfile` and update the parameter whenever you touch it, or hibernation will resume from
> garbage.

---

<div align="center">

[← Base Installation](../base-install-common.md) | [Back to Main Guide](../../../README.md)

</div>
