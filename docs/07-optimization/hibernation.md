# Hibernation Setup

> Suspend-to-disk: save your whole session into swap, power off completely, and come back to
> exactly where you left off.

This guide applies **after** you have a booted, working system on any of the six flows. It
consolidates hibernation into one place instead of repeating it per flow — the only parts that
differ between flows are noted inline.

## Table of Contents

- [How Hibernation Works](#how-hibernation-works)
- [Step 1: Check Your Swap](#step-1-check-your-swap)
- [Step 2: Find Your Resume Parameters](#step-2-find-your-resume-parameters)
- [Step 3: Add the `resume` Hook](#step-3-add-the-resume-hook)
- [Step 4: Tell the Bootloader](#step-4-tell-the-bootloader)
- [Step 5: Test It](#step-5-test-it)
- [Troubleshooting](#troubleshooting)
- [Hibernate vs Suspend vs Hybrid Sleep](#hibernate-vs-suspend-vs-hybrid-sleep)
- [Hibernating on an Encrypted or TPM-Unlocked Disk](#hibernating-on-an-encrypted-or-tpm-unlocked-disk)

---

## How Hibernation Works

`systemctl hibernate` freezes every process, writes all of RAM into your swap space, and powers
the machine off. On the next boot, the kernel checks the `resume=` parameter you gave it *before*
mounting your normal root filesystem — if it finds a valid hibernation image in swap, it loads RAM
back from disk and continues exactly where it stopped, skipping the rest of the normal boot.

This is why hibernation needs two things a plain reboot does not:
- **Swap at least as large as your installed RAM** — the image has to fit.
- **The kernel told where to look** — a `resume=` parameter, and (if you hibernate to a file
  rather than a partition) a byte offset into that file.

---

## Step 1: Check Your Swap

```bash
free -h
swapon --show
```

Compare the `Mem:` total against your swap size. If swap is smaller than RAM, hibernation will
fail partway through — grow it before continuing. Sizing guidance is in the
[Partition Overview](../02-partitioning/partition-overview.md#swap-partitionfile).

You already created swap in whichever partitioning guide you followed:

| Flow | What you have | Where it was created |
|------|---------------|----------------------|
| Basic / Advanced | Swap **partition** | [Basic](../02-partitioning/basic-partitioning.md) / [Advanced](../02-partitioning/advanced-partitioning.md) Partitioning |
| Btrfs / Btrfs + Encryption | Swap **file** on the `@swap` subvolume | [Btrfs Setup](../02-partitioning/btrfs-setup.md#swap-file-setup) |
| LVM / LUKS + LVM | Swap **logical volume** | [LVM Setup](../02-partitioning/lvm-setup.md) / [LVM with Encryption](../02-partitioning/lvm-encryption.md) |

If you skipped swap entirely, add a swap file now — the "Create Swap File" steps in
[Performance Tweaks](performance-tweaks.md#quick-optimizations) still apply, just size it to at
least your RAM instead of the smaller figure suggested there for non-hibernating systems.

---

## Step 2: Find Your Resume Parameters

### Swap partition (Basic, Advanced, LVM, LUKS + LVM)

```bash
sudo blkid | grep swap
```

Note the `UUID=`. For LVM you can use the logical volume path instead, which never changes:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... resume=/dev/volgroup0/lv_swap"
```

### Swap file on ext4 (a plain swap file you created yourself)

```bash
sudo filefrag -v /swapfile | awk '$1=="0:" {print $4}'   # physical_offset, strip the trailing "."
sudo blkid | grep "$(findmnt -no SOURCE /)"               # UUID of the filesystem *holding* the file
```

You need **both** values — `resume=` takes the UUID of the filesystem the swap file lives on,
never the swap file's own UUID (a swap file has none), and `resume_offset=` takes the physical
block offset from `filefrag`.

### Swap file on Btrfs (Btrfs, Btrfs + Encryption)

```bash
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

That single command replaces `filefrag` — Btrfs's extent layout makes the generic offset
calculation unreliable, which is why `btrfs-progs` ships its own tool for this. Get the
filesystem UUID the same way:

```bash
sudo blkid /dev/mapper/cryptroot   # or your root device, if unencrypted
```

> ⚠️ **The offset changes** if the swap file is ever recreated, moved, or defragmented
> (`btrfs filesystem defragment` touches it too). Re-run `map-swapfile` and update
> `resume_offset=` whenever you do any of those, or hibernation will resume from garbage —
> typically a hang or a kernel panic, not a clean failure.

---

## Step 3: Add the `resume` Hook

```bash
sudo vim /etc/mkinitcpio.conf
```

`resume` goes right before `filesystems`, and **after** any hook that has to run first to make the
swap device reachable — `encrypt` (or `sd-encrypt`) if swap sits inside a LUKS container, `lvm2` if
it is a logical volume:

| Flow | HOOKS line |
|------|------------|
| Basic / Advanced | `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block **resume** filesystems fsck)` |
| Btrfs | `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block **resume** filesystems fsck)` |
| Btrfs + Encryption | `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt **resume** filesystems fsck)` |
| LVM | `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 **resume** filesystems fsck)` |
| LUKS + LVM | `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 **resume** filesystems fsck)` |

(Ignore the `**`, they're just marking what changed against the HOOKS line your base-install
guide gave you — write the plain word `resume`.)

```bash
sudo mkinitcpio -P
```

> ⚠️ **`resume` after `fsck` does nothing.** By the time `fsck` runs, the kernel has already
> decided there is no hibernation image to resume from. Order matters, not just presence.

---

## Step 4: Tell the Bootloader

### GRUB

```bash
sudo vim /etc/default/grub
```

Unencrypted flows — add to `GRUB_CMDLINE_LINUX_DEFAULT` (safe here, since there's no LUKS
passphrase parameter that needs to reach the recovery entries too):

```bash
# Swap partition or LV
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet resume=UUID=<swap-uuid>"

# Swap file
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet resume=UUID=<root-fs-uuid> resume_offset=<offset>"
```

Encrypted flows already have `cryptdevice=` in `GRUB_CMDLINE_LINUX` (not `_DEFAULT` — see the
warning in your flow's GRUB guide about why). Add `resume=` to that **same** line, right after it:

```bash
# Btrfs + Encryption
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptroot resume=UUID=<btrfs-fs-uuid> resume_offset=<offset>"

# LUKS + LVM
GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:cryptlvm resume=/dev/volgroup0/lv_swap"
```

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### systemd-boot

Only relevant for the unencrypted flows — [systemd-boot cannot prompt for a LUKS passphrase](../03-base-installation/bootloader-systemd.md) with the hooks this guide uses, so encrypted flows stay on GRUB.

```bash
sudo vim /boot/loader/entries/arch.conf
```

Add to the `options` line, same values as above:

```
options root=UUID=<root-uuid> rw resume=UUID=<swap-uuid>
# or, for a swap file:
options root=UUID=<root-uuid> rw resume=UUID=<root-fs-uuid> resume_offset=<offset>
```

---

## Step 5: Test It

```bash
sudo systemctl hibernate
```

The screen should go black, disk activity for a few seconds, then the machine powers off
completely — no fans, no lights. Power it back on the normal way (not a fresh boot from the
bootloader menu's "reboot" — just press the power button); it should skip the login screen
entirely and land you back exactly where you were, restored apps and all.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Powers off, then boots fresh (login screen, no restored session) | `resume=` missing, wrong, or `resume` hook not in initramfs | Recheck Step 2/3, then `journalctl -b -1 -k \| grep -i pm_hibernation` |
| `systemctl hibernate` returns "not enough swap space" | Swap smaller than RAM | Grow swap (see [Step 1](#step-1-check-your-swap)) |
| Hangs on resume / kernel panic instead of restoring | Stale `resume_offset` after moving/defragmenting the swap file | Re-run `map-swapfile` or `filefrag`, update the bootloader config |
| Never even attempts to power off | `systemd-logind` disallows hibernation on this hardware | `cat /sys/power/state` should list `disk`; if it doesn't, your firmware doesn't support S4 |

Verify what actually made it into the boot images:

```bash
lsinitcpio /boot/initramfs-linux.img | grep resume   # hook is present
cat /proc/cmdline | grep resume                      # parameter reached the running kernel
```

---

## Hibernate vs Suspend vs Hybrid Sleep

| | Suspend (`suspend`) | Hibernate (`hibernate`) | Hybrid Sleep (`hybrid-sleep`) |
|---|---|---|---|
| Power draw while "off" | Low (RAM stays powered) | None | Low, until the battery would otherwise die |
| Resume speed | 2–5s | 10–30s | 2–5s normally, falls back to hibernate's speed if power was lost |
| Survives a dead battery / unplugged laptop | ❌ | ✅ | ✅ |
| Needs swap configured | ❌ | ✅ | ✅ |

```bash
sudo systemctl suspend        # RAM only
sudo systemctl hibernate      # disk only
sudo systemctl hybrid-sleep   # both — RAM for speed, disk as a safety net
```

`hybrid-sleep` is the best default for a laptop: it resumes as fast as suspend most of the time,
and still recovers cleanly if the battery runs out while asleep.

---

## Hibernating on an Encrypted or TPM-Unlocked Disk

Nothing above changes if you also set up
[TPM2 auto-unlock](tpm-luks-autounlock.md). Resume happens in the initramfs, using the same
already-unlocked LUKS container the kernel just decrypted — whether that unlock came from you
typing a passphrase or from the TPM, the swap device inside it is available by the time the
`resume` hook runs. The one thing to double check if you switch to the `sd-encrypt` hook for TPM
unlocking: `resume` still needs to sit after `sd-encrypt` (and `lvm2`, if present) and before
`filesystems`, exactly as in the table in [Step 3](#step-3-add-the-resume-hook).

---

<div align="center">

[← Performance Tweaks](performance-tweaks.md) | [Back to Main Guide](../../README.md) | [Next: TPM2 Auto-Unlock →](tpm-luks-autounlock.md)

</div>
