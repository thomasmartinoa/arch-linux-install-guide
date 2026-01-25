# BIOS/UEFI Settings

> Before booting the Arch installer, you need to configure your BIOS settings.

![BIOS Settings](../../images/bios-settings.png)

## Table of Contents

- [Accessing BIOS/UEFI](#accessing-biosuefi)
- [Essential Settings](#essential-settings)
- [Boot Order](#boot-order)
- [Common BIOS Keys by Manufacturer](#common-bios-keys-by-manufacturer)
- [Troubleshooting](#troubleshooting)

---

## Accessing BIOS/UEFI

To get into your BIOS settings, press a specific key during boot:

1. Restart your computer
2. Spam the BIOS key as soon as it starts
3. The key varies by manufacturer (see table below)

### Common BIOS Keys by Manufacturer

| Manufacturer | BIOS Key | Boot Menu Key |
|--------------|----------|---------------|
| **ASUS** | F2 or DEL | F8 |
| **Acer** | F2 or DEL | F12 |
| **Dell** | F2 | F12 |
| **HP** | F10 or ESC | F9 |
| **Lenovo** | F1 or F2 | F12 |
| **MSI** | DEL | F11 |
| **Gigabyte** | DEL | F12 |
| **Samsung** | F2 | F10 |
| **Toshiba** | F2 | F12 |
| **Intel NUC** | F2 | F10 |

> **Tip:** Not sure which key? Just try F2, DEL, or ESC repeatedly.

---

## Essential Settings

### 1. Disable Secure Boot

**What is Secure Boot?**
It prevents unauthorized operating systems from loading. Linux can work with it, but it's easier to just disable it for installation.

**How to disable:**
1. Go to Security or Boot tab
2. Find Secure Boot option
3. Set to Disabled

![Disable Secure Boot](../../images/secure-boot-disable.png)

> **Note:** You can re-enable it later if you want, but it needs extra setup.

---

### 2. Set UEFI Mode (Not Legacy/CSM)

**What's the difference?**
- **UEFI**: Modern boot method, required for GPT partitions
- **Legacy/CSM**: Old BIOS mode, uses MBR partitions

**Why UEFI?**
- Supports drives over 2TB
- Faster boot
- Better security
- This guide assumes UEFI

**How to set it:**
1. Go to Boot tab
2. Find Boot Mode or UEFI/Legacy Boot
3. Set to UEFI Only
4. Disable CSM if present

```
UEFI Mode: Enabled
CSM Support: Disabled
Secure Boot: Disabled
```

---

### 3. Enable AHCI Mode (For SATA drives)

**What is AHCI?**
Advanced Host Controller Interface enables features like hot-swapping for SATA drives.

**How to set it:**
1. Go to Advanced or Storage tab
2. Find SATA Mode or SATA Configuration
3. Set to AHCI (not IDE or RAID)

> **Warning:** If Windows is installed in IDE mode, this will break Windows boot. Look up how to enable AHCI in Windows first if you're dual-booting.

---

### 4. Disable Fast Boot (Optional but Recommended)

**What is Fast Boot?**
Skips hardware checks for faster boot times. Can mess with USB detection and dual-boot setups.

**How to disable:**
1. Go to Boot tab
2. Find Fast Boot option
3. Set to Disabled

---

### 5. Virtualization Settings (If needed)

If you'll use VMs:

1. Go to Advanced or CPU Configuration
2. Enable:
   - **Intel VT-x** or **AMD-V** (CPU virtualization)
   - **Intel VT-d** or **AMD-Vi** (IOMMU for GPU passthrough)

---

## Boot Order

Set your USB as the first boot device:

1. Go to Boot tab
2. Find Boot Priority or Boot Order
3. Move USB Drive to the top
4. Or use the Boot Menu Key (F12, F8, etc.) at startup

### Boot Order Example:
```
1. USB Hard Drive (UEFI)
2. Internal SSD/HDD
3. Network Boot
```

---

## Pre-Flight Checklist

Before saving:

- [ ] **Secure Boot:** Disabled
- [ ] **Boot Mode:** UEFI Only
- [ ] **CSM:** Disabled
- [ ] **SATA Mode:** AHCI
- [ ] **Fast Boot:** Disabled (optional)
- [ ] **Boot Order:** USB first

### Save and Exit:
- Press **F10** to save and exit
- Confirm with **Yes** or **Enter**

---

## Troubleshooting

### USB Drive Not Detected

1. Try a different USB port (USB 2.0 ports work better)
2. Make sure USB was created correctly (see [Create Bootable USB](create-bootable-usb.md))
3. Disable Fast Boot
4. Enable USB Legacy Support if available

### "No Bootable Device Found"

1. Verify USB drive was created in UEFI mode, not Legacy
2. Check if Secure Boot is disabled
3. Try recreating the USB drive

### System Boots Directly to Windows

1. Disable Fast Startup in Windows:
   - Control Panel → Power Options → Choose what the power buttons do
   - Click "Change settings that are currently unavailable"
   - Uncheck "Turn on fast startup"
2. Enter Boot Menu (F12, etc.) and select USB drive manually

---

## Understanding the Terms

| Term | Description |
|------|-------------|
| **BIOS** | Basic Input/Output System - old firmware interface |
| **UEFI** | Unified Extensible Firmware Interface - modern replacement for BIOS |
| **GPT** | GUID Partition Table - modern partition scheme, requires UEFI |
| **MBR** | Master Boot Record - old partition scheme, works with Legacy BIOS |
| **CSM** | Compatibility Support Module - allows UEFI to boot Legacy systems |
| **Secure Boot** | Security feature that validates boot software signatures |
| **AHCI** | Advanced Host Controller Interface - enables advanced SATA features |

---

## Next Steps

Once your BIOS is configured:

→ [Create Bootable USB](create-bootable-usb.md)

---

<div align="center">

[← Back to Main Guide](../../README.md) | [Next: Create Bootable USB →](create-bootable-usb.md)

</div>
