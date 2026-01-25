# Display Managers

> Graphical login screens for your desktop.

## Comparison

| DM | Best For | RAM | Features |
|----|----------|-----|----------|
| **GDM** | GNOME | ~50MB | Wayland, sleek |
| **SDDM** | KDE/Hyprland | ~30MB | Themeable |
| **LightDM** | XFCE/Any | ~20MB | Lightweight |
| **ly** | Minimal | ~5MB | TUI-based |

---

## GDM (GNOME Display Manager)

```bash
sudo pacman -S gdm
sudo systemctl enable gdm
```

**Best for:** GNOME, Wayland sessions

---

## SDDM

```bash
sudo pacman -S sddm
sudo systemctl enable sddm
```

**Best for:** KDE, Hyprland, themeable

### SDDM Themes

```bash
# From AUR
yay -S sddm-theme-sugar-candy
```

Configure: `/etc/sddm.conf`

---

## LightDM

```bash
sudo pacman -S lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm
```

**Best for:** XFCE, Cinnamon, lightweight setups

---

## ly (TUI)

```bash
yay -S ly
sudo systemctl enable ly
```

**Best for:** Minimal setups, no GUI login

---

## No Display Manager

Start your DE from TTY:

```bash
# In ~/.bash_profile or ~/.zprofile
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec Hyprland  # Or startx for X11
fi
```

---

<div align="center">

[← DE Overview](de-overview.md) | [Back to Main Guide](../../README.md)

</div>
