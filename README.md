# Arch Linux Installation Guide

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)

> My Arch Linux installation guide with actual explanations for each command.

![Arch Linux Banner](images/arch-banner.png)

## 📋 Table of Contents

1. [Introduction](#-introduction)
2. [Prerequisites](#-prerequisites)
3. [Quick Navigation](#-quick-navigation)
4. [Partitioning Options](#-partitioning-options)
5. [Bootloader Options](#-bootloader-options)
6. [Post-Installation](#-post-installation)
7. [Troubleshooting](#-troubleshooting)
8. [Contributing](#-contributing)

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

## Quick Navigation

### For Beginners (Standard Path)

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md)
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md)
4. [Basic Partitioning](docs/02-partitioning/basic-partitioning.md)
5. [Standard Base Installation](docs/03-base-installation/base-install-standard.md)
6. [Standard Bootloader](docs/03-base-installation/bootloader-standard.md)
7. [First Boot](docs/04-post-installation/first-boot.md)
8. [Choose a Desktop Environment](docs/05-desktop-environments/de-overview.md)

### For LVM Users (Flexible Partitioning)

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md)
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md)
4. [LVM Setup](docs/02-partitioning/lvm-setup.md)
5. [LVM Base Installation](docs/03-base-installation/base-install-lvm.md)
6. [LVM Bootloader](docs/03-base-installation/bootloader-lvm.md)
7. [First Boot](docs/04-post-installation/first-boot.md)

### For Security-Focused Users (Encrypted)

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md)
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md)
4. [LVM with Encryption](docs/02-partitioning/lvm-encryption.md)
5. [Encrypted Base Installation](docs/03-base-installation/base-install-encrypted.md)
6. [Encrypted Bootloader](docs/03-base-installation/bootloader-encrypted.md)
7. [First Boot](docs/04-post-installation/first-boot.md)
8. [Security Hardening](docs/07-optimization/security.md)

### For Modern Filesystem Users (Btrfs)

1. [BIOS Settings](docs/01-pre-installation/bios-settings.md)
2. [Create Bootable USB](docs/01-pre-installation/create-bootable-usb.md)
3. [Live Environment Setup](docs/01-pre-installation/live-environment.md)
4. [Btrfs Setup](docs/02-partitioning/btrfs-setup.md)
5. [Standard Base Installation](docs/03-base-installation/base-install-standard.md)
6. [systemd-boot Bootloader](docs/03-base-installation/bootloader-systemd.md)
7. [First Boot](docs/04-post-installation/first-boot.md)


---

## Partitioning Options

Choose your partitioning method based on your needs:

| Method | Difficulty | Use Case | Snapshots |
|--------|------------|----------|-----------|
| [Basic](docs/02-partitioning/basic-partitioning.md) | ⭐ Easy | Simple setup, dual boot | ❌ |
| [Advanced](docs/02-partitioning/advanced-partitioning.md) | ⭐⭐ Medium | Separate /home partition | ❌ |
| [Btrfs](docs/02-partitioning/btrfs-setup.md) | ⭐⭐ Medium | Modern CoW filesystem | ✅ |
| [LVM](docs/02-partitioning/lvm-setup.md) | ⭐⭐⭐ Advanced | Flexible partition management | ⚠️ |
| [LVM + Encryption](docs/02-partitioning/lvm-encryption.md) | ⭐⭐⭐⭐ Expert | Full disk encryption | ⚠️ |

---

## Bootloader Options

| Bootloader | Difficulty | Features | Best For |
|------------|------------|----------|----------|
| [GRUB (Standard)](docs/03-base-installation/bootloader-standard.md) | ⭐ Easy | Multi-boot, theming | Most users |
| [GRUB (Encrypted)](docs/03-base-installation/bootloader-encrypted.md) | ⭐⭐⭐ Advanced | LUKS support | Encrypted setups |
| [systemd-boot](docs/03-base-installation/bootloader-systemd.md) | ⭐⭐ Medium | Minimal, fast | UEFI-only, non-encrypted |

> 💡 **Note:** systemd-boot doesn't handle LUKS encryption well. Stick with GRUB if you're encrypting.

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

## 🤝 Contributing

Found a mistake or want to add something?

1. Fork this repo
2. Make your changes
3. Open a pull request

Pretty standard stuff.

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

</div>
