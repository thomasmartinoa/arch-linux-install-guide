# Security Hardening

Complete guide for protecting your Arch Linux system.

## Table of Contents

- [Security Overview](#security-overview)
- [User Security](#user-security)
- [Firewall (UFW)](#firewall-ufw)
- [Firewall (nftables)](#firewall-nftables)
- [SSH Security](#ssh-security)
- [Fail2ban](#fail2ban)
- [AppArmor](#apparmor)
- [Secure Boot](#secure-boot)
- [Automatic Security Updates](#automatic-security-updates)
- [Kernel Hardening](#kernel-hardening)
- [Security Audit](#security-audit)

---

## Security Overview

### Security Layers

```
┌─────────────────────────────────────────────┐
│              Application Layer              │
│         (Sandboxing, AppArmor)              │
├─────────────────────────────────────────────┤
│               Network Layer                 │
│      (Firewall, Fail2ban, SSH keys)         │
├─────────────────────────────────────────────┤
│               System Layer                  │
│    (User permissions, sudo, file perms)     │
├─────────────────────────────────────────────┤
│                Boot Layer                   │
│         (Secure Boot, GRUB password)        │
├─────────────────────────────────────────────┤
│                Disk Layer                   │
│          (LUKS encryption)                  │
└─────────────────────────────────────────────┘
```

### Priority Guide

| Priority | Measure | Difficulty |
|----------|---------|------------|
| High | Firewall | Easy |
| High | User security/sudo | Easy |
| High | SSH key authentication | Medium |
| Medium | Fail2ban | Easy |
| Medium | Automatic updates | Easy |
| Medium | Disk encryption | Medium |
| Low | AppArmor | Medium |
| Low | Secure Boot | Advanced |
| Low | Kernel hardening | Advanced |

---

## User Security

### Principle of Least Privilege

Never use root for daily tasks. Use `sudo` when needed.

### Configure sudo

```bash
sudo visudo
```

**Recommended settings:**
```bash
# Require password for sudo (default)
Defaults env_reset
Defaults mail_badpass
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Password timeout (minutes)
Defaults timestamp_timeout=5

# Log sudo commands
Defaults logfile="/var/log/sudo.log"

# User privilege specification
root ALL=(ALL:ALL) ALL
%wheel ALL=(ALL:ALL) ALL
```

### Lock Root Account (Optional)

```bash
sudo passwd -l root
```

> ⚠️ Make sure you have a working sudo user first!

---

## Firewall (UFW)

UFW (Uncomplicated Firewall) is the easiest firewall to configure.

### Install UFW

```bash
sudo pacman -S ufw
```

### Configure and Enable

```bash
# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable firewall
sudo ufw enable

# Enable at boot
sudo systemctl enable ufw

# Start immediately
sudo systemctl start ufw
```

### Verify Status

```bash
sudo ufw status verbose
```

**Expected output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip
```

### Check Service Status

```bash
sudo systemctl status ufw
```

Should show "active (running)".

### Allow Common Services

```bash
# SSH (if needed)
sudo ufw allow ssh
# or
sudo ufw allow 22/tcp

# HTTP/HTTPS (for web servers)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Custom port
sudo ufw allow 8080/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Allow specific app
sudo ufw allow in "CUPS"
```

### List All Rules

```bash
sudo ufw status numbered
```

### Delete Rules

```bash
# List rules with numbers
sudo ufw status numbered

# Delete rule by number
sudo ufw delete 2

# Delete rule by specification
sudo ufw delete allow 8080/tcp
```

### Disable/Reset UFW

```bash
# Disable temporarily
sudo ufw disable

# Reset all rules
sudo ufw reset
```

> 💡 **Recommended:** Enable UFW immediately after installation to protect your system.

---

## Firewall (nftables)

nftables is the modern replacement for iptables.

### Install nftables

```bash
sudo pacman -S nftables
```

### Basic Configuration

```bash
sudo vim /etc/nftables.conf
```

```bash
#!/usr/bin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        
        ct state established,related accept
        iif "lo" accept
        ct state invalid drop
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        tcp dport 22 accept  # SSH
    }
    
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
    
    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

### Enable nftables

```bash
sudo systemctl enable --now nftables
```

---

## SSH Security

### Generate SSH Keys (On Client)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server
```

### Harden SSH Server

```bash
sudo vim /etc/ssh/sshd_config
```

**Recommended settings:**
```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
```

### Restart SSH

```bash
sudo systemctl restart sshd
```

---

## Fail2ban

Fail2ban bans IPs that show malicious signs.

### Install and Configure

```bash
sudo pacman -S fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo vim /etc/fail2ban/jail.local
```

**Recommended settings:**
```ini
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1
banaction = ufw

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 1h
```

### Enable Fail2ban

```bash
sudo systemctl enable --now fail2ban
```

### Check Status

```bash
sudo fail2ban-client status sshd
```

---

## AppArmor

AppArmor provides Mandatory Access Control for applications.

### Install AppArmor

```bash
sudo pacman -S apparmor
```

### Enable in Kernel

Add to GRUB:
```bash
sudo vim /etc/default/grub
# Add to GRUB_CMDLINE_LINUX_DEFAULT:
# apparmor=1 security=apparmor

sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Enable Service

```bash
sudo systemctl enable --now apparmor
```

### Check Status

```bash
sudo aa-status
```

---

## Secure Boot

Enable UEFI Secure Boot with your own keys (advanced).

### Install Tools

```bash
sudo pacman -S sbctl
```

### Setup Secure Boot

```bash
# Check status
sbctl status

# Create and enroll keys
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft

# Sign bootloader and kernel
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/vmlinuz-linux

# Verify
sudo sbctl verify
```

Then enable Secure Boot in BIOS.

---

## Automatic Security Updates

### Enable Reflector Timer

```bash
sudo pacman -S reflector
sudo systemctl enable --now reflector.timer
```

### Enable Paccache Timer

```bash
sudo pacman -S pacman-contrib
sudo systemctl enable --now paccache.timer
```

---

## Kernel Hardening

### Sysctl Security Settings

```bash
sudo vim /etc/sysctl.d/99-security.conf
```

```ini
# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable SYN cookies
net.ipv4.tcp_syncookies = 1

# Restrict kernel pointers
kernel.kptr_restrict = 2

# Restrict dmesg
kernel.dmesg_restrict = 1

# Enable ASLR
kernel.randomize_va_space = 2
```

### Apply Settings

```bash
sudo sysctl --system
```

---

## Security Audit

### Lynis Security Audit

```bash
sudo pacman -S lynis
sudo lynis audit system
```

### Check for Rootkits

```bash
sudo pacman -S rkhunter
sudo rkhunter --update
sudo rkhunter --check
```

### Check Open Ports

```bash
ss -tulpn
```

---

## Security Checklist

- [ ] **User Security** - Strong password, sudo configured, root locked
- [ ] **Firewall** - UFW/nftables enabled, default deny incoming
- [ ] **SSH** - Key auth only, password auth disabled, root login disabled
- [ ] **Fail2ban** - Installed and configured for SSH
- [ ] **Updates** - Reflector timer, paccache timer enabled
- [ ] **Advanced** - AppArmor, Secure Boot, kernel hardening (optional)

---

## Next Steps

- [System Maintenance](maintenance.md)

---

<div align="center">

[← Performance Tweaks](performance-tweaks.md) | [Back to Main Guide](../../README.md) | [Next: Maintenance →](maintenance.md)

</div>
