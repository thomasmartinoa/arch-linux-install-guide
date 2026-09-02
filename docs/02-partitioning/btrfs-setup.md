# Btrfs Partitioning Guide

> Modern copy-on-write filesystem with snapshots, compression, and easy rollbacks.

## Table of Contents

- [Why Btrfs?](#why-btrfs)
- [Partition Layout](#partition-layout)
- [Step-by-Step Setup](#step-by-step-setup)
- [Subvolume Layout](#subvolume-layout)
- [Mount Options](#mount-options)
- [Snapshot Setup](#snapshot-setup)
- [Verification](#verification)

---

## Why Btrfs?

Btrfs (B-tree File System) is a modern copy-on-write filesystem with powerful features.

> **Required Package:** You MUST install `btrfs-progs` during base installation for Btrfs to work!

### Features

| Feature | Description |
|---------|-------------|
| **Snapshots** | Instant backups, easy rollbacks |
| **Compression** | Transparent compression (zstd, lzo) |
| **Subvolumes** | Flexible partition-like organization |
| **Self-Healing** | Checksums detect and fix corruption |
| **Copy-on-Write** | Efficient file copies and writes |
| **RAID Support** | Built-in RAID 0, 1, 10 |

### When to Use Btrfs

- You want easy system rollbacks
- You want transparent compression
- You need flexible storage management
- You want built-in data integrity
- Not recommended for databases (disable CoW)
- RAID 5/6 still experimental

### Btrfs vs ext4

| Feature | Btrfs | ext4 |
|---------|-------|------|
| Snapshots | Native | Need LVM |
| Compression | Native | No |
| Checksums | Yes | No |
| Resize Online | Grow & Shrink | Grow only |
| Maturity | Good | Excellent |
| Performance | Good | Excellent |

---

## Partition Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                            DISK                                 │
├─────────────┬───────────────────────────────────────────────────┤
│    ESP      │                    Btrfs                          │
│    1GB      │  ┌─────────────────────────────────────────────┐  │
│             │  │             Subvolumes                      │  │
│   FAT32     │  │  @          → /     (root)                  │  │
│             │  │  @home      → /home (user data)             │  │
│             │  │  @snapshots → /.snapshots                   │  │
│             │  │  @var_log   → /var/log                      │  │
│             │  │  @swap      → /swap (if using swapfile)     │  │
│             │  └─────────────────────────────────────────────┘  │
└─────────────┴───────────────────────────────────────────────────┘
```

| Partition | Size | Filesystem | Purpose |
|-----------|------|------------|---------|
| ESP | 1GB | FAT32 | Bootloader + kernels |
| Root | Remaining | Btrfs | Everything else |

> **No separate swap partition needed!** We'll use a swap file on Btrfs.

---

## Step-by-Step Setup

### Step 1: Create Partitions

```bash
cfdisk /dev/sda
```

Create two partitions:

| # | Size | Type |
|---|------|------|
| 1 | 1G | EFI System |
| 2 | Remaining | Linux filesystem |

Write and quit.

### Step 2: Format the ESP

```bash
mkfs.fat -F32 /dev/sda1
```

### Step 3: Create Btrfs Filesystem

```bash
mkfs.btrfs -L "Arch" /dev/sda2
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `mkfs.btrfs` | Create Btrfs filesystem |
| `-L "Arch"` | Volume label |
| `/dev/sda2` | Target partition |

---

## Subvolume Layout

### Step 4: Mount Btrfs Partition

```bash
mount /dev/sda2 /mnt
```

### Step 5: Create Subvolumes

```bash
# Root subvolume
btrfs subvolume create /mnt/@

# Home subvolume
btrfs subvolume create /mnt/@home

# Snapshots subvolume
btrfs subvolume create /mnt/@snapshots

# Log subvolume (exclude from snapshots)
btrfs subvolume create /mnt/@var_log

# Cache subvolume (exclude from snapshots)
btrfs subvolume create /mnt/@var_cache

# Swap subvolume (for swap file)
btrfs subvolume create /mnt/@swap
```

### Step 6: Verify Subvolumes

```bash
btrfs subvolume list /mnt
```

**Expected output:**
```
ID 256 gen 8 top level 5 path @
ID 257 gen 8 top level 5 path @home
ID 258 gen 8 top level 5 path @snapshots
ID 259 gen 8 top level 5 path @var_log
ID 260 gen 8 top level 5 path @var_cache
ID 261 gen 8 top level 5 path @swap
```

### Step 7: Unmount

```bash
umount /mnt
```

---

## Mount Options

### Step 8: Mount with Options

```bash
# Mount root subvolume
mount -o noatime,compress=zstd,subvol=@ /dev/sda2 /mnt

# Create mount points
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}

# Mount other subvolumes
mount -o noatime,compress=zstd,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd,subvol=@snapshots /dev/sda2 /mnt/.snapshots
mount -o noatime,compress=zstd,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,subvol=@swap /dev/sda2 /mnt/swap

# Mount EFI
mount /dev/sda1 /mnt/boot
```

### Mount Options Explained

| Option | Purpose |
|--------|---------|
| `noatime` | Don't update access time (performance) |
| `compress=zstd` | Use zstd compression (best ratio/speed) |
| `subvol=@` | Mount specific subvolume |

### Alternative Compression Options

| Option | Speed | Ratio | Use Case |
|--------|-------|-------|----------|
| `compress=zstd` | Fast | Best | Default, recommended |
| `compress=zstd:3` | Medium | Better | More compression |
| `compress=lzo` | Fastest | Good | Maximum speed |
| `compress=zlib` | Slow | Good | Legacy |

---

## Swap File Setup

### Step 9: Create Swap File

```bash
btrfs filesystem mkswapfile --size 8g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile
```

| Part | Meaning |
|------|---------|
| `mkswapfile` | Creates the file, sets NOCOW, preallocates it and runs `mkswap` in one step |
| `--size 8g` | Adjust to your RAM. For hibernation, at least as much as you have RAM |
| `--uuid clear` | Zeroed UUID — avoids clashing with swap from a previous install |

> **Why not `dd` and `chattr +C`?** That is the old recipe and it is easy to get subtly wrong.
> `chattr +C` only affects files created *after* it is set on an empty directory, so running the
> steps in the wrong order silently produces a copy-on-write swap file that corrupts under
> memory pressure. `mkswapfile` (btrfs-progs 6.1+) does the whole thing correctly.

---

## Snapshots

Snapper setup happens **after the first reboot**, not now. It is covered in full — including the
`/.snapshots` conflict that trips up almost everyone — on the path notes page:

→ **[Path Notes: Btrfs — Setting up Snapper](../03-base-installation/deltas/btrfs.md#setting-up-snapper-after-first-boot)**

The one thing you must not forget during installation is the package:

```bash
pacman -S btrfs-progs      # in chroot, during base installation
```

> 🔴 Without `btrfs-progs` the installed system cannot mount its own root filesystem. There is no
> warning at install time — it simply fails to boot.

---

## Verification

### Check Mounts

```bash
lsblk -f
```

**Expected output:**
```
NAME   FSTYPE LABEL MOUNTPOINT
sda                 
├─sda1 vfat         /mnt/boot
└─sda2 btrfs  Arch  /mnt
```

### Check Subvolumes

```bash
btrfs subvolume list /mnt
```

### Check Compression

After installation:
```bash
sudo compsize /
```

### Check Filesystem

```bash
btrfs filesystem df /
btrfs filesystem usage /
```

---

## Complete fstab Example

After running `genfstab -U /mnt >> /mnt/etc/fstab`, your fstab should look like:

```
# /dev/sda2 LABEL=Arch
UUID=xxxxx-xxxxx  /              btrfs  noatime,compress=zstd,subvol=/@          0 0
UUID=xxxxx-xxxxx  /home          btrfs  noatime,compress=zstd,subvol=/@home      0 0
UUID=xxxxx-xxxxx  /.snapshots    btrfs  noatime,compress=zstd,subvol=/@snapshots 0 0
UUID=xxxxx-xxxxx  /var/log       btrfs  noatime,compress=zstd,subvol=/@var_log   0 0
UUID=xxxxx-xxxxx  /var/cache     btrfs  noatime,compress=zstd,subvol=/@var_cache 0 0
UUID=xxxxx-xxxxx  /swap          btrfs  noatime,subvol=/@swap                                   0 0

# /dev/sda1
UUID=xxxxx-xxxxx  /boot          vfat   defaults                                                 0 2

# Swap file
/swap/swapfile    none           swap   defaults                                                 0 0
```

---

## Quick Reference

```bash
# Create partitions
cfdisk /dev/sda

# Format
mkfs.fat -F32 /dev/sda1
mkfs.btrfs -L "Arch" /dev/sda2

# Mount and create subvolumes
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@swap
umount /mnt

# Mount with options
mount -o noatime,compress=zstd,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}
mount -o noatime,compress=zstd,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd,subvol=@snapshots /dev/sda2 /mnt/.snapshots
mount -o noatime,compress=zstd,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,subvol=@swap /dev/sda2 /mnt/swap
mount /dev/sda1 /mnt/boot

# Create swap
btrfs filesystem mkswapfile --size 8g --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Verify
lsblk -f
```

---

## Next Steps

→ **[Base System Installation](../03-base-installation/base-install-common.md)**

At its two branch points, use the **Btrfs** row:

| Branch | Answer |
|--------|--------|
| Step 6.2 — extra packages | `btrfs-progs` |
| Step 9 — HOOKS | Arch default, unchanged |

Details: **[Path Notes: Btrfs](../03-base-installation/deltas/btrfs.md)**

Then pick a bootloader:

- [GRUB](../03-base-installation/bootloader-standard.md) — works everywhere, and `grub-btrfs`
  gives you a boot-from-snapshot menu
- [systemd-boot](../03-base-installation/bootloader-systemd.md) — simpler and faster, but you
  must add `rootflags=subvol=@` to the entry by hand

> **Want encryption too?** See [Btrfs with Full Disk Encryption](btrfs-encryption.md).

---

<div align="center">

[← LVM Setup](lvm-setup.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation →](../03-base-installation/base-install-common.md)

</div>
