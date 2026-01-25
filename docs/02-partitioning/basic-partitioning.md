# Basic Partitioning Guide

> Simple partition setup for beginners - perfect for your first Arch installation.

![Basic Partitioning](../../images/basic-partition.png)

## Table of Contents

- [Overview](#overview)
- [Identify Your Disk](#identify-your-disk)
- [Partition Layout](#partition-layout)
- [Step-by-Step Partitioning](#step-by-step-partitioning)
- [Format Partitions](#format-partitions)
- [Mount Partitions](#mount-partitions)
- [Verification](#verification)

---

## Overview

This guide creates a simple partition layout:

```
┌───────────────────────────────────────────────────┐
│                      DISK                         │
├─────────┬─────────────────────────────┬───────────┤
│   EFI   │          ROOT (/)           │   SWAP    │
│  512MB  │        (remaining)          │   8GB     │
│  FAT32  │          ext4               │   swap    │
└─────────┴─────────────────────────────┴───────────┘
```

| Partition | Size | Filesystem | Purpose |
|-----------|------|------------|---------|
| EFI | 512MB | FAT32 | Boot files |
| Root | Remaining | ext4 | Operating system + data |
| Swap | 8GB | swap | Virtual memory |

---

## Identify Your Disk

> **Device Naming Convention:**
> - **SATA/USB drives:** `/dev/sda`, `/dev/sdb`, etc. Partitions: `/dev/sda1`, `/dev/sda2`
> - **NVMe drives:** `/dev/nvme0n1`, `/dev/nvme1n1`, etc. Partitions: `/dev/nvme0n1p1`, `/dev/nvme0n1p2`
> - **SD cards/eMMC:** `/dev/mmcblk0`. Partitions: `/dev/mmcblk0p1`, `/dev/mmcblk0p2`
>
> This guide uses `/dev/sda` as an example. **Replace with your actual device!**

### List All Disks

```bash
lsblk
```

**Example output:
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0 500.0G  0 disk              ← SATA drive
nvme0n1     259:0    0   1.0T  0 disk              ← NVMe drive
sdb           8:16   1   8.0G  0 disk              ← USB (installation media)
└─sdb1        8:17   1   8.0G  0 part /run/archiso/bootmnt
```

**Understanding device names:**

| Name | Type | Example |
|------|------|---------|
| `sda`, `sdb` | SATA/SCSI drives | Traditional HDD/SSD |
| `nvme0n1`, `nvme1n1` | NVMe drives | Modern fast SSD |
| `mmcblk0` | eMMC/SD card | Embedded storage |

> **Important:** Identify your **target disk** carefully. In this example, we'll use `/dev/sda`. Replace it with your actual disk!

### Check Disk Details

```bash
fdisk -l /dev/sda
```

**What this shows:**
- Disk size
- Current partition table type (GPT/DOS)
- Existing partitions

---

## Partition Layout

For a **500GB disk**, here's the layout:

| # | Name | Size | Type Code | Filesystem |
|---|------|------|-----------|------------|
| 1 | EFI | 512MB | EF00 | FAT32 |
| 2 | Root | ~484GB | 8300 | ext4 |
| 3 | Swap | 8GB | 8200 | swap |

---

## Step-by-Step Partitioning

### Method 1: Using cfdisk (Recommended)

`cfdisk` has a user-friendly text interface.

```bash
cfdisk /dev/sda
```

#### Step 1: Select Label Type

If prompted, select **gpt** for GPT partition table:

```
┌─────────────────────────────────────────────────┐
│           Select label type                     │
│                                                 │
│     gpt                                         │
│     dos                                         │
│     sgi                                         │
│     sun                                         │
└─────────────────────────────────────────────────┘
```

Select `gpt` and press Enter.

#### Step 2: Create EFI Partition

1. Select **[ New ]** (use arrow keys, Enter to select)
2. Enter size: `512M`
3. Select the new partition
4. Select **[ Type ]**
5. Choose **EFI System**

```
Device         Size     Type
/dev/sda1      512M     EFI System
Free space    499.5G
```

#### Step 3: Create Root Partition

1. Select **Free space**
2. Select **[ New ]**
3. Enter size: `491.5G` (or leave default for remaining - swap)
4. Type is automatically **Linux filesystem** ✓

```
Device         Size     Type
/dev/sda1      512M     EFI System
/dev/sda2     491.5G    Linux filesystem
Free space      8G
```

#### Step 4: Create Swap Partition

1. Select **Free space**
2. Select **[ New ]**
3. Press Enter to use remaining space (8G)
4. Select **[ Type ]**
5. Choose **Linux swap**

```
Device         Size     Type
/dev/sda1      512M     EFI System
/dev/sda2     491.5G    Linux filesystem
/dev/sda3       8G      Linux swap
```

#### Step 5: Write Changes

1. Select **[ Write ]**
2. Type `yes` to confirm
3. Select **[ Quit ]**

---

### Method 2: Using fdisk

```bash
fdisk /dev/sda
```

#### Create GPT Table

```
Command (m for help): g
Created a new GPT disklabel.
```

**Command explanation:**
| Command | Action |
|---------|--------|
| `g` | Create new GPT partition table (erases all partitions!) |

#### Create EFI Partition

```
Command (m for help): n
Partition number (1-128, default 1): 1
First sector: [Enter for default]
Last sector: +512M

Command (m for help): t
Partition type (type L to list all types): 1
Changed type of partition 'Linux filesystem' to 'EFI System'.
```

**Command explanation:**
| Command | Action |
|---------|--------|
| `n` | New partition |
| `+512M` | Set size to 512 megabytes |
| `t` | Change partition type |
| `1` | Type code for EFI System |

#### Create Root Partition

```
Command (m for help): n
Partition number (2-128, default 2): 2
First sector: [Enter for default]
Last sector: -8G
```

**Command explanation:**
| Part | Meaning |
|------|---------|
| `-8G` | Leave 8GB at the end (for swap) |

#### Create Swap Partition

```
Command (m for help): n
Partition number (3-128, default 3): 3
First sector: [Enter for default]
Last sector: [Enter for default - use remaining]

Command (m for help): t
Partition number: 3
Partition type: 19
Changed type to 'Linux swap'.
```

#### View and Write

```
Command (m for help): p

Device       Start        End    Sectors   Size Type
/dev/sda1     2048    1050623    1048576   512M EFI System
/dev/sda2  1050624  980566015  979515392   467G Linux filesystem
/dev/sda3 980566016  997339135   16773120     8G Linux swap

Command (m for help): w
The partition table has been altered.
```

**Command explanation:**
| Command | Action |
|---------|--------|
| `p` | Print partition table |
| `w` | Write changes to disk and exit |

---

## Format Partitions

After creating partitions, they need filesystems.

### Format EFI Partition (FAT32)

```bash
mkfs.fat -F32 /dev/sda1
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `mkfs.fat` | Make filesystem (FAT) |
| `-F32` | FAT32 format (required for EFI) |
| `/dev/sda1` | Target partition |

**Why FAT32?** UEFI firmware can only read FAT filesystems.

---

### Format Root Partition (ext4)

```bash
mkfs.ext4 /dev/sda2
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `mkfs.ext4` | Make ext4 filesystem |
| `/dev/sda2` | Target partition |

**Why ext4?** 
- Most stable Linux filesystem
- Journaling (crash recovery)
- Widely supported

---

### Format Swap Partition

```bash
mkswap /dev/sda3
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `mkswap` | Make swap area |
| `/dev/sda3` | Target partition |

---

## Mount Partitions

Mounting makes partitions accessible at specific directories.

### Mount Order

⚠️ **Important:** Mount order matters! Mount root (/) first, then create directories and mount others.

### Step 1: Mount Root Partition

```bash
mount /dev/sda2 /mnt
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `mount` | Mount a filesystem |
| `/dev/sda2` | Source (root partition) |
| `/mnt` | Target directory (standard for installation) |

---

### Step 2: Create and Mount Boot Directory

```bash
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

**Command breakdown:**

| Command | Purpose |
|---------|---------|
| `mkdir /mnt/boot` | Create boot directory |
| `mount /dev/sda1 /mnt/boot` | Mount EFI partition here |

---

### Step 3: Enable Swap

```bash
swapon /dev/sda3
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `swapon` | Enable swap space |
| `/dev/sda3` | Swap partition |

---

## Verification

### Check Mounts

```bash
lsblk
```

**Expected output:**
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   500G  0 disk
├─sda1   8:1    0   512M  0 part /mnt/boot
├─sda2   8:2    0 491.5G  0 part /mnt
└─sda3   8:3    0     8G  0 part [SWAP]
```

### Check Swap

```bash
swapon --show
```

**Expected output:**
```
NAME      TYPE      SIZE USED PRIO
/dev/sda3 partition   8G   0B   -2
```

---

## Summary Commands

Here's the complete sequence for basic partitioning:

```bash
# 1. Partition the disk (using cfdisk)
cfdisk /dev/sda

# 2. Format partitions
mkfs.fat -F32 /dev/sda1      # EFI partition
mkfs.ext4 /dev/sda2          # Root partition
mkswap /dev/sda3             # Swap partition

# 3. Mount partitions
mount /dev/sda2 /mnt         # Mount root first
mkdir /mnt/boot              # Create boot directory
mount /dev/sda1 /mnt/boot    # Mount EFI partition
swapon /dev/sda3             # Enable swap

# 4. Verify
lsblk
```

---

## Troubleshooting

### "Device or resource busy"

The partition is in use. Unmount first:
```bash
umount /dev/sda1
```

### "No space left on device"

Check if you specified partition sizes correctly:
```bash
fdisk -l /dev/sda
```

### Partition table not updating

Force kernel to re-read partition table:
```bash
partprobe /dev/sda
```

---

## Next Steps

Your disk is now partitioned and ready!

→ [Standard Base Installation](../03-base-installation/base-install-standard.md)

---

<div align="center">

[← Partition Overview](partition-overview.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation →](../03-base-installation/base-install-standard.md)

</div>
