# 🔷 KDE Plasma Installation

> Feature-packed and super customizable.

![KDE Plasma](../../images/kde-plasma.png)

##  Installation

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

##  Package Groups

| Group | Description |
|-------|-------------|
| `plasma` | Full Plasma desktop |
| `plasma-desktop` | Minimal Plasma |
| `kde-applications` | All KDE apps |
| `kde-utilities` | Essential utilities |

---

##  Customization

KDE lets you tweak pretty much everything:

1. Right-click desktop → Configure Desktop
2. System Settings → Appearance
3. Add widgets to panels
4. Grab themes from KDE Store

---

##  Installation Complete!

**Nice!** You've got Arch running with KDE Plasma now.

The base system is done. Here's what you might want to set up next:

###  Continue Your Journey

| Next Steps | Why? |
|------------|------|
| [**Essential Packages**](../06-essential-software/essential-packages.md) | Software you'll actually want to use |
| [**AUR Helpers**](../06-essential-software/aur-helpers.md) | Get access to community packages |
| [**Performance Tweaks**](../07-optimization/performance-tweaks.md) | Speed things up, better battery life, gaming performance |
| [**Security Hardening**](../07-optimization/security.md) | Set up firewall and other security basics |
| [**Maintenance Guide**](../07-optimization/maintenance.md) | Keep things running smooth |
| [**Troubleshooting**](../08-troubleshooting/README.md) | Fix common problems |

> 💡 **Recommended flow:** Essential Packages → AUR Helpers → Performance → Security → Troubleshooting

---

<div align="center">

[← DE Overview](de-overview.md) | [Back to Main Guide](../../README.md) | [Next: Essential Software →](../06-essential-software/essential-packages.md)

</div>
