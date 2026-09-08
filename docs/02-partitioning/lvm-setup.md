# LVM Setup Guide

> Flexible partition management using Logical Volume Manager.

## Table of Contents

- [What is LVM?](#what-is-lvm)
- [LVM Concepts](#lvm-concepts)
- [Partition Layout](#partition-layout)
- [Step-by-Step Setup](#step-by-step-setup)
- [Mount Partitions](#mount-partitions)
- [Verification](#verification)

---

## What is LVM?

**LVM (Logical Volume Manager)** provides a layer of abstraction between your physical disks and filesystems.

### Benefits of LVM

| Benefit | Description |
|---------|-------------|
| **Resize Volumes** | Grow or shrink partitions without unmounting |
| **Span Disks** | Combine multiple physical disks into one |
| **Snapshots** | Create point-in-time copies |
| **Easy Management** | Add/remove disks dynamically |

### When to Use LVM

- You want flexibility to resize partitions later
- You might add more disks in the future
- You need snapshot capability
- You're setting up a server
- Not ideal for simple desktop with fixed storage needs

---

## LVM Concepts

```
Physical Disk(s)
       ↓
┌──────────────────┐
│ Physical Volumes │ ← PV: Entire disk or partition
└────────┬─────────┘
         ↓
┌──────────────────┐
│   Volume Group   │ ← VG: Pool of storage from one or more PVs
└────────┬─────────┘
         ↓
┌──────────────────┐
│ Logical Volumes  │ ← LV: Virtual partitions carved from VG
└──────────────────┘
```

### Terminology

| Term | Abbreviation | Description |
|------|--------------|-------------|
| Physical Volume | PV | Physical disk/partition prepared for LVM |
| Volume Group | VG | Collection of PVs, storage pool |
| Logical Volume | LV | Virtual partition within a VG |
| Physical Extent | PE | Smallest unit of storage (default 4MB) |

### Analogy

Think of it like a warehouse:
- **PV** = Physical warehouse buildings
- **VG** = Combined floor space of all buildings
- **LV** = Allocated areas within the space

---

## Partition Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                DISK                                     │
├─────────┬───────────────────────────────────────────────────────────────┤
│   EFI   │                    LVM Physical Volume                        │
│   1GB   │  ┌──────────────────────────────────────────────────────────┐ │
│         │  │              Volume Group (volgroup0)                    │ │
│  FAT32  │  │ ┌─────────┐  ┌──────────────────┐  ┌───────────────────┐ │ │
│         │  │ │lv_root  │  │     lv_home      │  │     lv_swap       │ │ │
│         │  │ │  50GB   │  │    (remaining)   │  │        8GB        │ │ │
│         │  │ │  ext4   │  │       ext4       │  │       swap        │ │ │
│         │  │ └─────────┘  └──────────────────┘  └───────────────────┘ │ │
│         │  └──────────────────────────────────────────────────────────┘ │
└─────────┴───────────────────────────────────────────────────────────────┘
```

| Volume | Size | Filesystem | Purpose |
|--------|------|------------|---------|
| ESP | 1GB | FAT32 | Bootloader + kernels |
| lv_root | 50GB | ext4 | Operating system |
| lv_home | 400GB+ | ext4 | Personal files |
| lv_swap | 8GB | swap | Virtual memory |

---

## Step-by-Step Setup

### Step 1: Create Partitions

We need two partitions: EFI and LVM.

```bash
cfdisk /dev/sda
```

**Create:**

| # | Size | Type |
|---|------|------|
| 1 | 1G | EFI System |
| 2 | Remaining | Linux LVM |

**Result:**
```
Device         Size     Type
/dev/sda1        1G     EFI System
/dev/sda2    499.5G     Linux LVM
```

Write and quit.

---

### Step 2: Format EFI Partition

```bash
mkfs.fat -F32 /dev/sda1
```

---

### Step 3: Create Physical Volume

```bash
pvcreate /dev/sda2
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `pvcreate` | Initialize a physical volume for LVM |
| `/dev/sda2` | Partition to use |

**Verify:**
```bash
pvdisplay
```

**Output:**
```
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               
  PV Size               499.50 GiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              127871
  Free PE               127871
  Allocated PE          0
```

---

### Step 4: Create Volume Group

```bash
vgcreate volgroup0 /dev/sda2
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `vgcreate` | Create a volume group |
| `volgroup0` | Name for the volume group |
| `/dev/sda2` | Physical volume to include |

**Verify:**
```bash
vgdisplay
```

**Output:**
```
  --- Volume group ---
  VG Name               volgroup0
  System ID             
  Format                lvm2
  VG Size               499.50 GiB
  PE Size               4.00 MiB
  Total PE              127871
  Alloc PE / Size       0 / 0
  Free  PE / Size       127871 / 499.50 GiB
```

---

### Step 5: Create Logical Volumes

#### Create Root Volume

```bash
lvcreate -L 50GB volgroup0 -n lv_root
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `lvcreate` | Create a logical volume |
| `-L 50GB` | Size: 50 gigabytes |
| `volgroup0` | Volume group to use |
| `-n lv_root` | Name: lv_root |

---

#### Create Swap Volume

```bash
lvcreate -L 8GB volgroup0 -n lv_swap
```

---

#### Create Home Volume (Remaining Space)

```bash
lvcreate -l 100%FREE volgroup0 -n lv_home
```

**Note:** `-l 100%FREE` uses all remaining space.

**Alternative with specific size:**
```bash
lvcreate -L 400GB volgroup0 -n lv_home
```

---

### Step 6: Verify Logical Volumes

```bash
lvdisplay
```

**Output:**
```
  --- Logical volume ---
  LV Path                /dev/volgroup0/lv_root
  LV Name                lv_root
  VG Name                volgroup0
  LV Size                50.00 GiB
  
  --- Logical volume ---
  LV Path                /dev/volgroup0/lv_swap
  LV Name                lv_swap
  VG Name                volgroup0
  LV Size                8.00 GiB

  --- Logical volume ---
  LV Path                /dev/volgroup0/lv_home
  LV Name                lv_home
  VG Name                volgroup0
  LV Size                441.50 GiB
```

---

### Step 7: Load Device Mapper Module

```bash
modprobe dm_mod
```

**What this does:**
- Loads the device-mapper kernel module
- Required for LVM to function properly

---

### Step 8: Scan and Activate Volume Groups

```bash
vgscan
vgchange -ay
```

**Command breakdown:**

| Command | Purpose |
|---------|---------|
| `vgscan` | Scan for volume groups |
| `vgchange -ay` | Activate all volume groups (-a = activate, y = yes) |

---

### Step 9: Format Logical Volumes

```bash
# Root filesystem
mkfs.ext4 /dev/volgroup0/lv_root

# Home filesystem
mkfs.ext4 /dev/volgroup0/lv_home

# Swap
mkswap /dev/volgroup0/lv_swap
```

---

## Mount Partitions

### Step 1: Mount Root

```bash
mount /dev/volgroup0/lv_root /mnt
```

### Step 2: Create Mount Points

```bash
mkdir /mnt/boot
mkdir /mnt/home
```

### Step 3: Mount Boot and Home

```bash
mount /dev/sda1 /mnt/boot
mount /dev/volgroup0/lv_home /mnt/home
```

### Step 4: Enable Swap

```bash
swapon /dev/volgroup0/lv_swap
```

---

## Verification

### Check Block Devices

```bash
lsblk
```

**Expected output:**
```
NAME                   SIZE TYPE  MOUNTPOINT
sda                    500G disk
├─sda1                   1G part  /mnt/boot
└─sda2               499.5G part
  ├─volgroup0-lv_root   50G lvm   /mnt
  ├─volgroup0-lv_swap    8G lvm   [SWAP]
  └─volgroup0-lv_home  441G lvm   /mnt/home
```

### Check Volume Group

```bash
vgdisplay volgroup0
```

### Check Logical Volumes

```bash
lvs
```

**Output:**
```
  LV      VG        Attr       LSize   Pool Origin Data%  Meta%
  lv_home volgroup0 -wi-ao---- 441.50g
  lv_root volgroup0 -wi-ao----  50.00g
  lv_swap volgroup0 -wi-ao----   8.00g
```

---

## Complete Command Summary

```bash
# 1. Create partitions
cfdisk /dev/sda
# Create: 1G ESP (EF00), remaining Linux LVM (8E00)

# 2. Format EFI
mkfs.fat -F32 /dev/sda1

# 3. Setup LVM
pvcreate /dev/sda2
vgcreate volgroup0 /dev/sda2
lvcreate -L 50GB volgroup0 -n lv_root
lvcreate -L 8GB volgroup0 -n lv_swap
lvcreate -l 100%FREE volgroup0 -n lv_home

# 4. Activate LVM
modprobe dm_mod
vgscan
vgchange -ay

# 5. Format logical volumes
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home
mkswap /dev/volgroup0/lv_swap

# 6. Mount
mount /dev/volgroup0/lv_root /mnt
mkdir /mnt/boot /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/volgroup0/lv_home /mnt/home
swapon /dev/volgroup0/lv_swap

# 7. Verify
lsblk
```

---

## LVM Management Commands

After installation, you can manage LVM with these commands:

### Resize Logical Volume

```bash
# Extend lv_home by 50GB
lvextend -L +50G /dev/volgroup0/lv_home
resize2fs /dev/volgroup0/lv_home

# Reduce lv_home (requires unmounting)
umount /mnt/home
e2fsck -f /dev/volgroup0/lv_home
resize2fs /dev/volgroup0/lv_home 300G
lvreduce -L 300G /dev/volgroup0/lv_home
```

### Add New Disk

```bash
pvcreate /dev/sdb1
vgextend volgroup0 /dev/sdb1
```

### Create Snapshot

```bash
lvcreate -L 10G -s -n root_snapshot /dev/volgroup0/lv_root
```

---

## Next Steps

Your disk is ready. Next you install Arch onto it.

→ **[Base Installation — LVM](../03-base-installation/base-install-lvm.md)**

That guide is written specifically for the **LVM** layout you just created — follow it
straight through, there is nothing to pick or choose.

---

<div align="center">

[← Partition Overview](partition-overview.md) | [Back to Main Guide](../../README.md) | [Next: Base Installation — LVM →](../03-base-installation/base-install-lvm.md)

</div>
