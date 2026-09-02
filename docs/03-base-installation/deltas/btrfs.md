# Path Notes: Btrfs

> Extras for the **Btrfs with subvolumes** path.

Partitioning: [Btrfs Setup](../../02-partitioning/btrfs-setup.md)

---

## Your two branch answers

| Branch point | Your answer |
|--------------|-------------|
| Step 6.2 — extra packages | `btrfs-progs` |
| Step 9 — HOOKS | Arch default, unchanged |

```bash
pacman -S btrfs-progs
```

> ### 🔴 `btrfs-progs` is mandatory
>
> Your root filesystem *is* Btrfs. Without these tools the installed system cannot check or
> mount its own root. There is no warning at install time — it simply fails to boot.

No mkinitcpio change is needed: the standard `filesystems` hook loads the Btrfs driver once
`btrfs-progs` is present.

Then continue to [GRUB — Standard](../bootloader-standard.md) or
[systemd-boot](../bootloader-systemd.md).

---

## Snapshots live outside your kernels

With the ESP mounted at `/boot`, your kernels and initramfs images sit on the FAT32 EFI
partition — which is *not* part of any Btrfs subvolume and therefore *not* captured by
snapshots. Rolling back to a snapshot restores your system files but keeps whatever kernel is
currently installed.

In practice this is what you want: a bad package update is what snapshots rescue you from, and
that rollback works perfectly. A bad *kernel* update is what the LTS kernel entry in your boot
menu is for. Just know that the two mechanisms cover different failures.

---

## Setting up Snapper after first boot

```bash
sudo pacman -S snapper snap-pac grub-btrfs
```

| Package | Purpose |
|---------|---------|
| `snapper` | Creates and manages snapshots |
| `snap-pac` | Automatic snapshot before and after every `pacman` transaction |
| `grub-btrfs` | Adds a "boot from snapshot" submenu to GRUB |

### The `/.snapshots` conflict — read this before running `create-config`

`snapper create-config` insists on creating its own `/.snapshots` subvolume, and refuses to run
if anything is already mounted there. But your `@snapshots` **is** mounted there — `genfstab`
captured it during install, so it mounts at every boot. Run `create-config` now and you get:

```
Creating config failed (creating btrfs subvolume .snapshots failed since it already exists).
```

That is the single most common Btrfs-on-Arch stumbling block. The fix is to get out of
snapper's way, let it do its thing, then put your own subvolume back:

```bash
sudo umount /.snapshots                    # unmount YOUR @snapshots
sudo rm -r /.snapshots                     # remove the now-empty mount point
sudo snapper -c root create-config /       # snapper creates ITS own /.snapshots subvolume
sudo btrfs subvolume delete /.snapshots    # delete snapper's — you want yours
sudo mkdir /.snapshots                     # recreate the mount point
sudo mount -a                              # remount YOUR @snapshots from fstab
sudo chmod 750 /.snapshots                 # snapper expects these permissions
```

Order matters throughout. `create-config` must run while nothing is mounted at `/.snapshots`,
and the `mount -a` at the end is what reconnects the subvolume `genfstab` recorded.

### Turn on automatic snapshots

```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now grub-btrfsd
```

### Tune the retention limits

```bash
sudo vim /etc/snapper/configs/root
```

```ini
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
```

Defaults keep far more snapshots than a desktop needs, and they are what fills your disk.

### Check it works

```bash
sudo snapper -c root list      # should show snapshots
sudo compsize /                # how much compression is actually saving you
```

---

<div align="center">

[← Base Installation](../base-install-common.md) | [Back to Main Guide](../../../README.md)

</div>
