# Path Notes: Standard (ext4)

> Extras for the **Basic** or **Advanced** ext4 partitioning paths.

Partitioning: [Basic](../../02-partitioning/basic-partitioning.md) ·
[Advanced](../../02-partitioning/advanced-partitioning.md)

---

## What's different

Nothing. This is the baseline path — it needs no extra packages and no mkinitcpio changes.

| Branch point | Your answer |
|--------------|-------------|
| Step 6.2 — extra packages | *(none)* |
| Step 9 — HOOKS | Arch default, unchanged |

Work straight through [base-install-common.md](../base-install-common.md), then continue to
[GRUB — Standard](../bootloader-standard.md) or [systemd-boot](../bootloader-systemd.md).

---

## Worth knowing

**Your ESP is also your `/boot`.** With this layout the FAT32 EFI partition is mounted directly
at `/boot`, so it holds the bootloader *and* your kernels and initramfs images. That is why
this guide asks for a 1GB ESP rather than the 512MB you will see in older guides: two kernels,
each with a normal and a fallback initramfs, plus microcode, does not comfortably fit in 512MB
— and it overflows outright once NVIDIA modules land in the fallback image.

If you already made a 512MB ESP and later hit `No space left on device` during a kernel update,
the quickest fix is to drop the LTS kernel (`pacman -Rns linux-lts linux-lts-headers`) and
remove its leftover images from `/boot`.

**Separate `/home`?** If you followed the Advanced guide, `/home` is its own partition. Nothing
in the install changes — `genfstab` picks it up automatically. The payoff comes later: you can
reinstall Arch over `/` and keep everything in `/home`.

---

<div align="center">

[← Base Installation](../base-install-common.md) | [Back to Main Guide](../../../README.md)

</div>
