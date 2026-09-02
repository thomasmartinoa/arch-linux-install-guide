# Audio and Bluetooth Setup

> Setting up PipeWire for audio and Bluetooth connectivity.

## Table of Contents

- [Audio with PipeWire](#audio-with-pipewire)
- [Bluetooth Setup](#bluetooth-setup)
- [Troubleshooting](#troubleshooting)

---

## Audio with PipeWire

**PipeWire** is the modern audio system for Linux, replacing PulseAudio and JACK.

### Why PipeWire?

| Feature | Description |
|---------|-------------|
| **Low latency** | Professional audio quality |
| **PulseAudio compatible** | Works with all apps |
| **JACK compatible** | Pro audio workflows |
| **Bluetooth support** | Built-in Bluetooth audio |
| **Screen sharing** | Native screen capture support |

### Install PipeWire

```bash
sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
```

**Package descriptions:**

| Package | Purpose |
|---------|---------|
| `pipewire` | Core audio daemon |
| `pipewire-pulse` | PulseAudio replacement |
| `pipewire-alsa` | ALSA plugin |
| `pipewire-jack` | JACK replacement |
| `wireplumber` | Session manager |

### Enable PipeWire

PipeWire runs as a user service (no sudo needed):

```bash
# Enable WirePlumber (session manager)
systemctl --user enable --now wireplumber

# Enable PipeWire
systemctl --user enable --now pipewire pipewire-pulse
```

> The `--user` flag runs services as your user, not system-wide.

### Verify Audio

```bash
# Check PipeWire status
systemctl --user status pipewire

# List audio devices
wpctl status

# Test audio
speaker-test -c 2
```

Press `Ctrl+C` to stop the test.

### Volume Control

```bash
# Command line
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+   # Increase
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-   # Decrease
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle  # Mute toggle

# GUI tool (install if needed)
sudo pacman -S pavucontrol
pavucontrol
```

---

## 📶 Bluetooth Setup

### Install Bluetooth Packages

```bash
sudo pacman -S bluez bluez-utils
```

**Package descriptions:**

| Package | Purpose |
|---------|---------|
| `bluez` | Bluetooth protocol stack |
| `bluez-utils` | CLI tools (bluetoothctl) |

### Enable Bluetooth Service

```bash
sudo systemctl enable --now bluetooth
```

### Using bluetoothctl

```bash
bluetoothctl
```

**Inside bluetoothctl:**

```bash
# Power on adapter
power on

# Enable agent
agent on
default-agent

# Scan for devices
scan on

# Wait for your device to appear...
# Device XX:XX:XX:XX:XX:XX Device Name

# Pair with device
pair XX:XX:XX:XX:XX:XX

# Trust device (auto-connect)
trust XX:XX:XX:XX:XX:XX

# Connect
connect XX:XX:XX:XX:XX:XX

# Stop scanning
scan off

# Exit
exit
```

### Auto Power On

Edit Bluetooth config:

```bash
sudo vim /etc/bluetooth/main.conf
```

Find and change:

```ini
[Policy]
AutoEnable=true
```

### GUI Bluetooth Manager

```bash
sudo pacman -S blueman
blueman-manager
```

---

## Troubleshooting

### No Sound

```bash
# Check if PipeWire is running
systemctl --user status pipewire

# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check audio sinks
wpctl status
pactl list sinks short
```

### Wrong Default Device

```bash
# List sinks
wpctl status

# Set default (use sink ID from list)
wpctl set-default <sink_id>
```

### Bluetooth Device Won't Connect

```bash
# Check Bluetooth service
sudo systemctl status bluetooth

# Check if device is blocked
rfkill list bluetooth

# Unblock if blocked
sudo rfkill unblock bluetooth

# Restart Bluetooth
sudo systemctl restart bluetooth
```

### Bluetooth Audio Stuttering

Increase Bluetooth audio quality:

```bash
sudo vim /etc/bluetooth/main.conf
```

Add under `[General]`:
```ini
[General]
ControllerMode = bredr
Enable=Source,Sink,Media,Socket
```

### No Bluetooth Adapter Found

```bash
# Check if adapter is recognized
lsusb | grep -i bluetooth
lspci | grep -i bluetooth

# Load Bluetooth module
sudo modprobe btusb
```

---

## Quick Reference

```bash
# Install audio
sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
systemctl --user enable --now wireplumber pipewire pipewire-pulse

# Install Bluetooth
sudo pacman -S bluez bluez-utils
sudo systemctl enable --now bluetooth

# Volume control
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Bluetooth pairing
bluetoothctl
> power on
> scan on
> pair XX:XX:XX:XX:XX:XX
> connect XX:XX:XX:XX:XX:XX
> exit
```

---

## Next Steps

Your audio and Bluetooth are configured!

→ [Desktop Environments Overview](../05-desktop-environments/de-overview.md)

---

<div align="center">

[← Drivers](drivers.md) | [Back to Main Guide](../../README.md) | [Next: Desktop Environments →](../05-desktop-environments/de-overview.md)

</div>
