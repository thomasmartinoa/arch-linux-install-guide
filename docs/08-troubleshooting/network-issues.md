# Network Issues

Solutions for WiFi, Ethernet, DNS, and connectivity problems.

![Network Issues](../../images/network-issues.png)

## Table of Contents

- [No Network at All](#no-network-at-all)
- [WiFi Not Working](#wifi-not-working)
- [Ethernet Not Working](#ethernet-not-working)
- [DNS Problems](#dns-problems)
- [Slow Network](#slow-network)
- [VPN Issues](#vpn-issues)

---

## No Network at All

### Step 1: Check Network Interfaces

```bash
ip link
```

**Expected output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> ...
2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...    # Ethernet
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...     # WiFi
```

If you don't see `enp*` (Ethernet) or `wlan*` (WiFi):
- Hardware not detected
- Driver missing

### Step 2: Check NetworkManager Status

```bash
systemctl status NetworkManager
```

**If not running:**
```bash
sudo systemctl enable --now NetworkManager
```

### Step 3: Check for IP Address

```bash
ip addr
```

Look for `inet` entries with IP addresses.

---

## WiFi Not Working

### Symptom 1: No WiFi Interface

```bash
ip link | grep wlan
```

If nothing shows, your WiFi hardware isn't detected.

#### Check Hardware

```bash
lspci | grep -i wireless
lspci | grep -i network
lsusb | grep -i wireless
```

#### Install Drivers

```bash
# For Intel WiFi
sudo pacman -S linux-firmware

# For Broadcom
sudo pacman -S broadcom-wl

# For Realtek USB adapters (from AUR)
yay -S rtl8821cu-morrownr-dkms-git
```

#### Enable Interface

```bash
sudo ip link set wlan0 up
```

If you get "RF-kill":
```bash
# Check RF-kill status
rfkill list

# Unblock WiFi
sudo rfkill unblock wifi
```

### Symptom 2: Can See Networks but Can't Connect

#### Using nmcli

```bash
# List available networks
nmcli device wifi list

# Connect
nmcli device wifi connect "NetworkName" password "YourPassword"
```

#### Using nmtui (Text UI)

```bash
nmtui
```
Navigate: **Activate a connection** → Select your network → Enter password

### Symptom 3: Wrong WiFi Password Error

```bash
# Forget the network
nmcli connection delete "NetworkName"

# Reconnect
nmcli device wifi connect "NetworkName" password "YourPassword"
```

### Symptom 4: WiFi Works Then Disconnects

#### Power Management Issue

```bash
# Check current power management
iwconfig wlan0 | grep "Power Management"

# Disable power management temporarily
sudo iwconfig wlan0 power off

# Make permanent
sudo nvim /etc/NetworkManager/conf.d/wifi-powersave.conf
```

Add:
```ini
[connection]
wifi.powersave = 2
```

Restart NetworkManager:
```bash
sudo systemctl restart NetworkManager
```

---

## Ethernet Not Working

### Check Cable and Link

```bash
# Check if cable is connected
ip link show enp3s0
```

Look for `state UP` or `state DOWN`.

### Enable Interface

```bash
sudo ip link set enp3s0 up
```

### Request IP via DHCP

```bash
sudo dhclient enp3s0
# or
sudo dhcpcd enp3s0
```

### Check Driver

```bash
lspci -k | grep -A 3 Ethernet
```

Look for "Kernel driver in use:". If missing, install the driver.

### Static IP Configuration

```bash
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8,8.8.4.4"

nmcli connection up "Wired connection 1"
```

---

## DNS Problems

### Symptoms
- `ping 8.8.8.8` works but `ping google.com` fails
- "Temporary failure in name resolution"

### Check Current DNS

```bash
cat /etc/resolv.conf
resolvectl status
```

### Solution 1: Set DNS Manually

```bash
# Using NetworkManager
nmcli connection modify "Your Connection" ipv4.dns "8.8.8.8 8.8.4.4"
nmcli connection modify "Your Connection" ipv4.ignore-auto-dns yes
nmcli connection up "Your Connection"
```

### Solution 2: Use systemd-resolved

```bash
# Enable systemd-resolved
sudo systemctl enable --now systemd-resolved

# Link resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Configure DNS
sudo nvim /etc/systemd/resolved.conf
```

Add:
```ini
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
```

Restart:
```bash
sudo systemctl restart systemd-resolved
```

### Solution 3: Edit resolv.conf Directly

```bash
sudo nvim /etc/resolv.conf
```

Add:
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

> ⚠️ This may be overwritten by NetworkManager. Use Solution 1 or 2 for persistence.

---

## Slow Network

### Test Speed

```bash
# Install speedtest
sudo pacman -S speedtest-cli

# Run test
speedtest
```

### Check for MTU Issues

```bash
# Test MTU
ping -M do -s 1472 google.com
```

If this fails, reduce packet size until it works:
```bash
ping -M do -s 1400 google.com
```

Set MTU:
```bash
sudo ip link set enp3s0 mtu 1400
```

### Disable IPv6 (If Causing Issues)

```bash
# Temporary
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Permanent
sudo nvim /etc/sysctl.d/40-ipv6.conf
```

Add:
```
net.ipv6.conf.all.disable_ipv6 = 1
```

---

## VPN Issues

### OpenVPN

```bash
# Install
sudo pacman -S openvpn networkmanager-openvpn

# Import config
sudo nmcli connection import type openvpn file your-config.ovpn

# Connect
nmcli connection up your-config
```

### WireGuard

```bash
# Install
sudo pacman -S wireguard-tools

# Import config
sudo cp your-config.conf /etc/wireguard/wg0.conf

# Start
sudo wg-quick up wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0
```

---

## Network Diagnostic Commands

```bash
# All interfaces
ip addr

# Routing table
ip route

# Check connectivity
ping -c 4 8.8.8.8      # Google DNS
ping -c 4 google.com   # DNS test

# DNS lookup
nslookup google.com
dig google.com

# Check listening ports
ss -tulpn

# Network connections
nmcli connection show

# WiFi scan
nmcli device wifi list

# Check NetworkManager logs
journalctl -u NetworkManager
```

---

## Next Steps

- [Driver Problems](driver-problems.md) - If network hardware isn't detected
- [System Recovery](system-recovery.md) - If you need to fix from Live USB

---

<div align="center">

[← Boot Problems](boot-problems.md) | [Back to Main Guide](../../README.md) | [Next: Driver Problems →](driver-problems.md)

</div>
