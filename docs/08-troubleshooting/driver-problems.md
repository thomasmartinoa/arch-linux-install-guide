# Driver Problems

Solutions for GPU issues, display problems, and hardware driver troubleshooting.

![Driver Problems](../../images/driver-problems.png)

## Table of Contents

- [No Display Output](#no-display-output)
- [Wrong Resolution](#wrong-resolution)
- [Screen Tearing](#screen-tearing)
- [NVIDIA Specific Issues](#nvidia-specific-issues)
- [AMD Specific Issues](#amd-specific-issues)
- [Multi-Monitor Problems](#multi-monitor-problems)
- [Laptop-Specific Issues](#laptop-specific-issues)

---

## No Display Output

### Step 1: Try TTY

Press `Ctrl+Alt+F2` to switch to TTY. If you can login, the issue is with the display manager or GPU driver.

### Step 2: Boot with nomodeset

At GRUB menu:
1. Press `e` to edit
2. Add `nomodeset` to the `linux` line
3. Press `Ctrl+X` to boot

### Step 3: Check GPU Driver

```bash
# Login via TTY or SSH
lspci -k | grep -A 3 VGA
```

Look for "Kernel driver in use":
- Intel: `i915`
- AMD: `amdgpu`
- NVIDIA: `nvidia` or `nouveau`

### Step 4: Install Correct Driver

**Intel:**
```bash
sudo pacman -S mesa intel-media-driver vulkan-intel
```

**AMD:**
```bash
sudo pacman -S mesa libva-mesa-driver vulkan-radeon
```

**NVIDIA:**
```bash
sudo pacman -S nvidia nvidia-utils nvidia-settings
sudo mkinitcpio -P
sudo reboot
```

---

## Wrong Resolution

### Check Current Resolution

```bash
xrandr
# or for Wayland
wlr-randr
```

### Set Resolution (X11)

```bash
# List available modes
xrandr

# Set resolution
xrandr --output HDMI-1 --mode 1920x1080

# Set refresh rate
xrandr --output HDMI-1 --mode 1920x1080 --rate 144
```

### Set Resolution (Wayland/Hyprland)

Edit `~/.config/hypr/hyprland.conf`:
```bash
monitor=HDMI-A-1,1920x1080@144,0x0,1
```

### Add Custom Resolution (X11)

```bash
# Generate modeline
cvt 1920 1080 60

# Create new mode
xrandr --newmode "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync

# Add to output
xrandr --addmode HDMI-1 "1920x1080_60.00"

# Apply
xrandr --output HDMI-1 --mode "1920x1080_60.00"
```

---

## Screen Tearing

### Intel: Enable TearFree

```bash
sudo nvim /etc/X11/xorg.conf.d/20-intel.conf
```

```
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection
```

### AMD: Enable TearFree

```bash
sudo nvim /etc/X11/xorg.conf.d/20-amdgpu.conf
```

```
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
```

### NVIDIA: Enable ForceFullCompositionPipeline

```bash
nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 { ForceFullCompositionPipeline = On }"
```

Or use nvidia-settings GUI → X Server Display Configuration → Advanced → Force Full Composition Pipeline

### Compositor-Based Fix

Use a compositor like `picom`:
```bash
sudo pacman -S picom
picom --vsync &
```

---

## NVIDIA Specific Issues

### Driver Not Loading

```bash
# Check if nouveau is blocking
lsmod | grep nouveau

# Blacklist nouveau
sudo nvim /etc/modprobe.d/blacklist-nouveau.conf
```

Add:
```
blacklist nouveau
options nouveau modeset=0
```

Regenerate initramfs:
```bash
sudo mkinitcpio -P
sudo reboot
```

### Wayland Issues (Black Screen)

Add environment variables:
```bash
sudo nvim /etc/environment
```

```bash
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
```

Enable DRM:
```bash
sudo nvim /etc/default/grub
# Add nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT

sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### nvidia-smi Shows No Devices

```bash
# Check if driver is loaded
lsmod | grep nvidia

# Load manually
sudo modprobe nvidia

# Check dmesg for errors
dmesg | grep -i nvidia
```

### NVIDIA Open Source Driver (nvidia-open)

For newer cards (RTX 2000+), you can try the open-source kernel modules:
```bash
sudo pacman -S nvidia-open nvidia-utils
sudo mkinitcpio -P
sudo reboot
```

### Suspend/Resume Issues

```bash
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume
```

---

## AMD Specific Issues

### AMDGPU Not Loading

Check if radeon (old driver) is loading instead:
```bash
lsmod | grep radeon
```

Blacklist radeon:
```bash
sudo nvim /etc/modprobe.d/blacklist-radeon.conf
```

```
blacklist radeon
```

Force AMDGPU:
```bash
sudo nvim /etc/modprobe.d/amdgpu.conf
```

```
options amdgpu si_support=1
options amdgpu cik_support=1
```

### Screen Flickering

Try different power management:
```bash
echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
```

### Hardware Acceleration Not Working

```bash
# Check VA-API
vainfo

# Install if missing
sudo pacman -S libva-mesa-driver

# For VDPAU
sudo pacman -S mesa-vdpau
```

---

## Multi-Monitor Problems

### Detect Monitors

```bash
# X11
xrandr --auto

# Wayland
wlr-randr
```

### Configure Layout (X11)

```bash
# Put DP-1 to the right of HDMI-1
xrandr --output HDMI-1 --primary --mode 1920x1080 --output DP-1 --mode 1920x1080 --right-of HDMI-1
```

### Configure Layout (Hyprland)

```bash
# ~/.config/hypr/hyprland.conf
monitor=HDMI-A-1,1920x1080@60,0x0,1
monitor=DP-1,1920x1080@144,1920x0,1
```

### Different Refresh Rates

```bash
# X11 - Set each monitor's refresh rate
xrandr --output HDMI-1 --mode 1920x1080 --rate 60 --output DP-1 --mode 1920x1080 --rate 144
```

---

## Laptop-Specific Issues

### Touchpad Not Working

```bash
# Check if detected
xinput list
libinput list-devices

# Install driver
sudo pacman -S xf86-input-libinput

# Enable tap to click
sudo nvim /etc/X11/xorg.conf.d/30-touchpad.conf
```

```
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
EndSection
```

### Brightness Control Not Working

```bash
# Check available controls
ls /sys/class/backlight/

# Set brightness (example for intel)
echo 500 | sudo tee /sys/class/backlight/intel_backlight/brightness

# Install brightness control
sudo pacman -S brightnessctl
brightnessctl set 50%
```

Add kernel parameter if not working:
```bash
# Add to GRUB_CMDLINE_LINUX_DEFAULT
acpi_backlight=vendor
# or
acpi_backlight=native
```

### Hybrid Graphics (Intel + NVIDIA)

```bash
# Install both drivers
sudo pacman -S mesa nvidia nvidia-prime

# Run application on NVIDIA
prime-run application_name

# Check which GPU is active
glxinfo | grep "OpenGL renderer"
prime-run glxinfo | grep "OpenGL renderer"
```

### Fingerprint Reader

```bash
# Install
sudo pacman -S fprintd

# Enroll fingerprint
fprintd-enroll

# Enable for sudo (optional)
sudo nvim /etc/pam.d/sudo
# Add at top: auth sufficient pam_fprintd.so
```

---

## Driver Diagnostic Commands

```bash
# GPU information
lspci -k | grep -A 3 VGA
lspci -v -s $(lspci | grep VGA | cut -d' ' -f1)

# Driver in use
lspci -nnk | grep -A 3 VGA

# OpenGL info
glxinfo | grep "OpenGL"

# Vulkan info
vulkaninfo | head -30

# NVIDIA specific
nvidia-smi
nvidia-settings

# AMD specific
radeontop

# Monitor info
xrandr --verbose
```

---

## Next Steps

- [Audio Issues](audio-issues.md) - If you have sound problems
- [System Recovery](system-recovery.md) - For major issues

---

<div align="center">

[← Network Issues](network-issues.md) | [Back to Main Guide](../../README.md) | [Next: Audio Issues →](audio-issues.md)

</div>
