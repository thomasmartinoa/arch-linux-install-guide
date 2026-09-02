# GRUB for Encrypted Systems

> For **LUKS + LVM** and **Btrfs + LUKS**. GRUB is the recommended bootloader for encrypted root.

![GRUB Bootloader](../../images/grub-bootloader.png)

## Table of Contents

- [Prerequisites](#prerequisites)
- [How Encrypted Boot Works](#how-encrypted-boot-works)
- [Step 1: Confirm Your Layout](#step-1-confirm-your-layout)
- [Step 2: Install GRUB](#step-2-install-grub)
- [Step 3: Tell the Kernel What to Unlock](#step-3-tell-the-kernel-what-to-unlock)
- [Step 4: Generate the Config](#step-4-generate-the-config)
- [Step 5: Verify Before Rebooting](#step-5-verify-before-rebooting)
- [Step 6: Reboot](#step-6-reboot)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- [ ] [Base System Installation](base-install-common.md) complete
- [ ] `cryptsetup` installed, plus `lvm2` or `btrfs-progs` for your path
- [ ] HOOKS contains `encrypt` (and `lvm2` if you use LVM)
- [ ] Still in the chroot

```bash
pacman -Q grub efibootmgr cryptsetup
grep '^HOOKS' /etc/mkinitcpio.conf
```

If `encrypt` is missing from HOOKS, go back to
[Step 9 of the base installation](base-install-common.md#step-9-configure-mkinitcpio) — GRUB
cannot compensate for an initramfs that has no way to unlock the disk.

---

## How Encrypted Boot Works

```
Power on
   │
   ▼
UEFI firmware  ──▶ reads the ESP (unencrypted — firmware cannot decrypt)
   │
   ▼
GRUB           ──▶ loads kernel + initramfs from /boot (also unencrypted)
   │
   ▼
initramfs      ──▶ "Enter passphrase for /dev/…"     ← the encrypt hook
   │                        │
   │                        ▼
   │                 unlocks LUKS ──▶ /dev/mapper/cryptroot (or cryptlvm)
   │                        │
   │                        ▼
   │                 lvm2 hook activates volumes    ← LUKS + LVM only
   ▼
root mounted   ──▶ normal boot continues
```

The key point: **GRUB never touches encryption here.** It only reads the unencrypted ESP and
`/boot`. All the unlocking happens later, inside the initramfs. That is why LUKS2 is safe on
this path even though GRUB's own LUKS2 support is incomplete.

---

## Step 1: Confirm Your Layout

The two encrypted paths mount things differently:

| | LUKS + LVM | Btrfs + LUKS |
|---|---|---|
| ESP | `/efi` | `/boot` |
| `/boot` | separate ext4 partition | *(the ESP itself)* |
| Mapper name | `cryptlvm` | `cryptroot` |
| `--efi-directory` | `/efi` | `/boot` |

```bash
findmnt /boot
findmnt /efi     # LUKS + LVM only
lsblk -f
```

> If your ESP is not mounted, mount it now — `grub-install` writes into it and will fail
> otherwise.

---

## Step 2: Install GRUB

**LUKS + LVM** (separate `/boot`, ESP at `/efi`):

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot \
             --bootloader-id=GRUB --recheck
```

**Btrfs + LUKS** (ESP mounted at `/boot`):

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
```

| Flag | Meaning |
|------|---------|
| `--target=x86_64-efi` | 64-bit UEFI build |
| `--efi-directory` | Where the ESP is mounted — this is where `grubx64.efi` goes |
| `--boot-directory` | Where GRUB's modules and `grub.cfg` go. Defaults to `/boot`, so only the split layout needs it spelled out |
| `--bootloader-id=GRUB` | The name that appears in your firmware's boot menu |
| `--recheck` | Rebuild the device map rather than trusting a stale one |

Expect `Installation finished. No error reported.` Anything else — stop and fix it; a partial
GRUB install produces a machine that does not boot and gives no clue why.

---

## Step 3: Tell the Kernel What to Unlock

The initramfs needs to know which device holds your encrypted root.

### Get the LUKS UUID

```bash
blkid -t TYPE=crypto_LUKS -o value -s UUID
```

That prints the UUID of the LUKS **partition** — the container itself, not the filesystem
inside it. Getting this wrong is the most common cause of a boot that hangs before the
passphrase prompt.

### Edit `/etc/default/grub`

```bash
vim /etc/default/grub
```

**LUKS + LVM:**

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptlvm"
```

**Btrfs + LUKS:**

```bash
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptroot"
```

| Part | Meaning |
|------|---------|
| `cryptdevice=` | The parameter the `encrypt` hook reads |
| `UUID=…` | Which device to unlock. Use the UUID — `/dev/sda2` changes the moment you add a disk |
| `:cryptlvm` / `:cryptroot` | The name it gets once unlocked. **Must match** the name you used with `cryptsetup open` |

> ### ⚠️ `GRUB_CMDLINE_LINUX`, not `GRUB_CMDLINE_LINUX_DEFAULT`
>
> `_DEFAULT` is applied only to normal boot entries. Recovery entries deliberately skip it — so
> putting `cryptdevice=` there gives you rescue entries that cannot unlock the disk, which is
> precisely when you need them. Use `GRUB_CMDLINE_LINUX`, which applies to every entry.

The rest of the file can stay as it is. A reasonable set:

```bash
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptroot"
GRUB_DISABLE_SUBMENU=y
GRUB_DISABLE_OS_PROBER=false
```

---

## Step 4: Generate the Config

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

Expected:

```
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-linux
Found initrd image: /boot/initramfs-linux.img
Found fallback initrd image: /boot/initramfs-linux-fallback.img
Found linux image: /boot/vmlinuz-linux-lts
...
done
```

If no kernel images are found, your `/boot` is not mounted or the kernel was never installed.

---

## Step 5: Verify Before Rebooting

You are still in the chroot with a working shell. This is the cheapest moment to catch a
mistake — after reboot, fixing any of these means booting the live USB again.

```bash
# 1. cryptdevice made it into the generated config
grep -c cryptdevice /boot/grub/grub.cfg              # must be > 0

# 2. the encrypt hook is present
grep '^HOOKS' /etc/mkinitcpio.conf                   # must contain: encrypt

# 3. cryptsetup actually landed in the initramfs   ← catches the classic failure
lsinitcpio /boot/initramfs-linux.img | grep -c 'bin/cryptsetup'    # must be 1

# 4. Btrfs only — the subvolume flag was emitted
grep -o 'rootflags=[^ ]*' /boot/grub/grub.cfg | head -1

# 5. the EFI binary exists
ls /efi/EFI/GRUB/grubx64.efi 2>/dev/null || ls /boot/EFI/GRUB/grubx64.efi
```

Check 3 is the important one. If it returns `0`, `cryptsetup` was not installed when
`mkinitcpio` ran, and your initramfs has no way to unlock the disk:

```bash
pacman -S cryptsetup
mkinitcpio -P
```

---

## Step 6: Reboot

```bash
exit
umount -R /mnt
swapoff -a
reboot
```

Remove the USB drive as the machine restarts.

At boot you will see the GRUB menu, then:

```
A password is required to access the cryptroot volume:
Enter passphrase for /dev/sda2:
```

Type your LUKS passphrase — nothing appears as you type. After it unlocks, boot continues to
the normal login prompt, where you use your **user** password, not the LUKS one.

---

## Troubleshooting

### Getting back in

Every fix below starts the same way — boot the live USB, unlock, mount, chroot:

**LUKS + LVM:**
```bash
cryptsetup open /dev/nvme0n1p3 cryptlvm
vgchange -ay
mount /dev/volgroup0/lv_root /mnt
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/efi
mount /dev/volgroup0/lv_home /mnt/home
arch-chroot /mnt
```

**Btrfs + LUKS:**
```bash
cryptsetup open /dev/sda2 cryptroot
mount -o noatime,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mount -o noatime,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount /dev/sda1 /mnt/boot
arch-chroot /mnt
```

### Symptom table

| What you see | Cause | Fix |
|--------------|-------|-----|
| No passphrase prompt at all | `encrypt` missing from HOOKS | Add it before `filesystems`, then `mkinitcpio -P` |
| `ERROR: file not found: cryptsetup` during `mkinitcpio` | `cryptsetup` not installed | `pacman -S cryptsetup && mkinitcpio -P` |
| `device … not found` before the prompt | Wrong `cryptdevice=` UUID | Recheck with `blkid -t TYPE=crypto_LUKS -o value -s UUID` |
| Prompt appears, unlocks, then hangs | `lvm2` hook missing or before `encrypt` | Order must be `… block encrypt lvm2 filesystems …` |
| `Volume group not found` after unlocking | Same as above | Same as above |
| Unlocks, then root is empty (Btrfs) | `rootflags=subvol=@` missing | Mount `@` at `/mnt`, re-run `grub-mkconfig` |
| Cannot mount root (Btrfs) | `btrfs-progs` not installed | `pacman -S btrfs-progs && mkinitcpio -P` |
| `No key available with this passphrase` | Wrong passphrase, Caps Lock, or a non-US keymap | Try again; see below |
| GRUB missing from the firmware menu | EFI entry not written | Re-run `grub-install` (Step 2), then check `efibootmgr -v` |

### Passphrase rejected but you are sure it is right

The initramfs uses the keymap from `/etc/vconsole.conf`. If you set a non-US layout and your
passphrase contains symbols, the characters you type may not be the ones registered — the
passphrase was *created* under the US layout of the live ISO.

Test the container directly from the live USB, where you control the layout:

```bash
cryptsetup open --test-passphrase /dev/sda2 && echo "passphrase is correct"
```

If that succeeds, the passphrase is fine and the problem is the keymap. Make sure `keyboard`
and `keymap` are both in HOOKS **before** `encrypt`, and regenerate.

### Emergency shell inside the initramfs

```bash
cryptsetup open /dev/sda2 cryptroot
vgchange -ay          # LUKS + LVM only
exit                  # boot continues
```

If that works, the container and passphrase are healthy and the fault is in your initramfs
configuration, not the encryption.

---

## Security Notes

Your ESP and `/boot` are **not encrypted**. They hold the bootloader, kernels and initramfs.
Someone with repeated physical access could modify them — an "evil maid" attack.

This layout protects against the realistic threat: a lost or stolen machine, where the disk is
read offline. It does not protect against a tampered bootloader. If you need that, look into
UEFI Secure Boot with your own keys, and a TPM-sealed unlock.

Two things worth doing now:

```bash
cryptsetup luksHeaderBackup /dev/sda2 --header-backup-file luks-header.img
cryptsetup luksAddKey /dev/sda2
```

The header holds the encrypted master key — if it is corrupted, the data is unrecoverable even
with the correct passphrase. The second key means one forgotten passphrase is not fatal. Store
the header backup off the machine, and treat it as sensitive as the disk itself.

---

## Next Steps

→ [First Boot](../04-post-installation/first-boot.md)

---

<div align="center">

[← Base Installation](base-install-common.md) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
