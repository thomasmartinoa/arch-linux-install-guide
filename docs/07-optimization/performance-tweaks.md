# Performance Tweaks

> Optimizing your Arch Linux system.

## Quick Optimizations

### Enable Parallel Downloads

```bash
sudo vim /etc/pacman.conf
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

> Only use TRIM if you have an SSD. Check with `lsblk -d -o name,rota` (0 = SSD, 1 = HDD).

### Reduce Swappiness

```bash
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
```

### Enable zram (Compressed RAM)

```bash
sudo pacman -S zram-generator

sudo vim /etc/systemd/zram-generator.conf
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

## Memory & Application Preloading

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
sudo vim /etc/preload.conf
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

## CPU Frequency Scaling

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
sudo vim /etc/auto-cpufreq.conf
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

## Boot Optimizations

### Enable NumLock on Boot

Automatically enable NumLock during boot (useful for desktop users).

```bash
# Install mkinitcpio hook
yay -S mkinitcpio-numlock

# Edit mkinitcpio config
sudo vim /etc/mkinitcpio.conf
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

## 💤 Hibernation & TPM Auto-Unlock

Moved into their own dedicated guides:

- **[Hibernation Setup](hibernation.md)** — swap sizing, resume parameters for every flow,
  mkinitcpio's `resume` hook, GRUB/systemd-boot config, testing and troubleshooting.
- **[TPM2 Auto-Unlock & Linking a Second Encrypted Disk](tpm-luks-autounlock.md)** — unlock a
  second LUKS disk with the same passphrase as your first, and optionally skip the passphrase
  prompt entirely using your TPM2 chip.

---

## Advanced Kernel Optimization

### CachyOS Kernel (Performance-Optimized)

CachyOS provides a custom-compiled Linux kernel with performance optimizations for desktop and gaming.

**Benefits:**
- Better gaming performance
- Improved system responsiveness
- Optimized CPU scheduler (BORE or BMQ)
- Pre-compiled with performance flags
- Optional LTO (Link Time Optimization)

**Installation:**

For detailed installation instructions, see the dedicated guide:

🔗 [**CachyOS Kernel Installation Guide**](https://github.com/thomasmartinoa/cachyos-kernel_on_arch)

The guide covers:
- Adding CachyOS repositories
- Choosing the right kernel variant
- Installation and configuration
- Bootloader setup
- Troubleshooting

> 💡 **Recommended for:** Gaming PCs, desktops where performance matters. Not necessary for servers or minimal systems.

---

## 🎮 Gaming Optimizations

### Enable multilib Repository

For 32-bit game support (Steam, Wine):

```bash
sudo vim /etc/pacman.conf
```

Uncomment these lines:
```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

**Update package database:**
```bash
sudo pacman -Syu
```

**What multilib enables:**
- 32-bit libraries for games
- Steam compatibility
- Wine/Proton support
- lib32 packages

### Install Gaming Essentials

```bash
# Enable GameMode
sudo pacman -S gamemode lib32-gamemode

# Steam (requires multilib)
sudo pacman -S steam

# Proton/Wine
sudo pacman -S wine wine-gecko wine-mono

# Additional 32-bit graphics drivers
# For NVIDIA:
sudo pacman -S lib32-nvidia-utils

# For AMD:
sudo pacman -S lib32-mesa lib32-vulkan-radeon

# For Intel:
sudo pacman -S lib32-mesa lib32-vulkan-intel
```

### Verify multilib

```bash
# Check if multilib is enabled
pacman -Sl multilib | head -10

# Install a 32-bit package to test
sudo pacman -S lib32-glibc
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

[← AUR Helpers](../06-essential-software/aur-helpers.md) | [Back to Main Guide](../../README.md) | [Next: Security →](security.md)

</div>
