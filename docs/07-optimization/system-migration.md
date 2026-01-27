# System Migration

> Exporting your Arch Linux setup to install on another PC.

## Table of Contents

- [Overview](#overview)
- [What to Export](#what-to-export)
- [Export Package Lists](#export-package-lists)
- [Export Enabled Services](#export-enabled-services)
- [Backup Configuration Files](#backup-configuration-files)
- [Dotfiles with GNU Stow](#dotfiles-with-gnu-stow)
- [Dotfiles with Git (Bare Repository)](#dotfiles-with-git-bare-repository)
- [Clean Package Lists](#clean-package-lists)
- [Restore on New System](#restore-on-new-system)
- [Post-Migration Checklist](#post-migration-checklist)
- [Complete Migration Script](#complete-migration-script)

---

## Overview

Moving your Arch setup to a new PC doesn't mean starting from scratch. You can export your package lists, dotfiles, and configurations, then restore everything on the new machine.

**The basic idea:**

```
Old PC                          New PC
├── Package lists      ──────>  Install packages
├── AUR packages       ──────>  Install AUR packages  
├── Dotfiles           ──────>  Deploy with stow/git
├── Config files       ──────>  Copy to /etc
└── Enabled services   ──────>  Re-enable services
```

---

## What to Export

Before migrating, gather these from your current system:

| Category | What to Export | Location |
|----------|----------------|----------|
| Official packages | Explicitly installed | `pacman -Qqe` |
| AUR packages | Foreign packages | `pacman -Qqem` |
| All packages | Including dependencies | `pacman -Qq` |
| Dotfiles | User configs | `~/.config`, `~/.*` |
| System configs | Modified /etc files | `/etc/` |
| Enabled services | Systemd units | `systemctl list-unit-files` |
| Cron jobs | Scheduled tasks | `crontab -l` |

---

## Export Package Lists

### Official Repository Packages

Get all explicitly installed packages from the official repos:

```bash
pacman -Qqen > pkglist.txt
```

**What this means:**
- `-Q` - Query installed packages
- `-q` - Quiet (names only, no versions)
- `-e` - Explicitly installed (not dependencies)
- `-n` - Native (from official repos only)

### AUR Packages

Get your AUR packages separately:

```bash
pacman -Qqem > aurlist.txt
```

**What this means:**
- `-m` - Foreign packages (not in sync database = AUR)

### All Packages (Including Dependencies)

If you want a complete snapshot:

```bash
pacman -Qq > all-packages.txt
```

### Optional Dependencies

Export optional deps you've installed:

```bash
comm -13 <(pacman -Qqdt | sort) <(pacman -Qqdtt | sort) > optdeps.txt
```

---

## Export Enabled Services

Get a list of all enabled systemd services:

```bash
systemctl list-unit-files --state=enabled > services.txt
```

For a cleaner list (just service names):

```bash
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > services-clean.txt
```

### User Services

Don't forget user-level services:

```bash
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > user-services.txt
```

---

## Backup Configuration Files

### System Configuration (/etc)

Find modified config files:

```bash
pacman -Qii | awk '/\[modified\]/ {print $(NF - 1)}' > modified-configs.txt
```

Copy important configs:

```bash
mkdir -p ~/backup/etc
sudo cp -r /etc/pacman.conf ~/backup/etc/
sudo cp -r /etc/pacman.d/mirrorlist ~/backup/etc/
sudo cp -r /etc/fstab ~/backup/etc/
sudo cp -r /etc/mkinitcpio.conf ~/backup/etc/
sudo cp -r /etc/default/grub ~/backup/etc/
sudo cp -r /etc/hostname ~/backup/etc/
sudo cp -r /etc/hosts ~/backup/etc/
sudo cp -r /etc/locale.conf ~/backup/etc/
sudo cp -r /etc/vconsole.conf ~/backup/etc/
```

### User Dotfiles

Common dotfiles to backup:

```bash
mkdir -p ~/backup/dotfiles
cp ~/.bashrc ~/backup/dotfiles/
cp ~/.zshrc ~/backup/dotfiles/
cp ~/.vimrc ~/backup/dotfiles/
cp -r ~/.config/nvim ~/backup/dotfiles/
cp -r ~/.config/kitty ~/backup/dotfiles/
cp -r ~/.config/alacritty ~/backup/dotfiles/
cp -r ~/.config/hypr ~/backup/dotfiles/
cp -r ~/.config/waybar ~/backup/dotfiles/
cp -r ~/.ssh ~/backup/dotfiles/    # Be careful with private keys!
```

---

## Dotfiles with GNU Stow

GNU Stow creates symlinks from a central directory to your home folder. It's the cleanest way to manage dotfiles.

### Install Stow

```bash
sudo pacman -S stow
```

### Set Up Dotfiles Directory

Create a structured dotfiles folder:

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles
```

### Organize by Application

Each app gets its own folder, mirroring where files should go in `~`:

```
~/dotfiles/
├── bash/
│   ├── .bashrc
│   └── .bash_profile
├── zsh/
│   ├── .zshrc
│   └── .zprofile
├── nvim/
│   └── .config/
│       └── nvim/
│           ├── init.lua
│           └── lua/
├── kitty/
│   └── .config/
│       └── kitty/
│           └── kitty.conf
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
└── hyprland/
    └── .config/
        └── hypr/
            └── hyprland.conf
```

### Move Files to Dotfiles Directory

```bash
# Example: Move zsh config
mkdir -p ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/

# Example: Move nvim config
mkdir -p ~/dotfiles/nvim/.config
mv ~/.config/nvim ~/dotfiles/nvim/.config/
```

### Deploy with Stow

From the dotfiles directory:

```bash
cd ~/dotfiles

# Stow individual packages
stow bash
stow zsh
stow nvim
stow kitty

# Or stow everything at once
stow */
```

This creates symlinks:
- `~/dotfiles/zsh/.zshrc` → `~/.zshrc`
- `~/dotfiles/nvim/.config/nvim` → `~/.config/nvim`

### Unstow (Remove Symlinks)

```bash
stow -D bash    # Remove bash symlinks
stow -D */      # Remove all
```

### Restow (Update Symlinks)

```bash
stow -R bash    # Re-create bash symlinks
```

### Push to Git

```bash
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles"
git remote add origin git@github.com:username/dotfiles.git
git push -u origin main
```

### Restore on New System

```bash
git clone git@github.com:username/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow */
```

---

## Dotfiles with Git (Bare Repository)

This method tracks dotfiles directly without symlinks. Good if you don't want stow as a dependency.

### Initialize Bare Repository

```bash
git init --bare ~/.dotfiles
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dotfiles config status.showUntrackedFiles no
```

Add the alias to your shell config:

```bash
echo "alias dotfiles='/usr/bin/git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\"'" >> ~/.bashrc
```

### Add Files

```bash
dotfiles add ~/.zshrc
dotfiles add ~/.config/nvim
dotfiles commit -m "Add zsh and nvim configs"
dotfiles remote add origin git@github.com:username/dotfiles.git
dotfiles push -u origin main
```

### Clone on New System

```bash
git clone --bare git@github.com:username/dotfiles.git ~/.dotfiles
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dotfiles checkout
dotfiles config status.showUntrackedFiles no
```

If you get conflicts with existing files:

```bash
mkdir -p ~/.dotfiles-backup
dotfiles checkout 2>&1 | grep -E "^\s" | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
dotfiles checkout
```

---

## Clean Package Lists

Hardware-specific packages shouldn't be installed on different hardware. Filter them out.

### Remove Kernels and GPU Drivers

Create a filtered package list:

```bash
grep -Ev \
'^(linux|linux-headers|linux-lts|linux-zen|linux-hardened|linux-cachyos|linux-cachyos.*|nvidia|nvidia-open|nvidia-utils|nvidia-settings|lib32-nvidia-utils|mesa|vulkan-radeon|vulkan-intel|xf86-video-|intel-ucode|amd-ucode|linux-firmware)' \
pkglist.txt > pkglist-clean.txt
```

**What gets excluded:**
- `linux*` - Kernels (you'll install the right one for new hardware)
- `nvidia*` - NVIDIA drivers
- `mesa`, `vulkan-*` - GPU drivers  
- `xf86-video-*` - Xorg video drivers
- `*-ucode` - CPU microcode (Intel/AMD specific)
- `linux-firmware` - Hardware firmware

### Clean AUR List Too

```bash
grep -Ev \
'^(linux|nvidia|vulkan|mesa|cachyos)' \
aurlist.txt > aurlist-clean.txt
```

### Review Before Using

Always check the cleaned lists:

```bash
cat pkglist-clean.txt | less
```

Make sure nothing important got filtered out accidentally.

---

## Restore on New System

After installing Arch on the new PC, restore your setup.

### Step 1: Copy Files to New System

Use USB drive, rsync, or cloud storage:

```bash
# On old system - create archive
tar -czvf arch-backup.tar.gz \
    pkglist-clean.txt \
    aurlist-clean.txt \
    services-clean.txt \
    ~/backup/etc \
    ~/dotfiles

# Transfer to new system...

# On new system - extract
tar -xzvf arch-backup.tar.gz
```

### Step 2: Install Official Packages

```bash
sudo pacman -S --needed - < pkglist-clean.txt
```

**What `--needed` does:** Skips packages that are already installed and up-to-date.

### Step 3: Install AUR Helper

If you were using yay:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

### Step 4: Install AUR Packages

```bash
yay -S --needed - < aurlist-clean.txt
```

Or with paru:

```bash
paru -S --needed - < aurlist-clean.txt
```

### Step 5: Deploy Dotfiles

With stow:

```bash
cd ~/dotfiles
stow */
```

Or with bare git method:

```bash
dotfiles checkout
```

### Step 6: Enable Services

```bash
while read -r service; do
    sudo systemctl enable "$service"
done < services-clean.txt
```

Or manually:

```bash
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm
# etc...
```

### Step 7: Install Correct Drivers

Based on your new hardware:

```bash
# Detect CPU and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    sudo pacman -S intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    sudo pacman -S amd-ucode
fi

# Install GPU drivers (check what you have)
lspci -k | grep -A 2 VGA
```

Then regenerate initramfs and update bootloader:

```bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Post-Migration Checklist

After migrating, verify everything works:

- [ ] System boots properly
- [ ] Network works (WiFi and/or Ethernet)
- [ ] Graphics drivers installed for new GPU
- [ ] Audio works
- [ ] All important packages installed
- [ ] Dotfiles deployed correctly
- [ ] SSH keys work (if copied)
- [ ] Browser data synced or imported
- [ ] Development environments set up
- [ ] Enabled services running (`systemctl --failed`)

---

## Complete Migration Script

Here's a script to automate the export process on your old system:

```bash
#!/bin/bash
# export-system.sh - Run on old system

BACKUP_DIR="$HOME/arch-migration"
mkdir -p "$BACKUP_DIR"

echo "Exporting package lists..."
pacman -Qqen > "$BACKUP_DIR/pkglist.txt"
pacman -Qqem > "$BACKUP_DIR/aurlist.txt"

echo "Creating cleaned package lists..."
grep -Ev \
'^(linux|linux-headers|linux-lts|linux-zen|linux-hardened|linux-cachyos|linux-cachyos.*|nvidia|nvidia-open|nvidia-utils|nvidia-settings|lib32-nvidia-utils|mesa|vulkan-radeon|vulkan-intel|xf86-video-|intel-ucode|amd-ucode|linux-firmware)' \
"$BACKUP_DIR/pkglist.txt" > "$BACKUP_DIR/pkglist-clean.txt"

grep -Ev \
'^(linux|nvidia|vulkan|mesa|cachyos)' \
"$BACKUP_DIR/aurlist.txt" > "$BACKUP_DIR/aurlist-clean.txt"

echo "Exporting enabled services..."
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > "$BACKUP_DIR/services.txt"

echo "Backing up system configs..."
mkdir -p "$BACKUP_DIR/etc"
sudo cp /etc/pacman.conf "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/pacman.d/mirrorlist "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/mkinitcpio.conf "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/default/grub "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/hostname "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/hosts "$BACKUP_DIR/etc/" 2>/dev/null
sudo cp /etc/locale.conf "$BACKUP_DIR/etc/" 2>/dev/null

echo "Creating archive..."
tar -czvf "$HOME/arch-migration.tar.gz" -C "$HOME" "arch-migration"

echo ""
echo "Done! Transfer arch-migration.tar.gz to your new system."
echo ""
echo "Package counts:"
echo "  Official packages: $(wc -l < "$BACKUP_DIR/pkglist-clean.txt")"
echo "  AUR packages: $(wc -l < "$BACKUP_DIR/aurlist-clean.txt")"
echo "  Enabled services: $(wc -l < "$BACKUP_DIR/services.txt")"
```

Make it executable and run:

```bash
chmod +x export-system.sh
./export-system.sh
```

---

> **Tip:** Keep your dotfiles in a git repository and update it regularly. That way you're always ready to migrate or recover from a fresh install.

---

<div align="center">

[← Maintenance](maintenance.md) | [Back to Main Guide](../../README.md) | [Next: Troubleshooting →](../08-troubleshooting/README.md)

</div>
