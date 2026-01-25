# ⚡ Performance Tweaks

> Optimizing your Arch Linux system.

## 🚀 Quick Optimizations

### Enable Parallel Downloads

```bash
sudo nvim /etc/pacman.conf
```

Uncomment:
```
ParallelDownloads = 5
```

### Enable TRIM (SSD)

TRIM helps maintain SSD performance and longevity.

```bash
# Enable fstrim timer
sudo systemctl enable fstrim.timer

# Start immediately
sudo systemctl start fstrim.timer

# Check status
sudo systemctl status fstrim.timer
```

**Expected output:**
```
● fstrim.timer - Discard unused blocks once a week
     Loaded: loaded (/usr/lib/systemd/system/fstrim.timer; enabled; preset: disabled)
     Active: active (waiting)
```

**Manual TRIM (optional):**
```bash
sudo fstrim -av
```

> ⚠️ Only use TRIM if you have an SSD. Check with `lsblk -d -o name,rota` (0 = SSD, 1 = HDD).

### Reduce Swappiness

```bash
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
```

### Enable zram (Compressed RAM)

```bash
sudo pacman -S zram-generator

sudo nvim /etc/systemd/zram-generator.conf
```

Add:
```
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
```

```bash
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
```

---

## 🧠 Memory & Application Preloading

### Preload (Application Prefetcher)

Preload monitors frequently used applications and preloads them into memory for faster startup.

```bash
# Install from AUR
yay -S preload

# Enable and start
sudo systemctl enable preload
sudo systemctl start preload

# Check status
sudo systemctl status preload
```

**How it works:**

| Feature | Description |
|---------|-------------|
| Monitors | Tracks which applications you use most |
| Preloads | Loads frequently used apps into RAM |
| Result | Faster application startup times |

**Configuration (optional):**
```bash
sudo nvim /etc/preload.conf
```

Key settings:
```ini
# Minimum amount of RAM to keep free
memfree = 50

# Interval between preload cycles (seconds)
cycle = 20
```

> 💡 **Best for:** Systems with 4GB+ RAM. Not recommended for low-memory systems.

---

## ⚡ CPU Frequency Scaling

### auto-cpufreq (Automatic CPU Speed & Power Optimization)

Automatically adjusts CPU frequency based on usage, extending battery life on laptops.

#### Installation

```bash
# Clone repository
git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq

# Install
sudo ./auto-cpufreq-installer --install
```

> 🔗 **GitHub:** [AdnanHodzic/auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq)

#### Enable auto-cpufreq

```bash
# Enable service
sudo auto-cpufreq --install

# Check status
sudo auto-cpufreq --stats
```

#### Monitor Live

```bash
sudo auto-cpufreq --monitor
```

**What it does:**

| Mode | Description |
|------|-------------|
| Battery | Lowers CPU frequency to save power |
| AC Power | Increases frequency for performance |
| Turbo Boost | Manages Intel Turbo Boost dynamically |

#### Configuration (optional)

```bash
sudo nvim /etc/auto-cpufreq.conf
```

Example config:
```ini
[charger]
governor = performance
scaling_min_freq = 1400000
scaling_max_freq = 3500000
turbo = auto

[battery]
governor = powersave
scaling_min_freq = 1400000
scaling_max_freq = 1800000
turbo = auto
```

> 💡 **Recommended for:** Laptops and systems where power efficiency matters.

---

## ⌨️ Boot Optimizations

### Enable NumLock on Boot

Automatically enable NumLock during boot (useful for desktop users).

```bash
# Install mkinitcpio hook
yay -S mkinitcpio-numlock

# Edit mkinitcpio config
sudo nvim /etc/mkinitcpio.conf
```

Find the `HOOKS` line and add `numlock` before `filesystems`:

```bash
# Before
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)

# After
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont numlock block filesystems fsck)
```

**Rebuild initramfs:**
```bash
sudo mkinitcpio -P
```

**Reboot to test:**
```bash
sudo reboot
```

> 💡 NumLock will now be enabled automatically on boot!

---

## 🎮 Gaming Optimizations

```bash
# Enable GameMode
sudo pacman -S gamemode lib32-gamemode

# Steam
sudo pacman -S steam

# Proton/Wine
sudo pacman -S wine wine-gecko wine-mono
```

---

## 🔋 Laptop Power Management

```bash
sudo pacman -S tlp tlp-rdw
sudo systemctl enable tlp
sudo systemctl enable NetworkManager-dispatcher
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
```

---

<div align="center">

[← Essential Software](../06-essential-software/essential-packages.md) | [Back to Main Guide](../../README.md)

</div>
