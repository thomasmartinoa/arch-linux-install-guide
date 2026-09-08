# Btrfs Partitioning Guide

> Modern copy-on-write filesystem with snapshots, compression, and easy rollbacks.

## Table of Contents

- [Why Btrfs?](#why-btrfs)
- [Partition Layout](#partition-layout)
- [Step-by-Step Setup](#step-by-step-setup)
- [Subvolume Layout](#subvolume-layout)
- [Mount Options](#mount-options)
- [Snapshots](#snapshots)
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

Snapshots are why most people choose Btrfs. You set them up **after the first reboot**, not now —
but the subvolume layout you just created is what makes them work.

The one thing you must not forget during installation is the package:

```bash
pacman -S btrfs-progs      # in the chroot, during base installation
```

> 🔴 Without `btrfs-progs` the installed system cannot mount its own root filesystem. Nothing
> warns you — it simply fails to boot.

```bash
sudo pacman -S snapper snap-pac grub-btrfs
```

| Package | Purpose |
|---------|---------|
| `snapper` | Creates and manages snapshots |
| `snap-pac` | Automatic snapshot before and after every `pacman` transaction |
| `grub-btrfs` | Adds a "boot from snapshot" submenu to GRUB |

### The `/.snapshots` conflict — read this before running `create-config`

`snapper create-config` insists on creating its own `/.snapshots` subvolume, and refuses to run
if anything is already mounted there. But your `@snapshots` **is** mounted there — `genfstab`
captured it during install, so it mounts at every boot. Run `create-config` now and you get:

```
Creating config failed (creating btrfs subvolume .snapshots failed since it already exists).
```

That is the single most common Btrfs-on-Arch stumbling block. The fix is to get out of
snapper's way, let it do its thing, then put your own subvolume back:

```bash
sudo umount /.snapshots                    # unmount YOUR @snapshots
sudo rm -r /.snapshots                     # remove the now-empty mount point
sudo snapper -c root create-config /       # snapper creates ITS own /.snapshots subvolume
sudo btrfs subvolume delete /.snapshots    # delete snapper's — you want yours
sudo mkdir /.snapshots                     # recreate the mount point
sudo mount -a                              # remount YOUR @snapshots from fstab
sudo chmod 750 /.snapshots                 # snapper expects these permissions
```

Order matters throughout. `create-config` must run while nothing is mounted at `/.snapshots`,
and the `mount -a` at the end is what reconnects the subvolume `genfstab` recorded.

### Turn on automatic snapshots

```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now grub-btrfsd
```

### Tune the retention limits

```bash
sudo vim /etc/snapper/configs/root
```

```ini
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
```

Defaults keep far more snapshots than a desktop needs, and they are what fills your disk.

### Check it works

```bash
sudo snapper -c root list      # should show snapshots
sudo compsize /                # how much compression is actually saving you
```

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

Your disk is ready. Next you install Arch onto it.

→ **[Base Installation — Btrfs](../03-base-installation/base-install-btrfs.md)**

That guide is written specifically for the **Btrfs** layout you just created — follow it
straight through, there is nothing to pick or choose.

---

<div align="center">

[← Partition Overview](partition-overview.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation — Btrfs →](../03-base-installation/base-install-btrfs.md)

</div>
