# Arch Linux Installation Guide

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)

> My Arch Linux installation guide with actual explanations for each command.

![Arch Linux Banner](images/arch-banner.png)

##  Table of Contents

1. [Introduction](#-introduction)
2. [Prerequisites](#prerequisites)
3. [Pick Your Path](#pick-your-path)
4. [Quick Navigation](#quick-navigation)
5. [Partitioning Options](#partitioning-options)
6. [Bootloader Options](#bootloader-options)
7. [Post-Installation](#-post-installation)
8. [Troubleshooting](#troubleshooting)
9. [Contributing](#contributing)

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

## Pick Your Path

Five paths. They differ only in how the disk is laid out — everything after partitioning is the
same guide.

| | Path | Encrypted | Snapshots | Difficulty | Best for |
|---|------|-----------|-----------|------------|----------|
| 1 | **Beginner — Standard** | ❌ | ❌ | ⭐ | Your first Arch install, dual boot |
| 2 | **LVM** | ❌ | ⚠️ LVM | ⭐⭐⭐ | Resizing volumes later, servers |
| 3 | **Encrypted — LUKS + LVM** | ✅ | ⚠️ LVM | ⭐⭐⭐⭐ | Encryption, with LVM volumes |
| 4 | **Modern — Btrfs** | ❌ | ✅ Native | ⭐⭐ | Most desktops ⭐ |
| 5 | **Encrypted + Snapshots — Btrfs + LUKS** | ✅ | ✅ Native | ⭐⭐⭐ | Laptops ⭐ |

**Not sure?** Take **4 (Btrfs)** for a desktop, or **5 (Btrfs + LUKS)** for anything that leaves
the house. Snapshots will rescue you from a bad update at some point, and Btrfs gives you them
without the extra LVM layer.

```
Need encryption?
│
├── YES ── Want snapshots? ── YES → 5. Btrfs + LUKS  ⭐
│                          └─ NO  → 3. LUKS + LVM
│
└── NO ─── Want snapshots? ── YES → 4. Btrfs  ⭐
                           └─ NO  ── Resize volumes later?
                                      ├── YES → 2. LVM
                                      └── NO  → 1. Standard
```

---

## Quick Navigation

Every path shares the same first three steps and the same tail. Only steps 4-6 differ.

**Everyone starts here:**

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md)
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md)

**Then your path — partition, install, boot:**

| Path | 4. Partition | 5. Install | 6. Bootloader |
|------|--------------|------------|---------------|
| **1. Standard** | [Basic](docs/02-partitioning/basic-partitioning.md) or [Advanced](docs/02-partitioning/advanced-partitioning.md) | [Base Install](docs/03-base-installation/base-install-common.md) → [notes](docs/03-base-installation/deltas/standard.md) | [GRUB](docs/03-base-installation/bootloader-standard.md) |
| **2. LVM** | [LVM Setup](docs/02-partitioning/lvm-setup.md) | [Base Install](docs/03-base-installation/base-install-common.md) → [notes](docs/03-base-installation/deltas/lvm.md) | [GRUB — LVM](docs/03-base-installation/bootloader-lvm.md) |
| **3. LUKS + LVM** | [LVM + Encryption](docs/02-partitioning/lvm-encryption.md) | [Base Install](docs/03-base-installation/base-install-common.md) → [notes](docs/03-base-installation/deltas/luks-lvm.md) | [GRUB — Encrypted](docs/03-base-installation/bootloader-encrypted.md) |
| **4. Btrfs** | [Btrfs Setup](docs/02-partitioning/btrfs-setup.md) | [Base Install](docs/03-base-installation/base-install-common.md) → [notes](docs/03-base-installation/deltas/btrfs.md) | [GRUB](docs/03-base-installation/bootloader-standard.md) or [systemd-boot](docs/03-base-installation/bootloader-systemd.md) |
| **5. Btrfs + LUKS** | [Btrfs + Encryption](docs/02-partitioning/btrfs-encryption.md) | [Base Install](docs/03-base-installation/base-install-common.md) → [notes](docs/03-base-installation/deltas/btrfs-luks.md) | [GRUB — Encrypted](docs/03-base-installation/bootloader-encrypted.md) |

**Then everyone finishes here:**

7. [First Boot](docs/04-post-installation/first-boot.md)
8. [Drivers](docs/04-post-installation/drivers.md)
9. [Audio & Bluetooth](docs/04-post-installation/audio-bluetooth.md)
10. [Choose a Desktop Environment](docs/05-desktop-environments/de-overview.md)
11. [Essential Software](docs/06-essential-software/essential-packages.md) · [AUR Helpers](docs/06-essential-software/aur-helpers.md)
12. Optional: [Security Hardening](docs/07-optimization/security.md) · [Performance](docs/07-optimization/performance-tweaks.md) · [Maintenance](docs/07-optimization/maintenance.md)

> **Why one install guide instead of five?** The installation steps are identical no matter how
> you partitioned. Only two things differ — which extra packages you install, and which
> mkinitcpio hooks you need — so the guide branches at exactly those two points and stays
> shared everywhere else.

---

## Two Things That Will Stop You Booting

Both are silent at install time and fatal on reboot, so they are worth knowing before you start.

**Encrypted paths (3 and 5) must install `cryptsetup`.** The `encrypt` initramfs hook copies the
`cryptsetup` binary into your initramfs. Without the package, `mkinitcpio` fails and the disk
can never be unlocked.

**Btrfs paths (4 and 5) must install `btrfs-progs`.** Your root filesystem is Btrfs; without the
tools the system cannot mount its own root.

Both are covered in the install guide — this is just so the warning lands twice.

---

## Partitioning Options

Choose your partitioning method based on your needs:

| Method | Difficulty | Use Case | Snapshots |
|--------|------------|----------|-----------|
| [Basic](docs/02-partitioning/basic-partitioning.md) | ⭐ Easy | Simple setup, dual boot | ❌ |
| [Advanced](docs/02-partitioning/advanced-partitioning.md) | ⭐⭐ Medium | Separate /home partition | ❌ |
| [Btrfs](docs/02-partitioning/btrfs-setup.md) | ⭐⭐ Medium | Modern CoW filesystem, snapshots | ✅ |
| [LVM](docs/02-partitioning/lvm-setup.md) | ⭐⭐⭐ Advanced | Flexible partition management | ⚠️ |
| [LVM + Encryption](docs/02-partitioning/lvm-encryption.md) | ⭐⭐⭐⭐ Expert | Full disk encryption | ⚠️ |
| [Btrfs + Encryption](docs/02-partitioning/btrfs-encryption.md) | ⭐⭐⭐ Advanced | Encryption **and** snapshots | ✅ |

---

## Bootloader Options

| Bootloader | Difficulty | Features | Best For |
|------------|------------|----------|----------|
| [GRUB (Standard)](docs/03-base-installation/bootloader-standard.md) | ⭐ Easy | Multi-boot, theming | Most users |
| [GRUB (Encrypted)](docs/03-base-installation/bootloader-encrypted.md) | ⭐⭐⭐ Advanced | LUKS support | Both encrypted paths |
| [systemd-boot](docs/03-base-installation/bootloader-systemd.md) | ⭐⭐ Medium | Minimal, fast | UEFI-only, non-encrypted |

> 💡 **Note:** systemd-boot has no built-in way to prompt for a LUKS passphrase with the
> `encrypt` hook setup this guide uses. Stick with GRUB if you're encrypting.

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
