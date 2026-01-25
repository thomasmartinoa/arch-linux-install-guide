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

## 🎉 Installation Complete!

**Congratulations!** You now have a fully functional Arch Linux system with Xfce desktop environment.

Your base installation is complete, but there's more to enhance your experience:

### 🚀 Continue Your Journey

| Next Steps | Why? |
|------------|------|
| [**Essential Packages**](../06-essential-software/essential-packages.md) | Install must-have software for daily use |
| [**AUR Helpers**](../06-essential-software/aur-helpers.md) | Access thousands of community packages |
| [**Performance Tweaks**](../07-optimization/performance-tweaks.md) | Optimize speed, battery life, and gaming |
| [**Security Hardening**](../07-optimization/security.md) | Protect your system with firewall and best practices |
| [**Maintenance Guide**](../07-optimization/maintenance.md) | Keep your system healthy long-term |
| [**Troubleshooting**](../08-troubleshooting/README.md) | Fix common issues like boot, network, or driver problems |

> 💡 **Recommended flow:** Essential Packages → AUR Helpers → Performance → Security → Troubleshooting
---

<div align="center">

[← DE Overview](de-overview.md) | [Back to Main Guide](../../README.md) | [Next: Essential Software →](../06-essential-software/essential-packages.md)

</div>
