# TPM2 Auto-Unlock & Linking a Second Encrypted Disk

> For systems that already have one or more LUKS-encrypted disks (**Btrfs + Encryption** or
> **LUKS + LVM**, or a second disk you encrypted yourself later): stop typing a passphrase for a
> second disk, and — optionally — stop typing one at all.

This is two independent upgrades. Do either on its own, or both:

1. **[Link a second encrypted disk](#part-1-link-a-second-encrypted-disk)** — add a keyfile as an
   extra unlock method on disk B, so unlocking disk A at boot also unlocks disk B, with no second
   prompt. No initramfs changes, works with the `encrypt` hook you already have.
2. **[Enroll the TPM2](#part-2-tpm2-auto-unlock-for-your-root-disk)** — so you don't type
   *anything* at boot. This one **does** change your initramfs, and is worth reading the caveats
   for before you touch a working system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Part 1: Link a Second Encrypted Disk](#part-1-link-a-second-encrypted-disk)
- [Part 2: TPM2 Auto-Unlock for Your Root Disk](#part-2-tpm2-auto-unlock-for-your-root-disk)
- [What You Are Giving Up](#what-you-are-giving-up)
- [Recovery](#recovery)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- A booted, working system on the **Btrfs + Encryption** or **LUKS + LVM** flow (or any LUKS disk
  you set up yourself the same way — `cryptsetup luksFormat`, unlocked via `cryptdevice=` and the
  `encrypt` hook).
- For Part 1, a second disk already LUKS-formatted with its own passphrase.
- For Part 2, a TPM2 chip. Almost every machine from the last decade has one (often labelled
  `fTPM` in firmware for AMD, or `PTT` for Intel) — check your BIOS if unsure, see
  [BIOS Settings](../01-pre-installation/bios-settings.md).

> Back up your LUKS header before touching either disk, if you have not already — both encrypted
> flows tell you how:
> [Btrfs + Encryption](../03-base-installation/bootloader-btrfs-luks.md#back-up-your-luks-header) ·
> [LUKS + LVM](../02-partitioning/lvm-encryption.md#back-up-your-luks-header). It takes one command.

---

## Part 1: Link a Second Encrypted Disk

The goal: type your root passphrase once, and the second disk unlocks itself — with **no** loss
of security on either disk. The keyfile that unlocks disk B only exists on disk A's filesystem,
which is itself encrypted. Anyone who can read the keyfile has already unlocked disk A with your
passphrase, so they had disk A's data anyway; disk B gains nothing to lose.

This does **not** touch the initramfs. Disk B is not needed to boot, so it can be unlocked later,
by systemd, after your real root filesystem is already mounted — the same mechanism that mounts
any other filesystem from `/etc/fstab`.

### Step 1: Generate a Keyfile

```bash
sudo mkdir -p -m 700 /etc/cryptsetup-keys.d
sudo dd if=/dev/urandom of=/etc/cryptsetup-keys.d/disk-b.key bs=512 count=1
sudo chmod 600 /etc/cryptsetup-keys.d/disk-b.key
```

| Part | Meaning |
|------|---------|
| `mkdir -m 700` | Directory readable only by root — the keyfile inherits nothing from a world-readable parent |
| `dd if=/dev/urandom` | 512 bytes of random data — far stronger than any passphrase, and you'll never type it |
| `bs=512 count=1` | One block. `cryptsetup` reads the whole file as key material; there's no reason to make it bigger |

### Step 2: Add the Keyfile to Disk B's LUKS Header

```bash
sudo cryptsetup luksAddKey /dev/sdX2 /etc/cryptsetup-keys.d/disk-b.key
```

Replace `/dev/sdX2` with disk B's actual LUKS partition. This prompts once for disk B's
**existing** passphrase, to prove you're allowed to add a new one — it does not remove that
passphrase, it adds the keyfile as an additional, independent way in.

```bash
sudo cryptsetup luksDump /dev/sdX2 | grep -A2 Keyslots
```

You should now see two active key slots: your original passphrase, and the new keyfile.
**Never wipe the passphrase slot.** It's your only way back in if the keyfile is ever lost —
for instance if you reinstall your root filesystem and forget to bring `/etc/cryptsetup-keys.d`
with it.

### Step 3: Register It in `/etc/crypttab`

```bash
sudo blkid -t TYPE=crypto_LUKS -o value -s UUID /dev/sdX2
```

```bash
sudo vim /etc/crypttab
```

Add one line:

```
diskb   UUID=<disk-b-luks-uuid>   /etc/cryptsetup-keys.d/disk-b.key   luks
```

| Field | Meaning |
|-------|---------|
| `diskb` | Mapper name — disk B appears at `/dev/mapper/diskb` |
| `UUID=` | The **LUKS partition's** UUID from `blkid`, not the filesystem inside it |
| `/etc/cryptsetup-keys.d/disk-b.key` | Path to the keyfile, read from your **already-mounted** root |
| `luks` | Options field — `luks` is enough; add `discard` here too if disk B is an SSD |

### Step 4: Mount It

If disk B isn't in `/etc/fstab` yet, add it now, pointing at the mapped device:

```bash
echo '/dev/mapper/diskb   /mnt/diskb   ext4   defaults   0 2' | sudo tee -a /etc/fstab
```

(Substitute your actual filesystem and mount point.)

```bash
sudo systemctl daemon-reload
sudo systemctl start systemd-cryptsetup@diskb.service
sudo mount -a
```

### Step 5: Verify

```bash
lsblk
journalctl -u systemd-cryptsetup@diskb.service --no-pager
```

Reboot. You should be asked for your root passphrase exactly once — disk B shows up in `lsblk`
already unlocked and mounted, with no second prompt.

> **This did not touch your initramfs on purpose.** Disk B unlocks in the real system, after
> root, driven by the same systemd generator that processes every other `crypttab` entry. If disk
> B ever needs to be available *before* root (for example, if it held `/`, which it doesn't
> here), that's a different, much narrower setup involving `mkinitcpio.conf`'s `FILES=` array —
> out of scope here because it doesn't apply to a second, non-root disk.

---

## Part 2: TPM2 Auto-Unlock for Your Root Disk

### Why this needs a different initramfs

Every encrypted flow in this guide uses mkinitcpio's classic, udev-based hooks (`base udev ...
encrypt ...`) rather than the systemd-based ones, specifically so all flows share one initramfs
design (see the explanation in
[Base Installation — Standard, Step 9](../03-base-installation/base-install-standard.md#step-9-build-the-initramfs)).

TPM2 tokens enrolled with `systemd-cryptenroll` are only understood by `systemd-cryptsetup`,
which only runs inside the initramfs when you use the **`sd-encrypt`** hook — the systemd-based
one. The busybox `encrypt` hook has no TPM support at all. There is no way to get TPM2 auto-unlock
without this switch; it is the one place this guide deliberately breaks its own consistency rule,
because the payoff (not typing anything at boot) is worth it.

Your passphrase keeps working as a fallback the entire time — `systemd-cryptenroll` **adds** a key
slot, it never removes the one you already have.

### Step 1: Confirm You Have a TPM

```bash
sudo pacman -S tpm2-tools
sudo systemd-cryptenroll --tpm2-device=list
```

You should see a device path, typically `/dev/tpmrm0`. An empty list usually means the TPM is
disabled in firmware — check
[BIOS Settings](../01-pre-installation/bios-settings.md) for `fTPM`/`PTT`/`Security Device`.

### Step 2: Switch to the systemd-Based Hooks

```bash
sudo vim /etc/mkinitcpio.conf
```

| Flow | Current `HOOKS=` | New `HOOKS=` |
|------|-------------------|--------------|
| Btrfs + Encryption | `base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck` | `base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck` |
| LUKS + LVM | `base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck` | `base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck` |

If you also set up [hibernation](hibernation.md), keep `resume` in the same relative position —
after `sd-encrypt` (and `lvm2`), before `filesystems`.

> **Replace the whole line, the same way Step 9 of your base install warned about.** `udev` and
> `systemd` are two different, mutually exclusive initramfs designs — do not mix hooks from both.

### Step 3: Replace the Kernel Parameter

The busybox `encrypt` hook reads `cryptdevice=`; `sd-encrypt` ignores it completely and reads
`rd.luks.name=` / `rd.luks.options=` instead — a parameter you missed here fails silently, not
loudly.

```bash
sudo blkid -t TYPE=crypto_LUKS -o value -s UUID /dev/sdX2   # your LUKS partition
```

```bash
sudo vim /etc/default/grub
```

| Flow | Old `GRUB_CMDLINE_LINUX` | New `GRUB_CMDLINE_LINUX` |
|------|--------------------------|--------------------------|
| Btrfs + Encryption | `cryptdevice=UUID=<uuid>:cryptroot` | `rd.luks.name=<uuid>=cryptroot rd.luks.options=cryptroot=tpm2-device=auto` |
| LUKS + LVM | `cryptdevice=UUID=<uuid>:cryptlvm` | `rd.luks.name=<uuid>=cryptlvm rd.luks.options=cryptlvm=tpm2-device=auto` |

`root=` and any `resume=`/`rootflags=` parameters stay exactly as they were.

### Step 4: Rebuild — But Don't Reboot Yet

```bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Check the `sd-encrypt` install actually pulled in what it needs:

```bash
lsinitcpio /boot/initramfs-linux.img | grep -c systemd-cryptsetup   # must be 1 or more
```

Stop here and reboot once *without* enrolling the TPM yet, to confirm `sd-encrypt` alone still
boots and still prompts for your passphrase the normal way. This isolates "did the hook switch
work" from "did the TPM enrollment work" — if something is wrong, you want to know which half
broke.

### Step 5: Enroll the TPM2

Back in the running system:

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/sdX2
```

`--tpm2-pcrs=7` binds the unlock to PCR 7 — the platform's Secure Boot state. This is deliberately
the *smallest* reasonable binding:

- **Do not bind to PCR 4, 8, 9, or 11** (bootloader code, kernel command line, initrd, and the
  UKI/kernel image respectively) unless you fully understand the consequence: `mkinitcpio -P`
  rebuilds your initrd on **every kernel update**, which changes PCR 9's measurement every time —
  the TPM unlock would then fail after every `pacman -Syu` that touches the kernel, until you
  re-enroll. That is not a security bug, just a maintenance trap most people don't want.
- PCR 7 changes only when you toggle Secure Boot or edit its key databases — rare, and something
  you'd expect to have to re-enroll after anyway.

Add a PIN if you want the TPM to require something you know as well as something you have:

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/sdX2
```

### Step 6: Reboot

You should see no passphrase prompt at all. If the TPM check fails for any reason —
firmware change, PCR mismatch, TPM briefly unavailable — `sd-encrypt` falls back to asking for
your passphrase, the same prompt you had before. It does not lock you out.

---

## What You Are Giving Up

A LUKS passphrase you must type protects against **two** different threats: someone who steals
the drive alone (encryption alone stops this), and someone who steals the whole running-or-off
*machine* (this needs the passphrase — the "something you know" factor).

**Plain TPM2 auto-unlock without a PIN removes the second protection entirely.** Anyone who
walks off with your powered-off laptop can simply turn it on, and the TPM will unlock it for them
— it only checks that the machine's own boot chain hasn't changed, not who is pressing the power
button. If your threat model includes physical theft of the whole device (most laptops), add
`--tpm2-with-pin=yes` in Step 5, or skip Part 2 and keep typing your passphrase.

Disk B, from Part 1, is unaffected either way — its security was never separate from disk A's to
begin with.

---

## Recovery

If a reboot leaves you stuck (TPM misbehaving, typo in a kernel parameter), your original
passphrase still works — `systemd-cryptenroll` never removed it.

**Can't get past the initramfs at all:**

1. Boot the live USB.
2. `cryptsetup open /dev/sdX2 cryptroot` (or `cryptlvm`) and enter your **passphrase**, not a PIN.
3. Mount and `arch-chroot` in as usual, then either fix the mistake, or roll all the way back:
   ```bash
   # Revert HOOKS to the udev-based line from your base-install guide, then:
   sudo mkinitcpio -P
   # Revert GRUB_CMDLINE_LINUX to cryptdevice=UUID=<uuid>:cryptroot, then:
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

**Just want to remove the TPM enrollment, keep `sd-encrypt`:**

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/sdX2
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Prompted for passphrase every boot despite enrolling | `rd.luks.options=` missing or misspelled, or HOOKS still has `encrypt` instead of `sd-encrypt` | Recheck [Step 2](#step-2-switch-to-the-systemd-based-hooks)/[3](#step-3-replace-the-kernel-parameter), `mkinitcpio -P` |
| TPM unlock worked once, then started asking for a passphrase again | A firmware update, Secure Boot toggle, or **mkinitcpio update changed PCR measurements** — this is a known, recurring issue after mkinitcpio's systemd-hook updates | Confirm the passphrase still unlocks it, then re-enroll: `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/sdX2` |
| `systemd-cryptenroll --tpm2-device=list` prints nothing | TPM disabled in firmware, or `tpm` kernel module not loaded early enough | Enable `fTPM`/`PTT` in BIOS; confirm with `ls /dev/tpm*` |
| Disk B never mounts, no prompt, no error | `systemd-cryptsetup@diskb.service` not started — usually a typo in the crypttab UUID | `journalctl -u systemd-cryptsetup@diskb.service`, recheck `blkid` output against `/etc/crypttab` |
| Disk B prompts for a passphrase instead of using the keyfile | Keyfile path wrong, unreadable, or the `luksAddKey` step didn't run against the right partition | `sudo cryptsetup luksDump /dev/sdX2 \| grep Keyslots` — confirm 2 slots exist |

---

<div align="center">

[← Hibernation Setup](hibernation.md) | [Back to Main Guide](../../README.md) | [Security →](security.md)

</div>
