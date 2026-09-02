# Path Notes: LVM

> Extras for the **LVM without encryption** path.

Partitioning: [LVM Setup](../../02-partitioning/lvm-setup.md)

---

## Your two branch answers

| Branch point | Your answer |
|--------------|-------------|
| Step 6.2 — extra packages | `lvm2` |
| Step 9 — HOOKS | `... block `**`lvm2`**` filesystems fsck` |

```bash
pacman -S lvm2
```

The `lvm2` package provides both the userspace tools and the `lvm2` initramfs hook. Without the
hook, the initramfs never activates your volume group, and boot dies with
`device /dev/mapper/volgroup0-lv_root not found`.

Then continue to [GRUB — LVM](../bootloader-lvm.md).

---

## No kernel parameters needed

Unlike the encrypted path, plain LVM needs nothing in `/etc/default/grub`. The `lvm2` hook
scans and activates every volume group it finds, then `filesystems` mounts root. `grub-mkconfig`
works out `root=/dev/mapper/volgroup0-lv_root` on its own.

Verify it did:

```bash
grep -m1 'root=' /boot/grub/grub.cfg
```

---

## Resizing later — the reason you chose LVM

```bash
# Grow /home by 50GB (online, no unmount needed)
sudo lvextend -L +50G /dev/volgroup0/lv_home
sudo resize2fs /dev/volgroup0/lv_home

# Shrink is offline and order-sensitive — filesystem FIRST, then the volume
sudo umount /home
sudo e2fsck -f /dev/volgroup0/lv_home
sudo resize2fs /dev/volgroup0/lv_home 300G
sudo lvreduce -L 300G /dev/volgroup0/lv_home
```

> ⚠️ Shrinking in the wrong order — `lvreduce` before `resize2fs` — destroys the filesystem.
> Growing is safe in either order, but shrinking is not. Back up first.

Add a second disk to the pool:

```bash
sudo pvcreate /dev/sdb1
sudo vgextend volgroup0 /dev/sdb1
```

---

<div align="center">

[← Base Installation](../base-install-common.md) | [Back to Main Guide](../../../README.md)

</div>
