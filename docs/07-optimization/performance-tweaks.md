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

## 💤 Hibernation Setup

Hibernation saves your system state to disk and completely powers off, allowing you to resume exactly where you left off.

### Prerequisites

You need a swap space **at least as large as your RAM**. Check your RAM size:

```bash
free -h
```

### Option 1: Using Swap Partition

If you already have a swap partition from installation:

```bash
# Find your swap partition UUID
sudo blkid | grep swap
```

Note the UUID (e.g., `UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`).

### Option 2: Create Swap File

If you don't have a swap partition or need more swap:

```bash
# Create 16GB swap file (adjust size to match your RAM)
sudo dd if=/dev/zero of=/swapfile bs=1M count=16384 status=progress

# Set permissions
sudo chmod 600 /swapfile

# Format as swap
sudo mkswap /swapfile

# Enable swap
sudo swapon /swapfile

# Verify
sudo swapon --show
```

**Add to fstab:**
```bash
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
```

**For Btrfs users:**
```bash
# Disable CoW for swap file
sudo chattr +C /swapfile
```

### Configure Hibernation

#### 1. Get Swap Information

**For swap partition:**
```bash
sudo blkid | grep swap
# Note the UUID
```

**For swap file:**
```bash
# Get swap file offset
sudo filefrag -v /swapfile | head -n 5
# Note the first physical_offset value
```

#### 2. Edit GRUB Configuration

```bash
sudo nvim /etc/default/grub
```

**For swap partition:**
Add to `GRUB_CMDLINE_LINUX_DEFAULT`:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... resume=UUID=your-swap-uuid"
```

**For swap file:**
Add both resume and resume_offset:
```bash
# First, find your root partition UUID
sudo blkid | grep "/ "

# Then add to GRUB (replace values)
GRUB_CMDLINE_LINUX_DEFAULT="... resume=UUID=your-root-uuid resume_offset=your_offset"
```

**Example:**
```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet resume=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx resume_offset=34816"
```

#### 3. Regenerate GRUB

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

#### 4. Configure mkinitcpio

```bash
sudo nvim /etc/mkinitcpio.conf
```

Find the `HOOKS` line and add `resume` **after** `filesystems`:

```bash
# Before
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)

# After
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems resume fsck)
```

> ⚠️ **Important:** `resume` must come AFTER `filesystems` but BEFORE `fsck`!

**Rebuild initramfs:**
```bash
sudo mkinitcpio -P
```

### For systemd-boot Users

Edit your boot entry:

```bash
sudo nvim /boot/loader/entries/arch.conf
```

Add resume parameters to the `options` line:

**For swap partition:**
```
options root=UUID=... rw resume=UUID=your-swap-uuid
```

**For swap file:**
```
options root=UUID=... rw resume=UUID=your-root-uuid resume_offset=your_offset
```

### Testing Hibernation

```bash
# Test hibernation
sudo systemctl hibernate
```

Your system should:
1. Save state to disk
2. Power off completely
3. On next boot, restore your session

### Troubleshooting

**Hibernation fails:**
```bash
# Check swap is active
sudo swapon --show

# Check journal for errors
sudo journalctl -b -u systemd-hibernate
```

**Resume doesn't work:**
```bash
# Verify resume hook is in initramfs
lsinitcpio /boot/initramfs-linux.img | grep resume

# Check kernel parameters
cat /proc/cmdline | grep resume
```

**Swap file offset not working:**
```bash
# Recalculate offset
sudo filefrag -v /swapfile | awk '$1=="0:" {print $4}'
# Use this value (remove trailing period)
```

### Hibernate vs Suspend

| Feature | Suspend (Sleep) | Hibernate |
|---------|----------------|-----------|
| Power usage | Low (RAM powered) | None (fully off) |
| Resume speed | Very fast (2-5s) | Slower (10-30s) |
| Battery drain | Yes (small) | No |
| Disk writes | No | Yes |
| Best for | Short breaks | Long periods |

### Hybrid Sleep (Optional)

Combines suspend and hibernate for safety:

```bash
sudo systemctl hybrid-sleep
```

System suspends to RAM but also saves to disk as backup.

---

## 🚀 Advanced Kernel Optimization

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
sudo nvim /etc/pacman.conf
```

Uncomment these lines:
```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

**Update package database:**
```bash
sudo pacman -Sy
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

[← Essential Software](../06-essential-software/essential-packages.md) | [Back to Main Guide](../../README.md)

</div>
