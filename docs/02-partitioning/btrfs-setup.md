# Btrfs Partitioning Guide

> Modern copy-on-write filesystem with snapshots, compression, and easy rollbacks.

![Btrfs Setup](../../images/btrfs-setup.png)

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
│    EFI      │                    Btrfs                          │
│   512MB     │  ┌─────────────────────────────────────────────┐  │
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
| EFI | 512MB | FAT32 | Boot files |
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
| 1 | 512M | EFI System |
| 2 | Remaining | Linux filesystem |

Write and quit.

### Step 2: Format EFI Partition

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
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/sda2 /mnt

# Create mount points
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}

# Mount other subvolumes
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots /dev/sda2 /mnt/.snapshots
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,subvol=@swap /dev/sda2 /mnt/swap

# Mount EFI
mount /dev/sda1 /mnt/boot
```

### Mount Options Explained

| Option | Purpose |
|--------|---------|
| `noatime` | Don't update access time (performance) |
| `compress=zstd` | Use zstd compression (best ratio/speed) |
| `space_cache=v2` | Improved free space tracking |
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
# Disable copy-on-write for swap
chattr +C /mnt/swap

# Create swap file (8GB example)
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8192 status=progress

# Set permissions
chmod 600 /mnt/swap/swapfile

# Format as swap
mkswap /mnt/swap/swapfile

# Enable swap
swapon /mnt/swap/swapfile
```

---

## Snapshot Setup

### Install Required Packages (In Chroot)

> 🔴 **CRITICAL:** Install `btrfs-progs` during base installation, NOT after reboot!

During base installation (while in chroot):

```bash
pacman -S btrfs-progs
```

### Install Snapper (After Base Install)

After installing the base system and rebooting:

```bash
sudo pacman -S snapper snap-pac grub-btrfs
```

### Configure Snapper

```bash
# Create config for root
sudo snapper -c root create-config /

# Check config
sudo snapper -c root list
```

### Snapper Configuration

```bash
sudo nvim /etc/snapper/configs/root
```

Recommended settings:
```ini
# Limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# Limits for number cleanup
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
```

### Enable Automatic Snapshots

```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

### Enable GRUB Boot Snapshots

```bash
sudo systemctl enable --now grub-btrfsd
```

This allows booting from snapshots directly from GRUB menu!

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
UUID=xxxxx-xxxxx  /              btrfs  noatime,compress=zstd,space_cache=v2,subvol=/@          0 0
UUID=xxxxx-xxxxx  /home          btrfs  noatime,compress=zstd,space_cache=v2,subvol=/@home      0 0
UUID=xxxxx-xxxxx  /.snapshots    btrfs  noatime,compress=zstd,space_cache=v2,subvol=/@snapshots 0 0
UUID=xxxxx-xxxxx  /var/log       btrfs  noatime,compress=zstd,space_cache=v2,subvol=/@var_log   0 0
UUID=xxxxx-xxxxx  /var/cache     btrfs  noatime,compress=zstd,space_cache=v2,subvol=/@var_cache 0 0
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
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,swap}
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots /dev/sda2 /mnt/.snapshots
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,subvol=@swap /dev/sda2 /mnt/swap
mount /dev/sda1 /mnt/boot

# Create swap
chattr +C /mnt/swap
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8192 status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Verify
lsblk -f
```

---

## Next Steps

After partitioning, continue to:

→ [Standard Base Installation](../03-base-installation/base-install-standard.md)

> 📝 **Important for Btrfs users:**
> - Install `btrfs-progs` during base installation (covered in the guide)
> - Choose your bootloader:
>   - [GRUB](../03-base-installation/bootloader-standard.md) - Works with all setups
>   - [systemd-boot](../03-base-installation/bootloader-systemd.md) - Simpler, requires `rootflags=subvol=@`

---

<div align="center">

[← LVM Setup](lvm-setup.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation →](../03-base-installation/base-install-standard.md)

</div>
