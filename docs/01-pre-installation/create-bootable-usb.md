# Creating a Bootable USB Drive

> Multiple ways to create an Arch Linux installation USB.

## Table of Contents

- [Download Arch Linux ISO](#download-arch-linux-iso)
- [Verify the ISO](#verify-the-iso-optional-but-recommended)
- [Creating the USB](#creating-the-usb)
  - [Windows Methods](#windows)
  - [Linux Methods](#linux)
  - [macOS Methods](#macos)
- [Troubleshooting](#troubleshooting)

---

## Download Arch Linux ISO

### Official Download

1. Go to **[archlinux.org/download](https://archlinux.org/download/)**
2. Pick a mirror close to you
3. Download the ISO (about 800MB-1GB)

### File naming:
```
archlinux-YYYY.MM.DD-x86_64.iso
```
Example: `archlinux-2024.11.01-x86_64.iso`

> **Tip:** Always download from official sources.

---

## Verify the ISO (Optional but Recommended)

Verifying makes sure your download isn't corrupted.

### On Windows (PowerShell):

```powershell
# Navigate to download folder
cd ~/Downloads

# Calculate SHA256 hash
Get-FileHash archlinux-*.iso -Algorithm SHA256
```

### On Linux:

```bash
# Calculate SHA256 hash
sha256sum archlinux-*.iso
```

Compare the output with the checksum on the download page.

---

## Creating the USB

Pick your OS:

---

### Windows

#### Method 1: Rufus (Recommended)

**Rufus** is the most reliable tool for this.

1. **Download Rufus:** [rufus.ie](https://rufus.ie/)
2. **Insert your USB** (8GB+)
3. **Run Rufus** (portable, no install)
4. **Settings:**

| Setting | Value |
|---------|-------|
| Device | Your USB drive |
| Boot selection | The Arch ISO |
| Partition scheme | **GPT** |
| Target system | **UEFI (non CSM)** |
| File system | FAT32 (Large) or ISO default |
| Cluster size | Default |

5. Click **START**
6. Select **Write in ISO Image mode** if asked
7. Wait 2-5 minutes

![Rufus Settings](../../images/rufus-settings.png)

> **Warning:** This erases everything on the USB!

---

#### Method 2: Ventoy (Multi-ISO USB)

**Ventoy** lets you have multiple ISOs on one USB.

1. **Download Ventoy:** [ventoy.net](https://www.ventoy.net/)
2. **Extract and run** Ventoy2Disk.exe
3. **Select your USB** and click **Install**
4. **Copy the Arch ISO** directly to the USB
5. Boot and select Arch Linux from the Ventoy menu

**Why Ventoy?**
- Multiple ISOs on one drive
- No reformatting needed
- Just drag and drop ISOs

---

#### Method 3: balenaEtcher

Simple and works everywhere.

1. **Download:** [balena.io/etcher](https://www.balena.io/etcher/)
2. Select **Flash from file** → Choose Arch ISO
3. Select **Target** → Choose USB drive
4. Click **Flash!**

---

### Linux

#### Method 1: dd Command (Recommended)

The `dd` command writes the ISO directly to the USB.

```bash
# First, identify your USB drive
lsblk

# Look for your USB drive (e.g., /dev/sdb)
# Make sure to identify the correct drive!

# Unmount the drive if mounted
sudo umount /dev/sdX*

# Write the ISO (replace X with your drive letter)
sudo dd bs=4M if=archlinux-*.iso of=/dev/sdX status=progress oflag=sync
```

**What each part does:**

| Parameter | Meaning |
|-----------|---------||
| `bs=4M` | Block size of 4 megabytes (faster writing) |
| `if=` | Input file (the ISO) |
| `of=` | Output file (your USB drive, NOT a partition) |
| `status=progress` | Show writing progress |
| `oflag=sync` | Synchronous writing (safer) |

> **CRITICAL:** Use `/dev/sdX` (whole drive), not `/dev/sdX1` (partition). Double-check the drive letter - `dd` can nuke data if you point it at the wrong drive!

---

#### Method 2: Using cp (Simpler)

```bash
# Identify USB drive
lsblk

# Write ISO using cp
sudo cp archlinux-*.iso /dev/sdX
sudo sync
```

---

#### Method 3: Using Ventoy

```bash
# Download and extract Ventoy
wget https://github.com/ventoy/Ventoy/releases/download/v1.x.x/ventoy-x.x.x-linux.tar.gz
tar -xzf ventoy-*.tar.gz
cd ventoy-*

# Install to USB drive
sudo ./Ventoy2Disk.sh -i /dev/sdX

# Mount and copy ISO
sudo mount /dev/sdX1 /mnt
sudo cp archlinux-*.iso /mnt/
sudo umount /mnt
```

---

### macOS

#### Method 1: dd Command

```bash
# List disks
diskutil list

# Find your USB drive (e.g., /dev/disk2)

# Unmount the drive
diskutil unmountDisk /dev/diskN

# Write ISO (use 'rdisk' for faster writing)
sudo dd if=archlinux-*.iso of=/dev/rdiskN bs=4m status=progress

# Eject when done
diskutil eject /dev/diskN
```

> **Tip:** Use `/dev/rdiskN` (raw disk) instead of `/dev/diskN` for faster writing.

---

#### Method 2: balenaEtcher

Same as Windows - download from [balena.io/etcher](https://www.balena.io/etcher/)

---

## Verify USB Creation

After creating the USB:

1. **Safely eject** the USB drive
2. **Reinsert** it
3. **Check contents** - you should see:
   - `arch/`
   - `EFI/`
   - `loader/`
   - `shellx64.efi`

If you see these files, you're good!

---

## Troubleshooting

### "USB not bootable"

- Make sure you wrote to the drive (`/dev/sdX`), not a partition (`/dev/sdX1`)
- Try using Rufus with "Write in DD Image mode"
- Recreate the USB with a different tool

### "Invalid signature" or "Security violation"

- Disable Secure Boot in BIOS
- See [BIOS Settings](bios-settings.md)

### USB drive not recognized in BIOS

- Try a USB 2.0 port instead of USB 3.0
- Disable Fast Boot in BIOS
- Try a different USB drive

### Write speed very slow

- Use a USB 3.0 drive in a USB 3.0 port
- On macOS, use `/dev/rdiskN` instead of `/dev/diskN`
- Increase block size: `bs=8M` or `bs=16M`

---

## Understanding the Process

### What happens when you create a bootable USB?

1. **ISO Image:** The Arch Linux ISO contains:
   - Linux kernel
   - Initial RAM filesystem
   - Installation tools
   - Live environment

2. **Writing Process:** Tools like `dd` or Rufus write this image byte-by-byte to the USB.

3. **UEFI Boot:** The USB contains an EFI partition that UEFI firmware can recognize and boot from.

---

## Next Steps

Your bootable USB is ready!

→ [Live Environment Setup](live-environment.md)

---

<div align="center">

[← BIOS Settings](bios-settings.md) | [Back to Main Guide](../../README.md) | [Next: Live Environment →](live-environment.md)

</div>
