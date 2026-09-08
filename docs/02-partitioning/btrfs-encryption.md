# Btrfs with Full Disk Encryption

> LUKS2 encryption wrapped around Btrfs subvolumes. Snapshots *and* encryption, no LVM.

## Table of Contents

- [Why This Layout](#why-this-layout)
- [Partition Layout](#partition-layout)
- [Step 1: Create Partitions](#step-1-create-partitions)
- [Step 2: Set Up LUKS](#step-2-set-up-luks)
- [Step 3: Create the Btrfs Filesystem](#step-3-create-the-btrfs-filesystem)
- [Step 4: Create Subvolumes](#step-4-create-subvolumes)
- [Step 5: Mount Everything](#step-5-mount-everything)
- [Step 6: Swap File](#step-6-swap-file)
- [Verification](#verification)
- [Recovery](#recovery)

---

## Why This Layout

The older encrypted path in this guide stacks LUKS → LVM → ext4. That works, but LVM is there to
do two jobs: carve flexible volumes, and take snapshots. **Btrfs subvolumes already do both** —
better, in the snapshot case. Stacking them means two volume managers, two sets of tools, and an
extra initramfs hook, for no capability you did not already have.

So this path drops LVM entirely:

| | LUKS + LVM + ext4 | LUKS + Btrfs (this page) |
|---|---|---|
| Partitions | 3 (ESP, /boot, LUKS) | **2** (ESP, LUKS) |
| Layers to unwind | LUKS → LVM → ext4 | LUKS → Btrfs |
| initramfs hooks | `encrypt lvm2` | `encrypt` |
| Resize a volume | `lvresize` + `resize2fs` | nothing to resize — subvolumes share the pool |
| Snapshots | LVM snapshots (clunky) | native, instant, with rollback |
| Compression | none | zstd, typically 30-50% on system files |

### What is and isn't encrypted

| Partition | Encrypted? | Why |
|-----------|------------|-----|
| ESP (`/boot`) | **No** | UEFI firmware must read the bootloader, and it cannot decrypt |
| Everything else | **Yes** | Root, home, logs, swap — all inside the LUKS container |

Your kernel and initramfs sit unencrypted on the ESP. That is the standard trade-off: it
protects your *data* against a stolen laptop, which is the threat that matters for almost
everyone. It does not protect against someone with physical access tampering with the kernel
itself — that needs Secure Boot, which is out of scope here.

---

## Partition Layout

```
┌─────────┬──────────────────────────────────────────────┐
│   ESP   │            LUKS2 container                   │
│   1GB   │  ┌────────────────────────────────────────┐  │
│  FAT32  │  │   Btrfs  (label: arch)                 │  │
│  /boot  │  │                                        │  │
│         │  │    @          → /                      │  │
│  (clear)│  │    @home      → /home                  │  │
│         │  │    @snapshots → /.snapshots            │  │
│         │  │    @var_log   → /var/log               │  │
│         │  │    @var_cache → /var/cache             │  │
│         │  │    @swap      → /swap   (no compress)  │  │
│         │  └────────────────────────────────────────┘  │
└─────────┴──────────────────────────────────────────────┘
     ↑                          ↑
 unencrypted            ENCRYPTED — passphrase at every boot
```

| # | Partition | Size | Type code | Filesystem |
|---|-----------|------|-----------|------------|
| 1 | ESP | 1GB | `EF00` | FAT32 |
| 2 | LUKS container | Remaining | `8309` | LUKS2 → Btrfs |

> **Why a 1GB ESP?** It holds the bootloader *and* both kernels with their normal and fallback
> initramfs images. The 512MB you see in older guides overflows once you have two kernels, and
> overflows badly with NVIDIA modules in the fallback image.

> **On the separate `/boot`:** the LUKS+LVM path uses a third partition for `/boot`. You do not
> need one. With no `/boot`, the ESP mounted at `/boot` holds the kernels directly — one fewer
> partition, one fewer thing to explain, identical security.

---

## Step 1: Create Partitions

> ⚠️ This erases the disk. `lsblk` first and be certain which device is yours. This guide uses
> `/dev/sda`; NVMe drives are `/dev/nvme0n1` with partitions `p1`, `p2`.

```bash
lsblk
gdisk /dev/sda
```

In `gdisk`:

```
o          # new empty GPT (destroys everything)
Y

n          # partition 1 — ESP
1
[Enter]    # default first sector
+1G
ef00

n          # partition 2 — LUKS container
2
[Enter]
[Enter]    # all remaining space
8309

p          # review before committing
w          # write
Y
```

| Code | Type |
|------|------|
| `ef00` | EFI System |
| `8309` | Linux LUKS |

> The `8309` type code is cosmetic — LUKS works regardless — but it makes `lsblk -f` and
> partition managers label the partition honestly, which helps a lot during recovery.

### Format the ESP

```bash
mkfs.fat -F32 /dev/sda1
```

---

## Step 2: Set Up LUKS

### Create the container

```bash
cryptsetup luksFormat --type luks2 /dev/sda2
```

You will be asked to type `YES` in capitals, then set a passphrase twice.

| Part | Meaning |
|------|---------|
| `luksFormat` | Initialise the encrypted container (destroys existing data) |
| `--type luks2` | LUKS2 — the current default, with Argon2id key derivation |

> ### 🔴 There is no password reset
>
> The passphrase unlocks the master key. Forget it and the data is gone — no recovery, no
> support channel, no exception. Use a long passphrase you will genuinely remember; four or five
> unrelated words beats a short mangled one, both for memorability and for actual strength.

> **Why LUKS2 is safe here:** GRUB has only partial LUKS2 support, which trips people up — but
> that only matters when GRUB itself must unlock the disk, i.e. when `/boot` is encrypted. Here
> `/boot` is the unencrypted ESP, so GRUB never touches LUKS. The kernel's `encrypt` hook does
> the unlocking, and it handles LUKS2 fully.

### Open it

```bash
cryptsetup open /dev/sda2 cryptroot
```

Enter your passphrase. The decrypted device now exists at `/dev/mapper/cryptroot`, and
everything from here on targets *that*, not `/dev/sda2`.

> The name `cryptroot` must match the `cryptdevice=...:cryptroot` kernel parameter you will set
> later. If you change it here, change it there too.

---

## Step 3: Create the Btrfs Filesystem

```bash
mkfs.btrfs -L arch /dev/mapper/cryptroot
```

Note the target: `/dev/mapper/cryptroot`, the *unlocked* device. Running `mkfs.btrfs` on
`/dev/sda2` would destroy the LUKS header you just created.

---

## Step 4: Create Subvolumes

Mount the top level of the filesystem so you can create subvolumes in it:

```bash
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@swap

btrfs subvolume list /mnt
umount /mnt
```

### What each one is for

| Subvolume | Mount point | Why it is separate |
|-----------|-------------|--------------------|
| `@` | `/` | The system. This is what you snapshot and roll back |
| `@home` | `/home` | Your files. Kept *out* of system snapshots — rolling back the OS must not revert your documents |
| `@snapshots` | `/.snapshots` | Where Snapper stores snapshots. Must not be inside `@`, or snapshots would contain themselves |
| `@var_log` | `/var/log` | Logs. Excluded so a rollback keeps the log of what went wrong |
| `@var_cache` | `/var/cache` | Package cache — large, churns constantly, worthless in a snapshot |
| `@swap` | `/swap` | Swap file. Cannot be compressed or copy-on-write, so it needs its own mount options |

The `@` naming convention is not required by Btrfs, but Snapper, `grub-btrfs` and most tooling
assume it. Follow it.

---

## Step 5: Mount Everything

```bash
# Root subvolume first
mount -o noatime,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt

# Mount points
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}

# The rest
mount -o noatime,compress=zstd,subvol=@home      /dev/mapper/cryptroot /mnt/home
mount -o noatime,compress=zstd,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o noatime,compress=zstd,subvol=@var_log   /dev/mapper/cryptroot /mnt/var/log
mount -o noatime,compress=zstd,subvol=@var_cache /dev/mapper/cryptroot /mnt/var/cache
mount -o noatime,subvol=@swap                    /dev/mapper/cryptroot /mnt/swap

# ESP last
mount /dev/sda1 /mnt/boot
```

### Mount options

| Option | What it does |
|--------|--------------|
| `noatime` | Stop updating access timestamps on every read. Meaningful write reduction, especially on SSDs |
| `compress=zstd` | Transparent zstd compression. Usually 30-50% on system files, and often *faster* than no compression because there is less to write |
| `subvol=@` | Which subvolume this mount exposes |

> **`@swap` has no `compress`.** A swap file must not be compressed or copy-on-write. That is
> the entire reason it gets its own subvolume.

> **What about `space_cache=v2`?** Older guides pass it explicitly. You no longer need to —
> `mkfs.btrfs` enables the free-space-tree by default. Harmless if you include it, just noise.

---

## Step 6: Swap File

```bash
btrfs filesystem mkswapfile --size 8g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile
```

| Part | Meaning |
|------|---------|
| `mkswapfile` | Creates the file, sets NOCOW, preallocates it, and runs `mkswap` — all in one step |
| `--size 8g` | Adjust to your RAM. For hibernation, at least as much as you have RAM |
| `--uuid clear` | Zeroed UUID — avoids clashing with a swap UUID from a previous install |

> **Why not `dd` and `chattr +C`?** That is the old recipe, and it is easy to get subtly wrong —
> `chattr +C` only takes effect on files created *after* it is set on an empty directory, so
> doing it in the wrong order silently gives you a copy-on-write swap file that corrupts under
> memory pressure. `mkswapfile` (btrfs-progs 6.1+) does the whole thing correctly.

Size it against the [swap guidelines](partition-overview.md#swap-partitionfile). For
suspend-to-disk see [Hibernation](#hibernation-optional) below — it needs two extra kernel
parameters.

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

## Verification

Before moving on, all of this must be true:

```bash
lsblk -f
```

```
NAME          FSTYPE      LABEL MOUNTPOINTS
sda
├─sda1        vfat              /mnt/boot
└─sda2        crypto_LUKS                      ← encrypted container
  └─cryptroot btrfs       arch  /mnt/swap
                                /mnt/var/cache
                                /mnt/var/log
                                /mnt/.snapshots
                                /mnt/home
                                /mnt
```

```bash
findmnt -R /mnt | head -10     # every subvolume mounted where you expect
swapon --show                  # swapfile active
btrfs subvolume list /mnt      # all six subvolumes present
```

Checklist:

- [ ] `sda2` shows `crypto_LUKS` — the container exists
- [ ] `cryptroot` shows `btrfs` — it is unlocked and formatted
- [ ] Six subvolumes listed
- [ ] `/mnt/boot` is `vfat`, not btrfs
- [ ] `swapon --show` is not empty

---

## Next Steps

Your disk is ready. Next you install Arch onto it.

→ **[Base Installation — Btrfs + LUKS](../03-base-installation/base-install-btrfs-luks.md)**

That guide is written specifically for the **Btrfs + LUKS** layout you just created — follow it
straight through, there is nothing to pick or choose.

---

## Recovery

If the system will not boot, get back in from the live USB:

```bash
cryptsetup open /dev/sda2 cryptroot
mount -o noatime,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mount -o noatime,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount /dev/sda1 /mnt/boot
arch-chroot /mnt
```

Fix what is wrong, then `mkinitcpio -P` and/or `grub-mkconfig -o /boot/grub/grub.cfg` before
rebooting.

### Common failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| No passphrase prompt at all | `encrypt` missing from HOOKS | Add it before `filesystems`, `mkinitcpio -P` |
| Prompt appears, then drops to a shell | Root cannot be mounted — usually `btrfs-progs` missing | `pacman -S btrfs-progs`, `mkinitcpio -P` |
| `device not found` before the prompt | `cryptdevice=` UUID wrong | Recheck `blkid -s UUID -o value /dev/sda2` |
| Boots to emergency shell, root is empty | `rootflags=subvol=@` missing | Mount `@` at `/mnt`, re-run `grub-mkconfig` |
| `ERROR: file not found: cryptsetup` when running `mkinitcpio` | `cryptsetup` not installed | `pacman -S cryptsetup`, `mkinitcpio -P` |

Unlock manually from the initramfs emergency shell to confirm the container itself is fine:

```bash
cryptsetup open /dev/sda2 cryptroot
exit
```

If that unlocks, your passphrase and header are healthy and the problem is in the initramfs.

---

<div align="center">

[← Partition Overview](partition-overview.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation — Btrfs + LUKS →](../03-base-installation/base-install-btrfs-luks.md)

</div>
