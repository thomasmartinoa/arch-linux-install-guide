# 📦 AUR Helpers

> Accessing the Arch User Repository (AUR).

![AUR](../../images/aur.png)

## 💡 What is the AUR?

The **Arch User Repository (AUR)** is a community-driven repository with PKGBUILDs for software not in official repos.

> ⚠️ AUR packages are user-submitted and not officially supported.

---

## 🔧 Installing an AUR Helper

### yay (Recommended) ⭐

```bash
# Install dependencies
sudo pacman -S --needed base-devel git

# Clone yay
git clone https://aur.archlinux.org/yay.git

# Build and install
cd yay
makepkg -si

# Clean up
cd ..
rm -rf yay
```

### paru (Alternative)

```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

---

## 📖 Using yay

### Search Packages

```bash
yay -Ss package_name
```

### Install Package

```bash
yay -S package_name
```

### Update All (Official + AUR)

```bash
yay -Syu
```

### Remove Package

```bash
yay -Rns package_name
```

---

## 🎯 Popular AUR Packages

```bash
# Browsers
yay -S google-chrome
yay -S brave-bin

# Apps
yay -S spotify
yay -S visual-studio-code-bin

# Tools
yay -S timeshift          # Backup
yay -S pamac-aur          # GUI package manager
```

---

## ⚠️ Safety Tips

1. **Read PKGBUILDs** before installing
2. **Check comments** on AUR page
3. **Verify popularity** and votes
4. **Keep updated** to avoid security issues

---

<div align="center">

[← Essential Packages](essential-packages.md) | [Back to Main Guide](../../README.md) | [Next: Performance Tweaks →](../07-optimization/performance-tweaks.md)

</div>
