# Install Path Verification

Boots every documented install path in a VM and proves it reaches a login prompt.

This exists because the guide once shipped four paths that all failed: `base` contains no
editor, so `vim /etc/hosts` was `command not found`; the AMD and NVIDIA driver commands
referenced packages that no longer exist; and the encrypted path never installed `cryptsetup`,
so `mkinitcpio` produced an initramfs that could not unlock the disk. Every one of those is
invisible when you only read the docs. All of them fail this test suite immediately.

## Usage

```bash
./run-path.sh standard        # one path
./run-path.sh --all           # all five (~60-75 min)
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `ARCH_ISO` | auto-download | Use an ISO you already have |
| `DISK_SIZE` | `40G` | Virtual disk size (sparse — real usage is ~6GB) |
| `MEMORY` | `4096` | Guest RAM for the install pass |
| `INSTALL_TIMEOUT` | `2400` | Seconds for pass 1 |
| `BOOT_TIMEOUT` | `300` | Seconds for pass 2 |

Requires `qemu-base`, `edk2-ovmf`, `libarchive`, `python`, `curl`. KVM is used when
`/dev/kvm` is writable; without it, it falls back to TCG emulation and takes far longer.

## How it works

**Pass 1 — install.** The Arch ISO's kernel and initramfs are extracted with `bsdtar` (no
loop-mount, no root needed) and booted directly via QEMU's `-kernel`/`-initrd`. The archiso
`script=` boot parameter points at a small HTTP server on the host, which QEMU's user-mode
networking exposes to the guest as `10.0.2.2`. The payload runs unattended against a blank
qcow2, prints `ARCHTEST: INSTALL COMPLETE`, and powers off.

**Pass 2 — boot.** The disk is booted again with no ISO attached. `lib/boot-check.py` watches
the serial console, sends the LUKS passphrase when an encrypted path prompts for one, and exits
0 only on reaching a login prompt. A kernel panic, emergency shell, or timeout fails the run.

```
scripts/test/
├── run-path.sh              orchestrator
├── lib/
│   ├── common.sh            shared install steps — mirrors base-install-common.md
│   └── boot-check.py        pass 2: serial watcher + LUKS passphrase
└── payloads/
    ├── standard.sh          ├── btrfs.sh
    ├── lvm.sh               └── btrfs-luks.sh
    └── luks-lvm.sh
```

## Keeping payloads honest

**A payload that drifts from the guide tests nothing.** Each one starts with a `MIRRORS:` header
naming the exact documents it reproduces:

```bash
# PATH: Btrfs + LUKS
# MIRRORS: docs/02-partitioning/btrfs-encryption.md
#          docs/03-base-installation/base-install-common.md   (Btrfs + LUKS row)
#          ...
```

If you change a command in one of those documents, change the payload in the same commit. When
reviewing, check that every `pacman -S`, every `HOOKS=` line, and every mount option matches
the document it claims to mirror.

Two deliberate differences, both marked in the code:

- **Partitioning is scripted with `sgdisk`** rather than interactive `cfdisk`/`gdisk`. The
  resulting partition table is identical; only the means of creating it differs.
- **`console=ttyS0,115200` is added to the kernel cmdline** so pass 2 can watch the boot on a
  serial port. This is test-only and must not be copied into the guide.

## Beyond these tests

The VMs are UEFI + virtio only. They will not catch:

- Real GPU driver problems — `nvidia-open-dkms` and the `kms` hook do not reproduce here
- Firmware quirks, Secure Boot, vendor-specific UEFI behaviour
- Wi-Fi, Bluetooth, suspend/resume, hibernation

Before trusting a change to a driver or firmware section, install on real hardware.
