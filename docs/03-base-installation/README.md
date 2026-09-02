# Base System Installation

> One installation flow, five paths through it.

## How this section works

The install steps are the same no matter how you partitioned — the same hostname, locale, user,
packages and services. Only two things differ: **which extra packages you install** and **which
mkinitcpio hooks you need**.

So there is one guide, with two clearly marked branch points:

```
        ┌──────────────────────────────┐
        │   base-install-common.md     │
        │                              │
        │   Steps 1-5   (identical)    │
        │   Step 6.2 ── branch 1 ──────┼──▶ extra packages for your path
        │   Steps 7-8   (identical)    │
        │   Step 9   ── branch 2 ──────┼──▶ mkinitcpio HOOKS for your path
        │   Step 10     (identical)    │
        └──────────────┬───────────────┘
                       ▼
                  bootloader
```

**→ Start here: [Base System Installation](base-install-common.md)**

---

## Your path at a glance

| Partitioning you did | Extra packages | HOOKS change | Path notes | Bootloader |
|---|---|---|---|---|
| [Basic](../02-partitioning/basic-partitioning.md) / [Advanced](../02-partitioning/advanced-partitioning.md) | — | none | [Standard](deltas/standard.md) | [GRUB](bootloader-standard.md) · [systemd-boot](bootloader-systemd.md) |
| [LVM](../02-partitioning/lvm-setup.md) | `lvm2` | `+lvm2` | [LVM](deltas/lvm.md) | [GRUB — LVM](bootloader-lvm.md) |
| [LVM + Encryption](../02-partitioning/lvm-encryption.md) | `lvm2 cryptsetup` | `+encrypt lvm2` | [LUKS + LVM](deltas/luks-lvm.md) | [GRUB — Encrypted](bootloader-encrypted.md) |
| [Btrfs](../02-partitioning/btrfs-setup.md) | `btrfs-progs` | none | [Btrfs](deltas/btrfs.md) | [GRUB](bootloader-standard.md) · [systemd-boot](bootloader-systemd.md) |
| [Btrfs + Encryption](../02-partitioning/btrfs-encryption.md) | `btrfs-progs cryptsetup` | `+encrypt` | [Btrfs + LUKS](deltas/btrfs-luks.md) | [GRUB — Encrypted](bootloader-encrypted.md) |

---

## Two things that will stop you booting

Both are silent at install time and fatal on reboot, so they are worth stating up front.

**Encrypted paths must install `cryptsetup`.** The `encrypt` initramfs hook copies the
`cryptsetup` binary into your initramfs. No package, no binary, no way to unlock the disk.

**Btrfs paths must install `btrfs-progs`.** Your root filesystem is Btrfs; without the tools the
system cannot mount its own root.

---

<div align="center">

[← Partitioning](../02-partitioning/) | [Back to Main Guide](../../README.md) | [Next: Base Installation →](base-install-common.md)

</div>
