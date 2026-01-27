# System Maintenance

> Keeping your Arch system healthy.

## Package Management

### Update System

```bash
sudo pacman -Syu
```

### Clean Package Cache

```bash
# Remove all but 3 most recent versions
sudo paccache -r

# Remove all uninstalled packages
sudo paccache -ruk0
```

### Remove Orphans

```bash
sudo pacman -Rns $(pacman -Qtdq)
```

---

## Backups with Timeshift

```bash
yay -S timeshift
```

Create snapshots before major updates!

---

## Check Disk Usage

```bash
df -h
ncdu /  # Interactive disk usage
```

---

## Check for Issues

```bash
# Failed services
systemctl --failed

# Journal errors
journalctl -p 3 -xb
```

---

## Maintenance Schedule

| Task | Frequency |
|------|-----------|
| Update system | Weekly |
| Clean cache | Monthly |
| Remove orphans | Monthly |
| Backup | Before updates |
| Check journals | Monthly |

---

<div align="center">

[← Security](security.md) | [Back to Main Guide](../../README.md) | [Next: System Migration →](system-migration.md)

</div>
