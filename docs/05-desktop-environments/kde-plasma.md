# 🔷 KDE Plasma Installation

> Full-featured, highly customizable desktop environment.

![KDE Plasma](../../images/kde-plasma.png)

## 📦 Installation

### Minimal Installation

```bash
sudo pacman -S plasma-desktop sddm
```

### Full Installation (Recommended)

```bash
sudo pacman -S plasma kde-applications
```

### Enable Display Manager

```bash
sudo systemctl enable sddm
```

### Reboot

```bash
sudo reboot
```

---

## 📋 Package Groups

| Group | Description |
|-------|-------------|
| `plasma` | Full Plasma desktop |
| `plasma-desktop` | Minimal Plasma |
| `kde-applications` | All KDE apps |
| `kde-utilities` | Essential utilities |

---

## 🎨 Customization

KDE is extremely customizable:

1. **Right-click desktop** → Configure Desktop
2. **System Settings** → Appearance
3. **Add widgets** to panels
4. **Download themes** from KDE Store

---

## 🎉 Installation Complete!

**Congratulations!** You now have a fully functional Arch Linux system with KDE Plasma desktop environment.

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
