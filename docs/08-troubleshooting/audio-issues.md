# Audio Issues

Solutions for no sound, wrong output devices, and audio configuration problems.

![Audio Issues](../../images/audio-issues.png)

## Table of Contents

- [No Sound at All](#no-sound-at-all)
- [Wrong Output Device](#wrong-output-device)
- [Microphone Not Working](#microphone-not-working)
- [Bluetooth Audio](#bluetooth-audio)
- [HDMI Audio](#hdmi-audio)
- [Application-Specific Issues](#application-specific-issues)

---

## No Sound at All

### Step 1: Check if Audio Service is Running

**For PipeWire (recommended):**
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

If not running:
```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

**For PulseAudio (legacy):**
```bash
systemctl --user status pulseaudio
```

### Step 2: Check Volume Levels

```bash
# Using alsamixer
alsamixer
# Use arrow keys, M to unmute, Esc to exit

# Using pactl
pactl list sinks short
pactl set-sink-volume @DEFAULT_SINK@ 100%
pactl set-sink-mute @DEFAULT_SINK@ 0
```

### Step 3: Check Sound Devices

```bash
# List sound cards
cat /proc/asound/cards

# List with aplay
aplay -l
```

If no cards shown, the driver isn't loaded.

### Step 4: Install Audio Stack

```bash
# PipeWire (modern, recommended)
sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

# Enable for user
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### Step 5: Test Audio

```bash
# Simple test
speaker-test -c 2

# Play a file
paplay /usr/share/sounds/freedesktop/stereo/bell.oga
```

---

## Wrong Output Device

### List Output Devices

```bash
# Using pactl
pactl list sinks short

# Using wpctl (WirePlumber)
wpctl status
```

### Set Default Output

```bash
# Using pactl
pactl set-default-sink <sink_name>

# Using wpctl
wpctl set-default <device_id>

# Example
wpctl set-default 46
```

### Use pavucontrol (GUI)

```bash
sudo pacman -S pavucontrol
pavucontrol
```

Navigate to "Output Devices" tab and set your preferred device as fallback (green checkmark).

### Make Default Persistent

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d/
nvim ~/.config/pipewire/pipewire.conf.d/10-default-sink.conf
```

```
context.properties = {
    default.audio.sink = "alsa_output.pci-0000_00_1f.3.analog-stereo"
}
```

---

## Microphone Not Working

### Check Input Devices

```bash
# List input devices
pactl list sources short

# Using arecord
arecord -l
```

### Set Default Input

```bash
pactl set-default-source <source_name>
# or
wpctl set-default <device_id>
```

### Check Microphone Volume

```bash
# Using alsamixer (F4 for capture devices)
alsamixer
# Press F4 for Capture, unmute with M

# Using pactl
pactl set-source-volume @DEFAULT_SOURCE@ 100%
pactl set-source-mute @DEFAULT_SOURCE@ 0
```

### Test Microphone

```bash
# Record 5 seconds
arecord -d 5 test.wav

# Play back
aplay test.wav
```

### Application Permissions

Some applications need specific permissions. In pavucontrol:
1. Go to "Recording" tab
2. Make sure your application is using the correct input device

---

## Bluetooth Audio

### Install Bluetooth Support

```bash
sudo pacman -S bluez bluez-utils
sudo systemctl enable --now bluetooth
```

### Pair Device

```bash
bluetoothctl
```

```
power on
agent on
default-agent
scan on
# Wait for your device to appear
pair XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
```

### Audio Not Working After Connect

```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check if Bluetooth sink exists
pactl list sinks short | grep bluez
```

### Switch to Bluetooth Audio

```bash
# Set Bluetooth as default
pactl set-default-sink bluez_sink.XX_XX_XX_XX_XX_XX.a2dp_sink

# Or use pavucontrol to select
pavucontrol
```

### High-Quality Audio (AAC/LDAC)

```bash
# Install codecs
sudo pacman -S libldac

# May need to restart Bluetooth
sudo systemctl restart bluetooth
systemctl --user restart pipewire wireplumber
```

---

## HDMI Audio

### Check HDMI Output

```bash
aplay -l | grep HDMI
pactl list sinks short | grep hdmi
```

### Set HDMI as Default

```bash
# Find the HDMI sink name
pactl list sinks short

# Set as default
pactl set-default-sink alsa_output.pci-0000_01_00.1.hdmi-stereo
```

### NVIDIA HDMI Audio

```bash
# Ensure nvidia-utils is installed
sudo pacman -S nvidia-utils

# Check if NVIDIA audio is detected
lspci | grep -i audio
```

If NVIDIA audio device shows but no sound:
```bash
# Add to /etc/modprobe.d/nvidia.conf
options snd-hda-intel enable_msi=1
```

### AMD HDMI Audio

Usually works out of the box. If not:
```bash
# Check kernel module
lsmod | grep snd_hda_intel

# Reload
sudo modprobe -r snd_hda_intel
sudo modprobe snd_hda_intel
```

---

## Application-Specific Issues

### Discord

```bash
# Run with PipeWire
PIPEWIRE_LATENCY=256/48000 discord
```

If screen share audio doesn't work:
```bash
# Install xdg-desktop-portal
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-gtk
```

### Firefox

1. Go to `about:config`
2. Set `media.cubeb.backend` to `pulse`
3. Restart Firefox

### Games (Steam/Wine)

```bash
# Install 32-bit libraries
sudo pacman -S lib32-pipewire lib32-libpulse
```

### OBS

```bash
# Install PipeWire plugin
sudo pacman -S obs-studio pipewire-jack
```

### Flatpak Apps

```bash
# Grant PipeWire access
flatpak override --user --socket=pulseaudio
flatpak override --user --socket=pipewire
```

---

## Audio Diagnostic Commands

```bash
# Sound cards
cat /proc/asound/cards
aplay -l
arecord -l

# PipeWire status
wpctl status
pw-cli ls Node

# PulseAudio info
pactl info
pactl list sinks
pactl list sources

# ALSA info
alsamixer
amixer

# Check for errors
journalctl --user -u pipewire
journalctl --user -u wireplumber

# Test speaker
speaker-test -c 2 -t wav
```

---

## Common Fixes

### Reset PipeWire Config

```bash
rm -rf ~/.config/pipewire
rm -rf ~/.local/state/pipewire
rm -rf ~/.local/state/wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Switch from PulseAudio to PipeWire

```bash
# Remove PulseAudio
sudo pacman -Rns pulseaudio pulseaudio-alsa

# Install PipeWire
sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

# Enable
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### ALSA Configuration Reset

```bash
# Reset ALSA state
sudo alsactl restore

# Store current state
sudo alsactl store
```

---

## Next Steps

- [System Recovery](system-recovery.md) - For major system issues

---

<div align="center">

[← Driver Problems](driver-problems.md) | [Back to Main Guide](../../README.md) | [Next: System Recovery →](system-recovery.md)

</div>
