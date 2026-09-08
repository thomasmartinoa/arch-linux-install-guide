# Understanding Disk Partitioning

> A guide to understanding disk partitioning before you start.

## Table of Contents

- [Device Naming](#device-naming)
- [What is Partitioning?](#what-is-partitioning)
- [Partition Tables: GPT vs MBR](#partition-tables-gpt-vs-mbr)
- [Partition Types](#partition-types)
- [Partition Schemes](#partition-schemes)
- [Choosing Your Setup](#choosing-your-setup)
- [Tools Overview](#tools-overview)

---

## Device Naming

> **Important:** Device names vary by disk type. Know your disk before partitioning!

### Device Naming Conventions

| Disk Type | Device | Partitions | Example |
|-----------|--------|------------|---------|
| **SATA/USB** | `/dev/sda`, `/dev/sdb` | `/dev/sda1`, `/dev/sda2` | HDD, SSD, USB drives |
| **NVMe** | `/dev/nvme0n1`, `/dev/nvme1n1` | `/dev/nvme0n1p1`, `/dev/nvme0n1p2` | NVMe SSDs |
| **SD/eMMC** | `/dev/mmcblk0` | `/dev/mmcblk0p1`, `/dev/mmcblk0p2` | SD cards, eMMC |
| **Virtual** | `/dev/vda` | `/dev/vda1`, `/dev/vda2` | VMs (KVM/QEMU) |

### Find Your Disk

```bash
lsblk
```

**Example output:**
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0 500.0G  0 disk          ← SATA disk
nvme0n1     259:0    0   1.0T  0 disk          ← NVMe disk
└─nvme0n1p1 259:1    0   512M  0 part
sdb           8:16   1   8.0G  0 disk          ← USB drive
```

> **Note:** This guide uses `/dev/sda` as an example. **Replace with YOUR device!**
> - If you have NVMe: use `/dev/nvme0n1` and partitions `/dev/nvme0n1p1`, `/dev/nvme0n1p2`, etc.
> - If you have SATA: use `/dev/sda` and partitions `/dev/sda1`, `/dev/sda2`, etc.

---

## What is Partitioning?

**Partitioning** divides a physical disk into separate logical sections. Each partition acts as an independent unit with its own filesystem.

### Analogy
Think of a disk as a building:
- The **disk** is the entire building
- **Partitions** are individual rooms/apartments
- Each room can be used for different purposes (bedroom, kitchen, office)

### Why Partition?

| Reason | Explanation |
|--------|-------------|
| **Organization** | Separate system files from personal data |
| **Dual Boot** | Run multiple operating systems |
| **Security** | Encrypt sensitive partitions |
| **Backup** | Easier to backup specific partitions |
| **Recovery** | Reinstall OS without losing data |

---

## Partition Tables: GPT vs MBR

A **partition table** is a data structure on the disk that defines partition locations.

### GPT (GUID Partition Table) - Recommended

| Feature | Specification |
|---------|---------------|
| **Max Partitions** | 128 partitions |
| **Max Disk Size** | 9.4 ZB (zettabytes) |
| **Boot Mode** | UEFI |
| **Redundancy** | Backup table at end of disk |
| **Compatibility** | Modern systems (2010+) |

### MBR (Master Boot Record)

| Feature | Specification |
|---------|---------------|
| **Max Partitions** | 4 primary (or 3 primary + extended) |
| **Max Disk Size** | 2 TB |
| **Boot Mode** | Legacy BIOS |
| **Redundancy** | None |
| **Compatibility** | All systems |

### Quick Comparison

```
GPT:
├── Partition 1 (EFI)
├── Partition 2 (Boot)
├── Partition 3 (Root)
├── Partition 4 (Home)
├── Partition 5 (Swap)
└── ... up to 128 partitions

MBR:
├── Primary 1
├── Primary 2
├── Primary 3
└── Extended Partition
    ├── Logical 1
    ├── Logical 2
    └── ...
```

> **Recommendation:** Use **GPT** for all modern installations. This guide focuses on GPT.

---

## Partition Types

### EFI System Partition (ESP)

| Property | Value |
|----------|-------|
| **Purpose** | Stores bootloaders and boot files |
| **Required** | Yes (for UEFI) |
| **Size** | 1GB recommended (512MB absolute minimum) |
| **Filesystem** | FAT32 |
| **Mount Point** | `/boot` or `/boot/efi` |

```bash
# Create EFI partition filesystem
mkfs.fat -F32 /dev/sdX1
```

> **Why 1GB and not 512MB?** On most layouts in this guide the ESP is mounted at `/boot`, so it
> holds your kernels and initramfs images as well as the bootloader. Two kernels (`linux` and
> `linux-lts`), each with a normal and a fallback initramfs, plus microcode, comes to roughly
> 400-500MB — and the fallback images grow substantially once NVIDIA modules are involved.
> 512MB works until it suddenly doesn't, and it fails during a kernel update, which is the worst
> time to run out of space on `/boot`. 1GB costs nothing and removes the problem.

---

### Boot Partition

| Property | Value |
|----------|-------|
| **Purpose** | Stores kernel and initramfs |
| **Required** | Only for encrypted setups |
| **Size** | 1GB recommended (512MB absolute minimum) |
| **Filesystem** | ext4 or FAT32 |
| **Mount Point** | `/boot` |

> 💡 **Note:** For simple setups, EFI and boot can be combined. For encrypted setups, keep them separate.

---

### Root Partition (/)

| Property | Value |
|----------|-------|
| **Purpose** | Contains the operating system |
| **Required** | Yes |
| **Size** | 30GB - 100GB |
| **Filesystem** | ext4, btrfs, xfs |
| **Mount Point** | `/` |

**What's stored here:**
- System programs (`/usr`)
- Configuration (`/etc`)
- Variable data (`/var`)
- Temporary files (`/tmp`)

---

### Home Partition (/home)

| Property | Value |
|----------|-------|
| **Purpose** | Stores user personal files |
| **Required** | No (can be part of root) |
| **Size** | Remaining space |
| **Filesystem** | ext4, btrfs, xfs |
| **Mount Point** | `/home` |

**What's stored here:**
- Documents, Downloads, Pictures
- User configurations (dotfiles)
- Application data

**Benefits of separate /home:**
- Reinstall OS without losing data
- Different filesystem options
- Easier backups

---

### Swap Partition/File

| Property | Value |
|----------|-------|
| **Purpose** | Virtual memory / hibernation |
| **Required** | Recommended |
| **Size** | See table below |
| **Filesystem** | swap |
| **Mount Point** | none (swap) |

**Swap Size Guidelines:**

| RAM | No Hibernation | With Hibernation |
|-----|----------------|------------------|
| ≤ 2GB | 2x RAM | 3x RAM |
| 2-8GB | Equal to RAM | 2x RAM |
| 8-64GB | At least 4GB | 1.5x RAM |
| > 64GB | At least 4GB | Not recommended |

> 💡 **Alternative:** You can use a swap file instead of a partition, which is easier to resize.

---

## Partition Schemes

### Scheme 1: Minimal (Beginners) ⭐

```
┌─────────────────────────────────────────────┐
│                   DISK                      │
├─────────┬───────────────────────────────────┤
│   EFI   │            ROOT (/)               │
│   1GB   │          (remaining)              │
│  FAT32  │            ext4                   │
└─────────┴───────────────────────────────────┘
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot |
| Root | Remaining | ext4 | / |

**Pros:** Simple, minimal partitions
**Cons:** No separate data partition, no swap

---

### Scheme 2: Basic with Swap

```
┌───────────────────────────────────────────────────┐
│                      DISK                         │
├─────────┬─────────────────────────────┬───────────┤
│   EFI   │          ROOT (/)           │   SWAP    │
│   1GB   │        (remaining)          │   8GB     │
│  FAT32  │          ext4               │   swap    │
└─────────┴─────────────────────────────┴───────────┘
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot |
| Root | Remaining - 8GB | ext4 | / |
| Swap | 8GB | swap | [SWAP] |

**Pros:** Has swap for better performance
**Cons:** No separate home partition

---

### Scheme 3: Standard (Recommended) ⭐

```
┌─────────────────────────────────────────────────────────────┐
│                          DISK                               │
├─────────┬───────────┬───────────────────────────┬───────────┤
│   EFI   │   ROOT    │          HOME             │   SWAP    │
│   1GB   │   50GB    │       (remaining)         │   8GB     │
│  FAT32  │   ext4    │          ext4             │   swap    │
└─────────┴───────────┴───────────────────────────┴───────────┘
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot |
| Root | 50-100GB | ext4 | / |
| Home | Remaining - 8GB | ext4 | /home |
| Swap | 8GB | swap | [SWAP] |

**Pros:** Separate home for data safety
**Cons:** Fixed root size

---

### Scheme 4: Advanced (Separate Boot)

```
┌───────────────────────────────────────────────────────────────────────┐
│                              DISK                                     │
├─────────┬─────────┬───────────┬───────────────────────────┬───────────┤
│   EFI   │  BOOT   │   ROOT    │          HOME             │   SWAP    │
│   1GB   │   1GB   │   50GB    │       (remaining)         │   8GB     │
│  FAT32  │  ext4   │   ext4    │          ext4             │   swap    │
└─────────┴─────────┴───────────┴───────────────────────────┴───────────┘
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot/efi |
| Boot | 1GB | ext4 | /boot |
| Root | 50-100GB | ext4 | / |
| Home | Remaining - 8GB | ext4 | /home |
| Swap | 8GB | swap | [SWAP] |

**Pros:** Required for encryption, flexible
**Cons:** More complex

---

### Scheme 5: Btrfs with Subvolumes (Modern) ⭐

```
┌───────────────────────────────────────────────────────────────┐
│                          DISK                                 │
├─────────┬─────────────────────────────────────────────────────┤
│   EFI   │              BTRFS Partition                        │
│   1GB   │  ┌───────────────────────────────────────────────┐  │
│         │  │             Btrfs Subvolumes                  │  │
│  FAT32  │  │  ┌─────┐ ┌──────┐ ┌──────────┐ ┌───────────┐  │  │
│         │  │  │  @  │ │@home │ │@snapshots│ │  @var_log │  │  │
│         │  │  │  /  │ │/home │ │/.snapshots│ │ /var/log  │  │  │
│         │  │  └─────┘ └──────┘ └──────────┘ └───────────┘  │  │
│         │  └───────────────────────────────────────────────┘  │
└─────────┴─────────────────────────────────────────────────────┘
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot |
| Btrfs | Remaining | btrfs | / (with subvolumes) |

**Subvolumes:**
- `@` → `/` (root)
- `@home` → `/home` (user data)
- `@snapshots` → `/.snapshots` (Snapper snapshots)
- `@var_log` → `/var/log` (logs, excluded from snapshots)

**Pros:** Built-in snapshots, compression (zstd), CoW filesystem, easy rollback
**Cons:** Slightly more complex than ext4, swap file needs special handling

> 💡 **Recommended for:** Desktop users who want easy system rollback with Snapper.

---

### Scheme 6: LVM (Flexible)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                DISK                                     │
├─────────┬───────────────────────────────────────────────────────────────┤
│   EFI   │                    LVM Physical Volume                        │
│   1GB   │  ┌──────────────────────────────────────────────────────────┐ │
│         │  │              Volume Group (volgroup0)                    │ │
│  FAT32  │  │ ┌─────────┐  ┌──────────────────┐  ┌───────────────────┐ │ │
│         │  │ │   ROOT  │  │       HOME       │  │       SWAP        │ │ │
│         │  │ │  50GB   │  │    (remaining)   │  │        8GB        │ │ │
│         │  │ │  ext4   │  │       ext4       │  │       swap        │ │ │
│         │  │ └─────────┘  └──────────────────┘  └───────────────────┘ │ │
│         │  └──────────────────────────────────────────────────────────┘ │
└─────────┴───────────────────────────────────────────────────────────────┘
```

**Pros:** Resize partitions, snapshots, span multiple disks
**Cons:** More complex setup

---

### Scheme 7: LVM + Encryption (Most Secure)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                 DISK                                       │
├─────────┬─────────┬────────────────────────────────────────────────────────┤
│   EFI   │  BOOT   │              LUKS Encrypted Container                  │
│   1GB   │   1GB   │  ┌────────────────────────────────────────────────────┐│
│         │         │  │              LVM Physical Volume                   ││
│  FAT32  │  ext4   │  │  ┌──────────────────────────────────────────────┐  ││
│         │         │  │  │           Volume Group (volgroup0)           │  ││
│         │         │  │  │ ┌───────┐  ┌────────────────┐  ┌───────────┐ │  ││
│         │         │  │  │ │ ROOT  │  │      HOME      │  │   SWAP    │ │  ││
│         │         │  │  │ │ 50GB  │  │  (remaining)   │  │    8GB    │ │  ││
│         │         │  │  │ └───────┘  └────────────────┘  └───────────┘ │  ││
│         │         │  │  └──────────────────────────────────────────────┘  ││
│         │         │  └────────────────────────────────────────────────────┘│
└─────────┴─────────┴────────────────────────────────────────────────────────┘
```

**Pros:** Full disk encryption, flexible partitions
**Cons:** Most complex, requires passphrase at boot

---

### Scheme 8: Btrfs + LUKS (Encrypted, with Snapshots) ⭐

```
┌─────────┬───────────────────────────────────────────────────────┐
│   ESP   │              LUKS Encrypted Container                 │
│   1GB   │  ┌─────────────────────────────────────────────────┐  │
│         │  │                   Btrfs                         │  │
│  FAT32  │  │   @  →  /        @home  →  /home                │  │
│  /boot  │  │   @snapshots  →  /.snapshots                    │  │
│         │  │   @var_log    →  /var/log                       │  │
│         │  │   @swap       →  /swap                          │  │
│         │  └─────────────────────────────────────────────────┘  │
└─────────┴───────────────────────────────────────────────────────┘
      ↑                            ↑
 unencrypted                   ENCRYPTED
```

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| ESP | 1GB | FAT32 | /boot |
| LUKS → Btrfs | Remaining | btrfs | / (with subvolumes) |

**Pros:** Full disk encryption **and** snapshots, only two partitions, no LVM layer
**Cons:** Passphrase at every boot

> 💡 **Recommended for:** laptops. You get the theft protection of encryption and the
> broken-update protection of snapshots, without stacking LVM underneath.

---

## Choosing Your Setup

### Decision Flowchart

```
Do you need disk encryption?
│
├── YES ─── Do you want snapshots / easy rollback?
│           ├── YES → Btrfs + Encryption   ⭐ (2 partitions, no LVM)
│           └── NO  → LVM + Encryption        (3 partitions)
│
└── NO ──── Do you want snapshots / easy rollback?
            ├── YES → Btrfs                ⭐
            └── NO  ── Do you need to resize volumes later?
                       ├── YES → LVM
                       └── NO ── Separate /home?
                                 ├── YES → Advanced (Standard)
                                 └── NO  → Basic
```

**The short version:** if you are unsure and this is a normal desktop or laptop, pick **Btrfs**
— the snapshots will save you from a bad update at least once. Add encryption if the machine
ever leaves your house.

### Recommendations by Use Case

| Use Case | Recommended Scheme | Guide |
|----------|-------------------|-------|
| First time Linux | Basic with Swap | [Basic Guide](basic-partitioning.md) |
| Daily desktop use | Btrfs ⭐ | [Btrfs Guide](btrfs-setup.md) |
| Want easy system rollback | Btrfs with Snapper | [Btrfs Guide](btrfs-setup.md) |
| Laptop with sensitive data | Btrfs + Encryption ⭐ | [Btrfs Encryption](btrfs-encryption.md) |
| Encrypted, prefer LVM volumes | LVM + Encryption | [LVM Encryption](lvm-encryption.md) |
| Server / Multi-disk | LVM | [LVM Guide](lvm-setup.md) |
| Dual boot with Windows | Basic or Standard | [Basic Guide](basic-partitioning.md) |

---

## Tools Overview

### cfdisk (Recommended for Beginners) ⭐

Text-based, menu-driven partition editor.

```bash
cfdisk /dev/sdX
```

**Features:**
- Visual interface
- Easy to use
- Supports GPT and MBR

---

### fdisk

Traditional command-line partition editor.

```bash
fdisk /dev/sdX
```

**Common commands:**
| Key | Action |
|-----|--------|
| `m` | Help menu |
| `g` | Create new GPT table |
| `n` | New partition |
| `d` | Delete partition |
| `t` | Change partition type |
| `p` | Print partition table |
| `w` | Write changes and exit |
| `q` | Quit without saving |

---

### gdisk

GPT-specific partition editor (recommended for GPT).

```bash
gdisk /dev/sdX
```

**Advantages:**
- GPT-focused
- Better GPT handling than fdisk
- Supports GPT backup/recovery

---

### parted

GNU partition editor with scripting support.

```bash
parted /dev/sdX
```

**Features:**
- Resize partitions
- Scripting support
- Supports GPT and MBR

---

## Filesystem Types

| Filesystem | Best For | Features |
|------------|----------|----------|
| **ext4** | Simplicity | Stable, fast, journaling, mature |
| **btrfs** | Modern desktops | Snapshots, compression (zstd), subvolumes, CoW |
| **xfs** | Large files/servers | High performance, scalable, no shrinking |
| **FAT32** | EFI partition | Required for UEFI boot |
| **swap** | Swap partition | Virtual memory |

### Btrfs vs ext4

| Feature | ext4 | Btrfs |
|---------|------|-------|
| Stability | ⭐⭐⭐ Very stable | ⭐⭐ Stable (improved) |
| Snapshots | ❌ No | ✅ Built-in |
| Compression | ❌ No | ✅ zstd, lzo, zlib |
| Subvolumes | ❌ No | ✅ Yes |
| Easy rollback | ❌ No | ✅ With Snapper |
| Mature | ⭐⭐⭐ Decades | ⭐⭐ ~15 years |

> 💡 **Recommendation:** For new installs, **Btrfs** is recommended for the snapshot capability alone - it can save you from broken updates!

---

## Next Steps — Pick Your Flow

**This is where the guide splits.** Up to now every path was identical. From here you follow one
flow straight through to a working system, and you can ignore the other four entirely.

| Your choice | Then | Then |
|-------------|------|------|
| **[Basic Partitioning](basic-partitioning.md)**<br>Simple ext4, easiest | [Base Installation — Standard](../03-base-installation/base-install-standard.md) | [GRUB](../03-base-installation/bootloader-standard.md) |
| **[Advanced Partitioning](advanced-partitioning.md)**<br>ext4 with separate `/home` | [Base Installation — Standard](../03-base-installation/base-install-standard.md) | [GRUB](../03-base-installation/bootloader-standard.md) |
| **[Btrfs Setup](btrfs-setup.md)** ⭐<br>Snapshots and compression | [Base Installation — Btrfs](../03-base-installation/base-install-btrfs.md) | [GRUB for Btrfs](../03-base-installation/bootloader-btrfs.md) |
| **[Btrfs + Encryption](btrfs-encryption.md)** ⭐<br>Snapshots **and** encryption | [Base Installation — Btrfs + LUKS](../03-base-installation/base-install-btrfs-luks.md) | [GRUB for Btrfs + LUKS](../03-base-installation/bootloader-btrfs-luks.md) |
| **[LVM Setup](lvm-setup.md)**<br>Resizable volumes | [Base Installation — LVM](../03-base-installation/base-install-lvm.md) | [GRUB for LVM](../03-base-installation/bootloader-lvm.md) |
| **[LVM + Encryption](lvm-encryption.md)**<br>Encryption with LVM volumes | [Base Installation — LUKS + LVM](../03-base-installation/base-install-encrypted.md) | [GRUB for LUKS + LVM](../03-base-installation/bootloader-encrypted.md) |

All six flows then rejoin at **[First Boot](../04-post-installation/first-boot.md)**.

> **Still unsure?** Take **Btrfs** for a desktop, or **Btrfs + Encryption** for a laptop. The
> snapshots will rescue you from a bad update at some point, and you do not need LVM to get them.
> Take **Basic** if you want the shortest path and can reinstall if something goes wrong.

> ⚠️ **Follow one flow only.** Each is complete on its own, and mixing steps between them is the
> most reliable way to end up with a system that will not boot.

---

<div align="center">

[← Live Environment](../01-pre-installation/live-environment.md) | [Back to Main Guide](../../README.md) | [Next: pick a flow above ↑](#next-steps--pick-your-flow)

</div>
