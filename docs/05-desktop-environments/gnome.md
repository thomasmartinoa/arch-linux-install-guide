# 🟠 GNOME Installation

> The modern, clean desktop.

![GNOME Desktop](../../images/gnome-desktop.png)

##  Installation

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

## Essential Extensions

Install GNOME Extensions support:

```bash
sudo pacman -S gnome-browser-connector
```

Recommended extensions:
- Dash to Dock
- AppIndicator
- Blur My Shell

---

##  Installation Complete!

**Nice!** You've got Arch running with GNOME now.

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
