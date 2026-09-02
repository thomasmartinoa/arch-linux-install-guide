# First Boot Configuration

> Initial setup after successfully booting into your new Arch Linux system.

![First Boot](../../images/first-boot.gif)

## Table of Contents

- [Login](#login)
- [Configure Sudo](#configure-sudo)
- [Network Setup](#network-setup)
- [Update System](#update-system)
- [Time Synchronization](#time-synchronization)
- [Basic Verification](#basic-verification)

---

## Login

### Encrypted System

If you set up encryption, you'll first see:

```
Enter passphrase for /dev/nvme0n1p3:
```

Enter your LUKS passphrase.

### Login Prompt

After boot, you'll see:

```
archpc login: martin
Password:
```

Login with your user account (not root).

---

## Check Sudo

You already enabled sudo during installation
([Step 6.3](../03-base-installation/base-install-common.md#63-configure-sudo)). Verify it:

```bash
sudo pacman -Syu
```

If that works, skip to the next section. If you get `username is not in the sudoers file`,
finish the setup below.

### Edit Sudoers File

```bash
# Switch to root
su -

# Edit sudoers (MUST use visudo)
EDITOR=vim visudo
```

> **NEVER** edit `/etc/sudoers` directly! Always use `visudo` — it syntax-checks before saving.
> A malformed sudoers file locks out sudo entirely, and repairing it needs a root shell you may
> not be able to get.

### Enable Wheel Group

Find and uncomment this line:

```bash
# Before
# %wheel ALL=(ALL:ALL) ALL

# After
%wheel ALL=(ALL:ALL) ALL
```

**What this means:**

| Part | Meaning |
|------|---------|
| `%wheel` | All users in wheel group |
| `ALL=` | On all hosts |
| `(ALL:ALL)` | As any user:group |
| `ALL` | Can run any command |

### Save and Exit

In vim: Press `Esc`, type `:wq`, press `Enter`.

### Verify Sudo Works

```bash
# Exit root
exit

# Test sudo (as your user)
sudo pacman -Syu
```

Enter your password when prompted.

> **Why `-Syu` and never bare `-Sy`?** `-Sy` refreshes the package database without upgrading
> anything. Install a package after that and it gets built against newer dependencies than the
> ones on your system — a partial upgrade, and the most common way to break an Arch install.
> Always sync and upgrade together.

### Alternative: Create Vim Symlink

If visudo complains about EDITOR:

```bash
ln -sf /usr/bin/vim /usr/bin/vi
```

Then simply:
```bash
visudo
```

---

## Network Setup

### NetworkManager (Recommended)

If you installed NetworkManager during base install:

```bash
# Enable and start NetworkManager
sudo systemctl enable --now NetworkManager
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `enable` | Start at every boot |
| `--now` | Also start immediately |
| `NetworkManager` | Service name |

### Connect to Network

#### Using nmtui (Text UI) ⭐

```bash
nmtui
```

Navigate with arrow keys:
1. Select **Activate a connection**
2. Select your network
3. Enter password if WiFi
4. Press **Back** then **Quit**

#### Using nmcli (Command Line)

**List WiFi networks:**
```bash
nmcli device wifi list
```

**Connect to WiFi:**
```bash
nmcli device wifi connect "NetworkName" password "yourpassword"
```

**Check connection:**
```bash
nmcli connection show
```

### For Wired Connection

Usually automatic. If not:

```bash
# Enable DHCP client
sudo systemctl enable --now dhcpcd
```

### Verify Connection

```bash
ping -c 3 archlinux.org
```

---

## Update System

### Sync Package Database

```bash
sudo pacman -Syu
```

### Full System Update

```bash
sudo pacman -Syu
```

> ⚠️ Always run full updates (`-Syu`) to avoid partial upgrades.

---

## Optimize Mirrors (Recommended)

Reflector automatically selects the fastest mirrors for faster downloads.

### Install Reflector

```bash
sudo pacman -S reflector
```

### Backup Current Mirrorlist

```bash
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
```

### Generate Optimized Mirrorlist

```bash
sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

**What this does:**

| Flag | Meaning |
|------|---------|
| `--verbose` | Show detailed output |
| `--latest 10` | Use 10 most recently synchronized mirrors |
| `--protocol https` | Only HTTPS mirrors (more secure) |
| `--sort rate` | Sort by download speed |
| `--save` | Save to mirrorlist file |

### Update Package Database

```bash
sudo pacman -Syu
```

You should notice faster download speeds!

### Automate Mirror Updates (Optional)

Enable weekly mirror optimization:

```bash
sudo systemctl enable reflector.timer
sudo systemctl start reflector.timer
```

Configure reflector settings:

```bash
sudo vim /etc/xdg/reflector/reflector.conf
```

Recommended configuration:
```
--save /etc/pacman.d/mirrorlist
--protocol https
--country India,Singapore,Germany,US
--latest 10
--sort rate
```

> 💡 **Tip:** Replace countries with those closest to your location for best results.

---

## Install Essential Packages

### Sync and Update All Packages

```bash
sudo pacman -Syu
```

**Command breakdown:**

| Part | Meaning |
|------|---------|
| `-S` | Sync operation |
| `-y` | Refresh package database |
| `-u` | Upgrade installed packages |

This may take a while if many updates are available.

### Install Additional Base Tools

```bash
sudo pacman -S --needed base-devel linux-headers \
networkmanager network-manager-applet wpa_supplicant \
git vim nano wget curl
```

**Package descriptions:**

| Package | Purpose |
|---------|---------|
| `base-devel` | Build tools (gcc, make, etc.) |
| `linux-headers` | Kernel headers for modules |
| `network-manager-applet` | GUI for NetworkManager |
| `wpa_supplicant` | WiFi authentication |
| `git` | Version control |
| `wget`, `curl` | Download utilities |

---

## Time Synchronization

### Configure Timezone

```bash
sudo timedatectl set-timezone Asia/Kolkata
```

### Enable NTP Sync

```bash
sudo timedatectl set-ntp true
```

### Start Time Sync Service

```bash
sudo systemctl enable --now systemd-timesyncd
```

### Verify Time

```bash
timedatectl status
```

**Expected output:**
```
               Local time: Mon 2024-11-04 15:30:00 IST
           Universal time: Mon 2024-11-04 10:00:00 UTC
                 RTC time: Mon 2024-11-04 10:00:00
                Time zone: Asia/Kolkata (IST, +0530)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

### Force Sync (If Needed)

```bash
sudo systemctl restart systemd-timesyncd
sleep 5
timedatectl
```

### Dual Boot Time Fix

If dual booting with Windows:

```bash
sudo timedatectl set-local-rtc 1
```

---

## Basic Verification

### Check System Information

```bash
# Kernel version
uname -r

# System info
hostnamectl

# Memory and CPU
free -h
lscpu | head -20
```

### Check Disk Space

```bash
df -h
```

### Check Services

```bash
# NetworkManager status
systemctl status NetworkManager

# SSH status (if installed)
systemctl status sshd

# Time sync status
systemctl status systemd-timesyncd
```

---

## Quick Reference

```bash
# Configure sudo
su -
EDITOR=vim visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
exit

# Network setup
sudo systemctl enable --now NetworkManager
nmtui  # Connect to network

# Update system
sudo pacman -Syu

# Install essentials
sudo pacman -S --needed base-devel linux-headers \
networkmanager network-manager-applet wpa_supplicant \
git vim nano wget curl

# Time sync
sudo timedatectl set-timezone Asia/Kolkata
sudo timedatectl set-ntp true
sudo systemctl enable --now systemd-timesyncd

# Verify
timedatectl status
ping -c 3 archlinux.org
```

---

## Next Steps

Your base system is configured! Continue with:

→ [Install Drivers](drivers.md) - GPU and hardware drivers

---

<div align="center">

[← Bootloader](../03-base-installation/README.md) | [Back to Main Guide](../../README.md) | [Next: Drivers →](drivers.md)

</div>
