# Base System Installation

> Choose the guide that matches your partition setup.

## Choose Your Installation Guide

| Your Partition Method | Installation Guide |
|-----------------------|--------------------|
| [Basic Partitioning](../02-partitioning/basic-partitioning.md) | [Standard Installation](base-install-standard.md) |
| [Advanced Partitioning](../02-partitioning/advanced-partitioning.md) | [Standard Installation](base-install-standard.md) |
| [LVM Setup](../02-partitioning/lvm-setup.md) | [LVM Installation](base-install-lvm.md) |
| [LVM + Encryption](../02-partitioning/lvm-encryption.md) | [Encrypted Installation](base-install-encrypted.md) |

---

## Important

> **Don't mix guides!** Each installation guide is complete and self-contained. Follow only the one that matches your partitioning method.

---

## What Each Guide Covers

### Standard Installation
- For simple partition setups (EFI + Root + Swap)
- No special kernel hooks required
- Simplest bootloader configuration

### LVM Installation  
- For LVM without encryption
- Requires `lvm2` package and mkinitcpio hooks
- LVM bootloader configuration

### Encrypted Installation
- For LUKS encryption with LVM
- Requires `encrypt` and `lvm2` mkinitcpio hooks
- Encryption bootloader configuration with cryptdevice

---

<div align="center">

[← Partitioning](../02-partitioning/) | [Back to Main Guide](../../README.md) | [Next: Post-Installation →](../04-post-installation/)

</div>
