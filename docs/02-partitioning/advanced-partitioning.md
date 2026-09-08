# Advanced Partitioning Guide

> Separate partitions for root, home, and swap - recommended for regular desktop use.

## Table of Contents

- [Overview](#overview)
- [Partition Layout](#partition-layout)
- [Step-by-Step Partitioning](#step-by-step-partitioning)
- [Format Partitions](#format-partitions)
- [Mount Partitions](#mount-partitions)
- [Verification](#verification)

---

## Overview

This setup separates your personal files (`/home`) from the system:

```
┌─────────────────────────────────────────────────────────────┐
│                          DISK                               │
├─────────┬───────────┬───────────────────────────┬───────────┤
│   EFI   │   ROOT    │          HOME             │   SWAP    │
│   1GB   │   50GB    │       (remaining)         │   8GB     │
│  FAT32  │   ext4    │          ext4             │   swap    │
└─────────┴───────────┴───────────────────────────┴───────────┘
```

### Benefits of Separate /home

| Benefit | Description |
|---------|-------------|
| **Safe Reinstalls** | Reinstall Arch without losing personal files |
| **Easy Backups** | Backup only the /home partition |
| **Different Filesystems** | Use btrfs for /home, ext4 for root |
| **Quota Management** | Limit disk space per partition |

---

## Partition Layout

For a **500GB disk**:

| # | Mount Point | Size | Filesystem | Purpose |
|---|-------------|------|------------|---------|
| 1 | /boot | 1GB | FAT32 | ESP — bootloader + kernels |
| 2 | / | 50GB | ext4 | Operating system |
| 3 | /home | ~442GB | ext4 | Personal files |
| 4 | [SWAP] | 8GB | swap | Virtual memory |

### Sizing Guidelines

| Partition | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| ESP | 512MB | 1GB | Holds the bootloader and all your kernels |
| Root (/) | 20GB | 50-100GB | System + programs |
| Home (/home) | 10GB | Remaining | Personal files |
| Swap | 2GB | RAM size | For hibernation: 1.5x RAM |

---

## Step-by-Step Partitioning

### Using cfdisk (Recommended)

```bash
cfdisk /dev/sda
```

If prompted for label type, select **gpt**.

#### Create All Partitions

| Step | Action | Size | Type |
|------|--------|------|------|
| 1 | New → | `1G` | EFI System |
| 2 | New → | `50G` | Linux filesystem |
| 3 | New → | `-8G` (remaining minus 8G) | Linux filesystem |
| 4 | New → | (remaining) | Linux swap |

**Final layout:**
```
Device         Size     Type
/dev/sda1        1G     EFI System
/dev/sda2       50G     Linux filesystem
/dev/sda3    441.5G     Linux filesystem  
/dev/sda4        8G     Linux swap
```

Select **[ Write ]** → type `yes` → **[ Quit ]**

---

### Using fdisk

```bash
fdisk /dev/sda
```

```
# Create GPT table
Command: g

# Partition 1: EFI
Command: n
Partition number: 1
First sector: [Enter]
Last sector: +1G
Command: t
Type: 1

# Partition 2: Root
Command: n
Partition number: 2
First sector: [Enter]
Last sector: +50G

# Partition 3: Home
Command: n
Partition number: 3
First sector: [Enter]
Last sector: -8G

# Partition 4: Swap
Command: n
Partition number: 4
First sector: [Enter]
Last sector: [Enter]
Command: t
Partition: 4
Type: 19

# Verify and write
Command: p
Command: w
```

---

## Format Partitions

### Format All Partitions

```bash
# EFI partition (must be FAT32)
mkfs.fat -F32 /dev/sda1

# Root partition
mkfs.ext4 /dev/sda2

# Home partition
mkfs.ext4 /dev/sda3

# Swap partition
mkswap /dev/sda4
```

### Command Explanations

#### mkfs.fat -F32

```bash
mkfs.fat -F32 /dev/sda1
```

| Part | Meaning |
|------|---------|
| `mkfs.fat` | Make a FAT filesystem |
| `-F32` | Use FAT32 (required for UEFI) |
| `/dev/sda1` | Target partition |

---

#### mkfs.ext4

```bash
mkfs.ext4 /dev/sda2
```

| Part | Meaning |
|------|---------|
| `mkfs.ext4` | Make an ext4 filesystem |
| `/dev/sda2` | Target partition |

**ext4 Features:**
- **Journaling** - Crash recovery
- **Large file support** - Up to 16TB files
- **Fast fsck** - Quick filesystem checks
- **Delayed allocation** - Better performance

---

#### mkswap

```bash
mkswap /dev/sda4
```

| Part | Meaning |
|------|---------|
| `mkswap` | Initialize swap area |
| `/dev/sda4` | Target partition |

---

## Mount Partitions

### Mount Order (Important!)

Mount partitions in this order:
1. Root (/) first
2. Create subdirectories
3. Mount other partitions

### Step 1: Mount Root

```bash
mount /dev/sda2 /mnt
```

---

### Step 2: Create Directories

```bash
mkdir /mnt/boot
mkdir /mnt/home
```

---

### Step 3: Mount Boot and Home

```bash
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home
```

---

### Step 4: Enable Swap

```bash
swapon /dev/sda4
```

---

## Verification

### Check All Mounts

```bash
lsblk
```

**Expected output:**
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   500G  0 disk
├─sda1   8:1    0     1G  0 part /mnt/boot
├─sda2   8:2    0    50G  0 part /mnt
├─sda3   8:3    0 441.5G  0 part /mnt/home
└─sda4   8:4    0     8G  0 part [SWAP]
```

### Check Swap

```bash
swapon --show
```

---

## Complete Command Summary

```bash
# Partition (interactive)
cfdisk /dev/sda

# Format partitions
mkfs.fat -F32 /dev/sda1      # EFI
mkfs.ext4 /dev/sda2          # Root
mkfs.ext4 /dev/sda3          # Home
mkswap /dev/sda4             # Swap

# Mount partitions
mount /dev/sda2 /mnt         # Root first!
mkdir /mnt/boot /mnt/home    # Create mount points
mount /dev/sda1 /mnt/boot    # EFI
mount /dev/sda3 /mnt/home    # Home
swapon /dev/sda4             # Enable swap

# Verify
lsblk
```

---

## Alternative: Using Labels

You can assign labels to partitions for easier identification:

```bash
# Format with labels
mkfs.fat -F32 -n EFI /dev/sda1
mkfs.ext4 -L ROOT /dev/sda2
mkfs.ext4 -L HOME /dev/sda3
mkswap -L SWAP /dev/sda4

# Mount using labels
mount -L ROOT /mnt
mkdir /mnt/boot /mnt/home
mount -L EFI /mnt/boot
mount -L HOME /mnt/home
swapon -L SWAP
```

Labels appear in `lsblk -f`:
```
NAME   FSTYPE LABEL SIZE MOUNTPOINT
sda1   vfat   ESP     1G /mnt/boot
sda2   ext4   ROOT   50G /mnt
sda3   ext4   HOME  441G /mnt/home
sda4   swap   SWAP    8G [SWAP]
```

---

## Next Steps

Your disk is ready. Next you install Arch onto it.

→ **[Base Installation — Standard](../03-base-installation/base-install-standard.md)**

That guide is written specifically for the **Standard (ext4)** layout you just created — follow it
straight through, there is nothing to pick or choose.

---

<div align="center">

[← Partition Overview](partition-overview.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation — Standard →](../03-base-installation/base-install-standard.md)

</div>
