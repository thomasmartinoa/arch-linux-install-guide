# 🐭 XFCE Installation

> Light on resources, familiar layout.

![XFCE Desktop](../../images/xfce-desktop.png)

##  Installation

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

##  Recommended Additions

```bash
# Better file manager features
sudo pacman -S gvfs gvfs-mtp

# Archive support
sudo pacman -S file-roller

# Image viewer
sudo pacman -S ristretto
```

---

## Installation Complete!

**Nice!** You've got Arch running with Xfce now.

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
