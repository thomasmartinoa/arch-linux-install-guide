# 🖥️ GPU and Hardware Drivers

> Installing graphics drivers for Intel, AMD, and NVIDIA GPUs.

![GPU Drivers](../../images/gpu-drivers.png)

## 📋 Table of Contents

- [Identify Your GPU](#-identify-your-gpu)
- [Intel Graphics](#-intel-graphics)
- [AMD Graphics](#-amd-graphics)
- [NVIDIA Graphics](#-nvidia-graphics)
- [Hybrid Graphics](#-hybrid-graphics)
- [Verify Installation](#-verify-installation)

---

## 🔍 Identify Your GPU

### Check GPU Hardware

```bash
lspci | grep -i vga
lspci | grep -i 3d
```

**Example outputs:**

```bash
# Intel
00:02.0 VGA compatible controller: Intel Corporation HD Graphics 630

# AMD
06:00.0 VGA compatible controller: AMD/ATI Navi 10 [Radeon RX 5600]

# NVIDIA
01:00.0 VGA compatible controller: NVIDIA Corporation TU106 [GeForce RTX 2060]
```

### Detailed GPU Info

```bash
lspci -v -s $(lspci | grep -i vga | cut -d' ' -f1)
```

---

## 🔧 CPU Microcode (Important)

Microcode updates provide CPU bug fixes and security patches.

### For Intel CPUs

```bash
sudo pacman -S intel-ucode
```

### For AMD CPUs

```bash
sudo pacman -S amd-ucode
```

### Regenerate GRUB Configuration

After installing microcode, update GRUB:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**Expected output:**
```
Generating grub configuration file...
Found linux image: /boot/vmlinuz-linux
Found initrd image: /boot/initramfs-linux.img
Found intel-ucode image: /boot/intel-ucode.img  ← Verify this line
```

> ✅ Look for "Found intel-ucode" or "Found amd-ucode" in the output.

### For systemd-boot Users

Microcode is automatically loaded if present, no action needed.

### Verify Microcode Loaded

After reboot:

```bash
dmesg | grep microcode
```

**Expected output:**
```
[    0.000000] microcode: updated early to revision 0xf0
```

> 💡 **Why install microcode?** It fixes CPU bugs, improves stability, and patches security vulnerabilities like Spectre/Meltdown.

---

## 💙 Intel Graphics

Intel integrated graphics use open-source drivers included in the kernel.

### Install Intel Drivers

```bash
sudo pacman -S mesa intel-media-driver
```

**Package descriptions:**

| Package | Purpose |
|---------|---------|
| `mesa` | OpenGL implementation |
| `intel-media-driver` | Hardware video acceleration (newer Intel) |

### For Older Intel GPUs (Pre-Broadwell)

```bash
sudo pacman -S mesa libva-intel-driver
```

### Vulkan Support (Gaming)

```bash
sudo pacman -S vulkan-intel
```

### All Intel Packages

```bash
sudo pacman -S mesa intel-media-driver vulkan-intel intel-gpu-tools
```

---

## ❤️ AMD Graphics

AMD uses open-source AMDGPU drivers (included in kernel).

### Install AMD Drivers

```bash
sudo pacman -S mesa libva-mesa-driver
```

**Package descriptions:**

| Package | Purpose |
|---------|---------|
| `mesa` | OpenGL implementation |
| `libva-mesa-driver` | Hardware video acceleration |

### Vulkan Support (Gaming)

```bash
sudo pacman -S vulkan-radeon
```

### For Older AMD GPUs (GCN 2 and older)

```bash
sudo pacman -S xf86-video-amdgpu  # Optional, kernel driver usually sufficient
```

### All AMD Packages

```bash
sudo pacman -S mesa libva-mesa-driver vulkan-radeon
```

### OpenCL Support (Compute)

```bash
sudo pacman -S opencl-mesa
```

---

## 💚 NVIDIA Graphics

NVIDIA requires proprietary drivers for best performance.

> 💡 **Recommendation:** For RTX 2000+ series cards, use `nvidia-open` for better performance and Wayland support.

### Install NVIDIA Drivers

**For RTX 2000+ (Turing, Ampere, Ada, Blackwell) - Recommended:**
```bash
sudo pacman -S nvidia-open nvidia-utils nvidia-settings
```

**For older cards (GTX 1000 series and below):**
```bash
sudo pacman -S nvidia nvidia-utils nvidia-settings
```

### For LTS Kernel Users

**RTX 2000+ cards:**
```bash
sudo pacman -S nvidia-open-lts nvidia-utils nvidia-settings
```

**Older cards:**
```bash
sudo pacman -S nvidia-lts nvidia-utils nvidia-settings
```

### NVIDIA Package Options

| Package | Description | Recommended For |
|---------|-------------|-----------------|
| `nvidia-open` | Open-source kernel modules | RTX 2000+ ⭐ |
| `nvidia-open-lts` | Open-source for LTS kernel | RTX 2000+ with LTS |
| `nvidia` | Proprietary driver for current kernel | GTX 1000 and older |
| `nvidia-lts` | Proprietary driver for LTS kernel | GTX 1000 and older with LTS |
| `nvidia-dkms` | DKMS version (compiles for any kernel) | Custom kernels |
| `nvidia-utils` | Utilities and libraries | All (required) |
| `nvidia-settings` | GUI settings application | All (recommended) |

### Why nvidia-open for RTX 2000+?

- ✅ Better Wayland support
- ✅ Improved power management
- ✅ Officially recommended by NVIDIA
- ✅ Faster bug fixes and updates
- ✅ Open-source kernel modules (userspace still proprietary)

### For Any Kernel (DKMS)

```bash
sudo pacman -S nvidia-dkms nvidia-utils nvidia-settings
```

> 💡 `nvidia-dkms` automatically compiles for your kernel, useful for custom kernels.

### Configure NVIDIA

After installing, regenerate initramfs:

```bash
sudo mkinitcpio -P
```

### NVIDIA + Wayland

For Wayland compositors (like Hyprland):

```bash
# Edit environment variables
sudo nvim /etc/environment
```

Add:
```bash
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
```

### Enable DRM Kernel Mode Setting

```bash
sudo nvim /etc/default/grub
```

Add to `GRUB_CMDLINE_LINUX_DEFAULT`:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... nvidia-drm.modeset=1"
```

Regenerate GRUB config:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 🔀 Hybrid Graphics (Laptop)

Many laptops have both Intel/AMD integrated and NVIDIA discrete graphics.

### Option 1: PRIME Render Offload (Recommended)

Run specific applications on NVIDIA:

```bash
# Install both drivers
sudo pacman -S mesa nvidia nvidia-utils nvidia-prime

# Run application on NVIDIA
prime-run application_name
```

### Option 2: Optimus Manager

For automatic switching:

```bash
# From AUR
yay -S optimus-manager optimus-manager-qt
```

### Option 3: Bumblebee (Older method)

```bash
sudo pacman -S bumblebee mesa nvidia
sudo systemctl enable bumblebeed
sudo gpasswd -a username bumblebee
```

---

## ✅ Verify Installation

### Check Loaded Driver

```bash
lspci -k | grep -A 2 -i vga
```

Look for "Kernel driver in use":
- Intel: `i915`
- AMD: `amdgpu`
- NVIDIA: `nvidia`

### OpenGL Information

```bash
# Install mesa-utils if needed
sudo pacman -S mesa-utils

# Check OpenGL
glxinfo | grep "OpenGL"
```

### Vulkan Information

```bash
# Install vulkan-tools if needed
sudo pacman -S vulkan-tools

# Check Vulkan
vulkaninfo | head -20
```

### NVIDIA Specific

```bash
# Check NVIDIA driver
nvidia-smi
```

### Test 3D Acceleration

```bash
glxgears
```

Should show a window with spinning gears at high FPS.

---

## 📊 Driver Summary Table

| GPU | Driver Package | Vulkan Package | Video Accel |
|-----|----------------|----------------|-------------|
| Intel (new) | `mesa` | `vulkan-intel` | `intel-media-driver` |
| Intel (old) | `mesa` | `vulkan-intel` | `libva-intel-driver` |
| AMD | `mesa` | `vulkan-radeon` | `libva-mesa-driver` |
| NVIDIA | `nvidia`/`nvidia-lts` | included | included |

---

## 📋 Quick Commands

### Intel
```bash
sudo pacman -S mesa intel-media-driver vulkan-intel
```

### AMD
```bash
sudo pacman -S mesa libva-mesa-driver vulkan-radeon
```

### NVIDIA
```bash
sudo pacman -S nvidia nvidia-lts nvidia-utils nvidia-settings
sudo mkinitcpio -P
```

### Verify
```bash
lspci -k | grep -A 2 -i vga
glxinfo | grep "OpenGL"
```

---

## ➡️ Next Steps

→ [Audio & Bluetooth Setup](audio-bluetooth.md)

---

<div align="center">

[← First Boot](first-boot.md) | [Back to Main Guide](../../README.md) | [Next: Audio & Bluetooth →](audio-bluetooth.md)

</div>
