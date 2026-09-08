# Arch Linux Installation Guide

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)

> My Arch Linux installation guide with actual explanations for each command.

![Arch Linux Banner](images/arch-banner.png)

##  Table of Contents

1. [Introduction](#-introduction)
2. [Prerequisites](#prerequisites)
3. [How This Guide Works](#how-this-guide-works)
4. [Step 1: Everyone Starts Here](#step-1-everyone-starts-here)
5. [Step 2: Choose Your Flow](#step-2-choose-your-flow)
6. [Step 3: Everyone Finishes Here](#step-3-everyone-finishes-here)
7. [Partitioning Options](#partitioning-options)
8. [Bootloader Options](#bootloader-options)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)

---

## 🎯 Introduction

This is how I install Arch Linux. Unlike most guides that just dump commands at you, I actually explain what each one does. Should work for beginners and people who already know their way around Linux.

---

## Prerequisites

You'll need:

- [ ] A computer with UEFI (most modern PCs)
- [ ] USB drive (8GB or bigger)
- [ ] Internet connection (wired is easier, WiFi works too)
- [ ] Backup your data first
- [ ] Some basic terminal knowledge

---

## How This Guide Works

Everyone starts the same way. At **partitioning** the guide splits into six flows, and from there
you follow **one** flow straight through — no branching, no tables to pick from, nothing to skip.

```
   ┌──────────────────────────────────────────┐
   │  1. BIOS Settings                        │
   │  2. Create Bootable USB     everyone      │
   │  3. Live Environment                     │
   │  4. Partition Overview  ← choose here    │
   └────────────────┬─────────────────────────┘
                    │
   ┌────────────────┴─────────────────────────┐
   │  Basic  Advanced  Btrfs  Btrfs+LUKS      │
   │              LVM   LUKS+LVM               │
   │                                          │
   │  each flow:  partition → install → boot  │
   └────────────────┬─────────────────────────┘
                    │
   ┌────────────────┴─────────────────────────┐
   │  First Boot → Drivers → Audio            │
   │  → Desktop → Software      everyone       │
   └──────────────────────────────────────────┘
```

---

## Step 1: Everyone Starts Here

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md) — enable UEFI, disable Secure Boot
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md) — boot the USB, get online
4. [Partition Overview](docs/02-partitioning/partition-overview.md) — **understand your options and choose**

---

## Step 2: Choose Your Flow

| | Flow | Encrypted | Snapshots | Difficulty | Best for |
|---|------|-----------|-----------|------------|----------|
| 1 | **[Basic](#flow-1--basic-ext4)** | ❌ | ❌ | ⭐ | First install, dual boot |
| 2 | **[Advanced](#flow-2--advanced-ext4--separate-home)** | ❌ | ❌ | ⭐⭐ | Keeping `/home` across reinstalls |
| 3 | **[Btrfs](#flow-3--btrfs)** ⭐ | ❌ | ✅ | ⭐⭐ | Most desktops |
| 4 | **[Btrfs + Encryption](#flow-4--btrfs--encryption)** ⭐ | ✅ | ✅ | ⭐⭐⭐ | Laptops |
| 5 | **[LVM](#flow-5--lvm)** | ❌ | ⚠️ | ⭐⭐⭐ | Resizable volumes, servers |
| 6 | **[LUKS + LVM](#flow-6--luks--lvm)** | ✅ | ⚠️ | ⭐⭐⭐⭐ | Encryption with LVM volumes |

**Unsure?** Flow 3 for a desktop, flow 4 for a laptop. Snapshots will save you from a bad update
at some point, and Btrfs gives you them without LVM underneath. Flow 1 if you want the shortest
path and can reinstall if something goes wrong.

---

### Flow 1 — Basic (ext4)

Simplest layout: ESP, root, swap.

1. [Basic Partitioning](docs/02-partitioning/basic-partitioning.md)
2. [Base Installation — Standard](docs/03-base-installation/base-install-standard.md)
3. [GRUB Bootloader](docs/03-base-installation/bootloader-standard.md)

### Flow 2 — Advanced (ext4 + separate /home)

Same as flow 1, but `/home` survives a reinstall.

1. [Advanced Partitioning](docs/02-partitioning/advanced-partitioning.md)
2. [Base Installation — Standard](docs/03-base-installation/base-install-standard.md)
3. [GRUB Bootloader](docs/03-base-installation/bootloader-standard.md)

### Flow 3 — Btrfs

Subvolumes, transparent compression, and snapshots you can roll back to.

1. [Btrfs Setup](docs/02-partitioning/btrfs-setup.md)
2. [Base Installation — Btrfs](docs/03-base-installation/base-install-btrfs.md)
3. [GRUB for Btrfs](docs/03-base-installation/bootloader-btrfs.md)

### Flow 4 — Btrfs + Encryption

Everything in flow 3, inside a LUKS container. Two partitions, no LVM.

1. [Btrfs with Encryption](docs/02-partitioning/btrfs-encryption.md)
2. [Base Installation — Btrfs + LUKS](docs/03-base-installation/base-install-btrfs-luks.md)
3. [GRUB for Btrfs + LUKS](docs/03-base-installation/bootloader-btrfs-luks.md)

### Flow 5 — LVM

Logical volumes you can grow and shrink after install.

1. [LVM Setup](docs/02-partitioning/lvm-setup.md)
2. [Base Installation — LVM](docs/03-base-installation/base-install-lvm.md)
3. [GRUB for LVM](docs/03-base-installation/bootloader-lvm.md)

### Flow 6 — LUKS + LVM

Full disk encryption with LVM volumes inside the container.

1. [LVM with Encryption](docs/02-partitioning/lvm-encryption.md)
2. [Base Installation — LUKS + LVM](docs/03-base-installation/base-install-encrypted.md)
3. [GRUB for LUKS + LVM](docs/03-base-installation/bootloader-encrypted.md)

---

## Step 3: Everyone Finishes Here

Once you have a login prompt, all flows rejoin:

1. [First Boot](docs/04-post-installation/first-boot.md) — network, mirrors, first update
2. [Drivers](docs/04-post-installation/drivers.md) — GPU and hardware
3. [Audio & Bluetooth](docs/04-post-installation/audio-bluetooth.md)
4. [Choose a Desktop Environment](docs/05-desktop-environments/de-overview.md)
5. [Essential Software](docs/06-essential-software/essential-packages.md) · [AUR Helpers](docs/06-essential-software/aur-helpers.md)
6. Optional: [Security](docs/07-optimization/security.md) · [Performance](docs/07-optimization/performance-tweaks.md) · [Maintenance](docs/07-optimization/maintenance.md)

---

## Two Things That Will Stop You Booting

Each flow warns you at the right moment, but they are worth knowing in advance.

**Encrypted flows (4 and 6) must install `cryptsetup`.** The `encrypt` hook copies that binary
into your initramfs. Without the package, `mkinitcpio` fails and the disk can never be unlocked.

**Btrfs flows (3 and 4) must install `btrfs-progs`.** Your root filesystem is Btrfs; without the
tools the system cannot mount its own root.

---

## Partitioning Options

| Method | Difficulty | Snapshots | Use case |
|--------|------------|-----------|----------|
| [Basic](docs/02-partitioning/basic-partitioning.md) | ⭐ Easy | ❌ | Simple setup, dual boot |
| [Advanced](docs/02-partitioning/advanced-partitioning.md) | ⭐⭐ Medium | ❌ | Separate `/home` |
| [Btrfs](docs/02-partitioning/btrfs-setup.md) ⭐ | ⭐⭐ Medium | ✅ Native | Modern desktops |
| [Btrfs + Encryption](docs/02-partitioning/btrfs-encryption.md) ⭐ | ⭐⭐⭐ Advanced | ✅ Native | Laptops |
| [LVM](docs/02-partitioning/lvm-setup.md) | ⭐⭐⭐ Advanced | ⚠️ LVM | Resizable volumes |
| [LVM + Encryption](docs/02-partitioning/lvm-encryption.md) | ⭐⭐⭐⭐ Expert | ⚠️ LVM | Encryption with LVM |

See [Partition Overview](docs/02-partitioning/partition-overview.md) for diagrams of each layout.

---

## Bootloader Options

Every flow uses **GRUB**, and each flow has its own bootloader guide with the right commands
already in it — you do not choose from this table, your flow picks for you.

| Flow | Bootloader guide |
|------|------------------|
| Basic / Advanced | [GRUB — Standard](docs/03-base-installation/bootloader-standard.md) |
| Btrfs | [GRUB for Btrfs](docs/03-base-installation/bootloader-btrfs.md) |
| Btrfs + Encryption | [GRUB for Btrfs + LUKS](docs/03-base-installation/bootloader-btrfs-luks.md) |
| LVM | [GRUB for LVM](docs/03-base-installation/bootloader-lvm.md) |
| LUKS + LVM | [GRUB for LUKS + LVM](docs/03-base-installation/bootloader-encrypted.md) |

**[systemd-boot](docs/03-base-installation/bootloader-systemd.md)** is a smaller, faster
alternative for the unencrypted Basic, Advanced and Btrfs flows.

> 💡 systemd-boot cannot prompt for a LUKS passphrase with the `encrypt` hook setup this guide
> uses. Encrypted flows should stay on GRUB.

---

## 🔧 Post-Installation

### Essential Steps
| Step | Description |
|------|-------------|
| [First Boot](docs/04-post-installation/first-boot.md) | Initial setup after installation |
| [Drivers](docs/04-post-installation/drivers.md) | GPU, WiFi, and hardware drivers |
| [Audio & Bluetooth](docs/04-post-installation/audio-bluetooth.md) | PipeWire setup |
| [Essential Packages](docs/06-essential-software/essential-packages.md) | Must-have software |
| [AUR Helpers](docs/06-essential-software/aur-helpers.md) | Install yay or paru |

### Desktop Environments
| DE | Style | RAM Usage | Link |
|----|-------|-----------|------|
| GNOME | Modern | ~800MB | [Guide](docs/05-desktop-environments/gnome.md) |
| KDE Plasma | Feature-rich | ~600MB | [Guide](docs/05-desktop-environments/kde-plasma.md) |
| Xfce | Lightweight | ~400MB | [Guide](docs/05-desktop-environments/xfce.md) |
| Hyprland | Tiling WM | ~300MB | [Guide](docs/05-desktop-environments/hyprland.md) |

### Optimization & Security
| Topic | Description |
|-------|-------------|
| [Security Hardening](docs/07-optimization/security.md) | Firewall, SSH, Fail2ban, AppArmor |
| [Performance Tweaks](docs/07-optimization/performance-tweaks.md) | SSD, swap, kernel optimization |
| [System Maintenance](docs/07-optimization/maintenance.md) | Updates, cleaning, backups |

---

## System Migration

Got a new PC? Don't start from scratch - just migrate your setup!

| Guide | What It Does |
|-------|-------------|
| [System Migration Guide](docs/07-optimization/system-migration.md) | Export everything and restore it on your new machine |

**What you can bring over:**
- All your packages (official repos + AUR)
- Dotfiles and configs (with Stow or Git)
- System settings from /etc
- Enabled services
- Your scripts and tweaks

Basically, you export a list of what you've got, copy your configs, then reinstall everything on the new PC. Way easier than remembering what you installed.

---

## Troubleshooting

Run into problems? Here's where to look:

| Issue | Common Causes | Guide |
|-------|---------------|-------|
|  Boot Problems | GRUB errors, kernel panic | [Boot Troubleshooting](docs/08-troubleshooting/boot-problems.md) |
|  Network Issues | WiFi not working, no internet | [Network Troubleshooting](docs/08-troubleshooting/network-issues.md) |
|  Driver Problems | GPU issues, hardware not detected | [Driver Troubleshooting](docs/08-troubleshooting/driver-problems.md) |
| 🔊 Audio Issues | No sound, Bluetooth audio | [Audio Troubleshooting](docs/08-troubleshooting/audio-issues.md) |
|  System Recovery | Broken packages, chroot rescue | [System Recovery](docs/08-troubleshooting/system-recovery.md) |

>  See the full [Troubleshooting Index](docs/08-troubleshooting/README.md) for more help.

---

##  Additional Resources

- [Arch Wiki](https://wiki.archlinux.org/) - The ultimate Arch Linux resource
- [Arch Linux Forums](https://bbs.archlinux.org/) - Community support
- [r/archlinux](https://www.reddit.com/r/archlinux/) - Reddit community

###  Advanced Guides

- [**CachyOS Kernel on Arch**](https://github.com/thomasmartinoa/cachyos-kernel_on_arch) - Install the performance-optimized CachyOS kernel (better gaming & responsiveness)

---

##  Contributing

Found a mistake or want to add something?

1. Fork this repo
2. Make your changes
3. Open a pull request

Pretty standard stuff.

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

</div>
