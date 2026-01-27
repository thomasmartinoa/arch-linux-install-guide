# System Migration

> Moving your Arch setup to a new PC without losing your mind.

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

Got a new PC? Don't reinstall everything from memory - that's a nightmare. Just export your current setup and restore it on the new machine.

**Here's how it works:**

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

You'll want to grab these from your old system:

| Category | What It Is | How to Get It |
|----------|------------|---------------|
| Official packages | Stuff you installed from repos | `pacman -Qqe` |
| AUR packages | Stuff from the AUR | `pacman -Qqem` |
| All packages | Everything (including deps) | `pacman -Qq` |
| Dotfiles | Your personal configs | `~/.config`, `~/.*` |
| System configs | Modified system files | `/etc/` |
| Enabled services | What starts on boot | `systemctl list-unit-files` |
| Cron jobs | Scheduled tasks | `crontab -l` |

---

## Export Package Lists

### Official Repository Packages

First, get everything you explicitly installed from the official repos:

```bash
pacman -Qqen > pkglist.txt
```

**Breaking it down:**
- `-Q` - Query what's installed
- `-q` - Quiet mode (just names, no versions)
- `-e` - Only stuff you chose to install (not auto-dependencies)
- `-n` - Native packages only (from official repos)

### AUR Packages

Grab your AUR packages in a separate list:

```bash
pacman -Qqem > aurlist.txt
```

**What `-m` does:**
- Foreign packages (anything not in the official repos - that's your AUR stuff)

### All Packages (Including Dependencies)

Want absolutely everything? Here you go:

```bash
pacman -Qq > all-packages.txt
```

### Optional Dependencies

If you've manually installed some optional deps:

```bash
comm -13 <(pacman -Qqdt | sort) <(pacman -Qqdtt | sort) > optdeps.txt
```

---

## Export Enabled Services

Grab everything that starts on boot:

```bash
systemctl list-unit-files --state=enabled > services.txt
```

Want just the names without the extra info?

```bash
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > services-clean.txt
```

### User Services

Also check for user-level services (these run as your user, not root):

```bash
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > user-services.txt
```

---

## Backup Configuration Files

### System Configuration (/etc)

Find which system config files you've changed:

```bash
pacman -Qii | awk '/\[modified\]/ {print $(NF - 1)}' > modified-configs.txt
```

Grab the important stuff:

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

Your personal config files - the ones that make your system *yours*:

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
cp -r ~/.ssh ~/backup/dotfiles/    # Careful - these are private keys!
```

---

## Dotfiles with GNU Stow

Stow is brilliant - it creates symlinks from one folder to your home directory. So you can keep all your dotfiles organized in one place and version control them.

### Install Stow

```bash
sudo pacman -S stow
```

### Set Up Dotfiles Directory

Make a folder for all your dotfiles:

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles
```

### Organize by Application

Each app gets its own folder. The folder structure mirrors where files go in your home:

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

From your dotfiles folder:

```bash
cd ~/dotfiles

# Stow specific apps
stow bash
stow zsh
stow nvim
stow kitty

# Or just stow everything
stow */
```

Now you've got symlinks:
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

This method tracks dotfiles right in your home directory without symlinks. Less dependencies, but a bit trickier.

### Initialize Bare Repository

```bash
git init --bare ~/.dotfiles
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dotfiles config status.showUntrackedFiles no
```

Add the alias to your shell so it sticks:

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

If you hit conflicts with existing files:

```bash
mkdir -p ~/.dotfiles-backup
dotfiles checkout 2>&1 | grep -E "^\s" | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
dotfiles checkout
```

---

## Clean Package Lists

You don't want to install your old GPU drivers on a machine with different hardware. Filter out the hardware-specific stuff.

### Remove Kernels and GPU Drivers

Clean up your package list:

```bash
grep -Ev \
'^(linux|linux-headers|linux-lts|linux-zen|linux-hardened|linux-cachyos|linux-cachyos.*|nvidia|nvidia-open|nvidia-utils|nvidia-settings|lib32-nvidia-utils|mesa|vulkan-radeon|vulkan-intel|xf86-video-|intel-ucode|amd-ucode|linux-firmware)' \
pkglist.txt > pkglist-clean.txt
```

**What this removes:**
- `linux*` - Kernels (install the right one on new hardware)
- `nvidia*` - NVIDIA drivers
- `mesa`, `vulkan-*` - GPU drivers  
- `xf86-video-*` - Xorg video drivers
- `*-ucode` - CPU microcode (Intel vs AMD)
- `linux-firmware` - Hardware-specific firmware

### Clean AUR List Too

```bash
grep -Ev \
'^(linux|nvidia|vulkan|mesa|cachyos)' \
aurlist.txt > aurlist-clean.txt
```

### Double Check Before Using

Make sure nothing important got filtered:

```bash
cat pkglist-clean.txt | less
```

Better safe than sorry - review what's in there.

---

## Restore on New System

You've installed Arch on the new PC. Now let's bring back all your stuff.

### Step 1: Copy Files to New System

Use whatever works - USB drive, rsync over network, cloud storage:

```bash
# On old system - pack it up
tar -czvf arch-backup.tar.gz \
    pkglist-clean.txt \
    aurlist-clean.txt \
    services-clean.txt \
    ~/backup/etc \
    ~/dotfiles

# Transfer however you want...

# On new system - unpack
tar -xzvf arch-backup.tar.gz
```

### Step 2: Install Official Packages

```bash
sudo pacman -S --needed - < pkglist-clean.txt
```

**The `--needed` flag:** Skips stuff that's already installed. Saves time.

### Step 3: Install AUR Helper

If you used yay:

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

Or if you're using paru:

```bash
paru -S --needed - < aurlist-clean.txt
```

### Step 5: Deploy Dotfiles

With stow:

```bash
cd ~/dotfiles
stow */
```

Or with the bare git method:

```bash
dotfiles checkout
```

### Step 6: Enable Services

```bash
while read -r service; do
    sudo systemctl enable "$service"
done < services-clean.txt
```

Or just do it manually:

```bash
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm
# whatever else you need...
```

### Step 7: Install Correct Drivers

Figure out what hardware you've got:

```bash
# Auto-detect CPU and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    sudo pacman -S intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    sudo pacman -S amd-ucode
fi

# Check your GPU
lspci -k | grep -A 2 VGA
```

Then update initramfs and bootloader:

```bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Post-Migration Checklist

Make sure everything's working:

- [ ] System boots (obviously important)
- [ ] Network connects (WiFi and/or Ethernet)
- [ ] Graphics drivers match your new GPU
- [ ] Audio plays
- [ ] All your important packages installed
- [ ] Dotfiles look right
- [ ] SSH keys work (if you copied them)
- [ ] Browser data synced
- [ ] Dev environments set up
- [ ] No failed services (`systemctl --failed`)

---

## Complete Migration Script

Here's a script that does all the export stuff for you. Run this on your old system:

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

Make it run:

```bash
chmod +x export-system.sh
./export-system.sh
```

---

> **Tip:** Keep your dotfiles in git and update them regularly. Makes migrating (or recovering from disasters) way easier.

---

<div align="center">

[← Maintenance](maintenance.md) | [Back to Main Guide](../../README.md) | [Next: Troubleshooting →](../08-troubleshooting/README.md)

</div>
