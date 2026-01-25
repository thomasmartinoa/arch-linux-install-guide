# 🟠 GNOME Installation

> Modern, streamlined desktop environment.

![GNOME Desktop](../../images/gnome-desktop.png)

## 📦 Installation

### Full Installation

```bash
sudo pacman -S gnome gnome-extra
```

### Minimal Installation

```bash
sudo pacman -S gnome-shell gnome-control-center gnome-terminal nautilus gdm
```

### Enable Display Manager

```bash
sudo systemctl enable gdm
```

### Reboot

```bash
sudo reboot
```

---

## 🔧 Essential Extensions

Install GNOME Extensions support:

```bash
sudo pacman -S gnome-browser-connector
```

Recommended extensions:
- Dash to Dock
- AppIndicator
- Blur My Shell

---

## 🎉 Installation Complete!

**Congratulations!** You now have a fully functional Arch Linux system with GNOME desktop environment.

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
