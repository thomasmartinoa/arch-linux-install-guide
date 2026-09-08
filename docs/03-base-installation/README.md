# Base System Installation

> Six flows. Follow **one**, top to bottom.

Each guide below is complete on its own. It contains every command for that layout — no tables to
pick from, no cross-references to other paths, nothing to skip.

## Find your guide

You get here from [Partitioning](../02-partitioning/). Use the row matching what you did:

| You partitioned with | Install guide | Then bootloader |
|----------------------|---------------|-----------------|
| [Basic Partitioning](../02-partitioning/basic-partitioning.md) | [Standard](base-install-standard.md) | [GRUB](bootloader-standard.md) |
| [Advanced Partitioning](../02-partitioning/advanced-partitioning.md) | [Standard](base-install-standard.md) | [GRUB](bootloader-standard.md) |
| [Btrfs Setup](../02-partitioning/btrfs-setup.md) | [Btrfs](base-install-btrfs.md) | [GRUB for Btrfs](bootloader-btrfs.md) |
| [Btrfs + Encryption](../02-partitioning/btrfs-encryption.md) | [Btrfs + LUKS](base-install-btrfs-luks.md) | [GRUB for Btrfs + LUKS](bootloader-btrfs-luks.md) |
| [LVM Setup](../02-partitioning/lvm-setup.md) | [LVM](base-install-lvm.md) | [GRUB for LVM](bootloader-lvm.md) |
| [LVM + Encryption](../02-partitioning/lvm-encryption.md) | [LUKS + LVM](base-install-encrypted.md) | [GRUB for LUKS + LVM](bootloader-encrypted.md) |

All flows rejoin at [First Boot](../04-post-installation/first-boot.md).

---

## What every flow covers

The ten steps are the same shape everywhere; what differs is which packages you install and how
the initramfs reaches your root filesystem.

```
1. Verify mounts          6. Install packages
2. Install base system    7. Kernel + microcode
3. Generate fstab         8. GPU drivers
4. Enter chroot           9. Build the initramfs
5. Configure system      10. Enable services
                              │
                              ▼
                          Bootloader → reboot → First Boot
```

---

## Where the flows actually differ

You do not need this table to follow a guide — each one already has the right commands baked in.
It is here if you are curious, or comparing before you choose.

| Flow | Extra packages | initramfs HOOKS | ESP mounted at |
|------|----------------|-----------------|----------------|
| Standard | — | unchanged | `/boot` |
| Btrfs | `btrfs-progs` | unchanged | `/boot` |
| LVM | `lvm2` | `+ lvm2` | `/boot` |
| Btrfs + LUKS | `btrfs-progs cryptsetup` | `+ encrypt` | `/boot` |
| LUKS + LVM | `lvm2 cryptsetup` | `+ encrypt lvm2` | `/efi` |

---

## Two mistakes that stop a system booting

Both are silent during install and fatal on reboot. Each flow warns you at the right moment, but
they are worth knowing in advance.

**Encrypted flows must install `cryptsetup`.** The `encrypt` hook copies that binary into your
initramfs. Without the package, `mkinitcpio` fails and nothing can ever unlock the disk.

**Btrfs flows must install `btrfs-progs`.** Your root filesystem is Btrfs; without the tools the
system cannot mount its own root.

---

## Choosing a bootloader

Every flow uses **GRUB**, which works with all six layouts.

[systemd-boot](bootloader-systemd.md) is a smaller, faster alternative for the unencrypted
Standard and Btrfs flows. It cannot prompt for a LUKS passphrase with the `encrypt` hook setup
used here, so encrypted flows should stay on GRUB.

---

<div align="center">

[← Partitioning](../02-partitioning/) | [Back to Main Guide](../../README.md) | [Next: First Boot →](../04-post-installation/first-boot.md)

</div>
