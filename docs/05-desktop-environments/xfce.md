# 🐭 XFCE Installation

> Lightweight, traditional desktop environment.

![XFCE Desktop](../../images/xfce-desktop.png)

## 📦 Installation

### Full Installation

```bash
sudo pacman -S xfce4 xfce4-goodies
```

### Display Manager

```bash
sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm
```

### Reboot

```bash
sudo reboot
```

---

## 🎨 Recommended Additions

```bash
# Better file manager features
sudo pacman -S gvfs gvfs-mtp

# Archive support
sudo pacman -S file-roller

# Image viewer
sudo pacman -S ristretto
```

---

## ➡️ Next Steps

→ [Essential Software](../06-essential-software/essential-packages.md)

---

<div align="center">

[← DE Overview](de-overview.md) | [Back to Main Guide](../../README.md) | [Next: Essential Software →](../06-essential-software/essential-packages.md)

</div>
