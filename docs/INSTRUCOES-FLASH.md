# 📱 FLASHING INSTRUCTIONS - Docker/LXC/NetHunter Kernel for POCO X5 5G

**Date:** 2026-02-02  
**Kernel Version:** v1 (Build v12)  
**Device:** POCO X5 5G (moonstone/rose)  
**Android:** 13-14  

---

## ⚠️ CRITICAL SAFETY WARNINGS - READ BEFORE PROCEEDING

### **🚨 RISKS YOU MUST UNDERSTAND:**

1. **BOOTLOOP RISK:** This kernel has NEVER been tested on actual hardware. It may cause bootloops.
2. **DATA LOSS:** Always backup your data before flashing ANY custom kernel.
3. **BRICK RISK:** Improper flashing can soft-brick your device (recoverable via fastboot).
4. **WARRANTY:** This WILL void your warranty if you still have one.
5. **SLOT A PROTECTION:** Your slot A boot partition will be modified. Keep slot B safe as fallback.

### **❌ DO NOT PROCEED IF:**
- You are not comfortable using fastboot/recovery
- You haven't backed up your important data
- You don't have access to a PC for recovery
- You don't understand what a bootloop is
- You're using this as your only phone without backup device

### **✅ PREREQUISITES:**
- [x] Unlocked bootloader
- [x] Custom recovery installed (TWRP/OrangeFox recommended)
- [x] Full device backup (including boot.img)
- [x] ADB and Fastboot tools installed on PC
- [x] USB cable (good quality, not damaged)
- [x] Battery charged >50%
- [x] Understanding of recovery/fastboot mode

---

## 📦 PACKAGE INFORMATION

### **Flashable ZIP:**
```
Filename: Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip
Size: 18 MB
MD5: ba4fbe9f397fb80e7c65b87849c3283b
Location: ~/Projetos/android16-kernel/
```

### **Kernel Image (inside ZIP):**
```
Filename: Image.gz
Size: 15 MB (compressed), 31 MB (uncompressed)
MD5: 5878d68818b3295aeca7d61db9f14945
Compiler: Android NDK r26d Clang 17.0.2
Build Date: 2026-02-02 13:57:08 BRT
```

### **Features Enabled:**
- ✅ Docker support (full cgroups, namespaces)
- ✅ LXC container support
- ✅ Kali NetHunter compatibility
- ✅ Overlay filesystem (OverlayFS)
- ✅ Bridge networking (VETH, BRIDGE)
- ✅ USB Gadget HID (keyboard/mouse emulation)
- ✅ Wireless extensions (monitor mode capable - hardware dependent)
- ✅ All stock features preserved

---

## 🎯 RECOMMENDED TESTING METHOD (SAFEST)

### **Method 1: Temporary Boot Test (NO PERMANENT CHANGES)**

This method boots the kernel ONCE without modifying your boot partition. If it fails, just reboot normally.

#### **Step 1: Extract kernel from ZIP**
```bash
# On your PC:
cd ~/Projetos/android16-kernel/
unzip Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip Image.gz
mv Image.gz test-kernel.img
```

#### **Step 2: Reboot to fastboot**
```bash
# On device or PC:
adb reboot bootloader

# Or manually: Power off, then hold Vol- + Power
```

#### **Step 3: Temporarily boot the kernel**
```bash
# On PC:
fastboot boot test-kernel.img

# Output should show:
# Sending 'boot.img' (15728 KB)                      OKAY [  0.xxx s]
# Booting                                            OKAY [  0.xxx s]
# Finished. Total time: 0.xxx s
```

#### **Step 4: Monitor boot process**
```bash
# Watch the device screen - it should boot normally
# Once booted, connect via ADB:
adb wait-for-device
adb shell

# Check kernel version:
uname -a
# Should show: Linux version 5.4.191 ... (clang version 17.0.2)

# Check Docker support:
dmesg | grep -i docker
dmesg | grep -i cgroup
dmesg | grep -i overlay

# Verify config (if available):
cat /proc/config.gz | gunzip | grep -E "CGROUP|NAMESPACE|OVERLAY" | head -20
```

#### **Step 5: Test Docker (if boot succeeded)**
```bash
# Install Docker via Termux or your preferred method
# Try running a simple container
# If successful, proceed to permanent installation
```

#### **Step 6: Revert (if needed)**
```bash
# Just reboot the device:
adb reboot

# Device will boot with original kernel (temporary test didn't modify anything)
```

---

## 🔥 PERMANENT INSTALLATION METHOD (AFTER SUCCESSFUL TEST)

⚠️ **ONLY DO THIS AFTER METHOD 1 SUCCEEDED!**

### **Method 2A: Flash via Recovery (RECOMMENDED)**

#### **Step 1: Backup current boot partition**
```bash
# In TWRP/OrangeFox:
# Backup > Select Boot partition > Swipe to Backup
# Or via ADB:
adb shell dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img
adb pull /sdcard/boot_backup.img ~/device-backups/
```

#### **Step 2: Transfer ZIP to device**
```bash
# On PC:
adb push ~/Projetos/android16-kernel/Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip /sdcard/
```

#### **Step 3: Verify MD5 on device (optional but recommended)**
```bash
adb shell md5sum /sdcard/Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip
# Should output: ba4fbe9f397fb80e7c65b87849c3283b
```

#### **Step 4: Boot to recovery**
```bash
adb reboot recovery
# Or manually: Power off, then hold Vol+ + Power
```

#### **Step 5: Flash the ZIP**
```
In TWRP/OrangeFox:
1. Tap "Install"
2. Navigate to /sdcard/
3. Select "Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip"
4. Swipe to confirm flash

Expected output:
========================================
  Docker/LXC/NetHunter Custom Kernel
  for POCO X5 5G (moonstone/rose)
========================================

Features enabled:
  - Docker & LXC support
  - Kali NetHunter compatible
  - Overlay filesystem
  - Full cgroups & namespaces

Installing kernel...

[Installation process...]
Done!
```

#### **Step 6: DO NOT REBOOT YET - Verify installation**
```bash
# In recovery, open Advanced > Terminal (or connect via ADB)
# No easy way to verify in recovery, so just ensure no errors appeared
```

#### **Step 7: Reboot and test**
```
Tap "Reboot System"

Monitor boot:
- Should see boot animation
- Should reach lock screen/home screen
- If bootloop: Force power off (hold Power 10s), boot to recovery, restore boot backup
```

---

### **Method 2B: Flash via Fastboot (ALTERNATIVE)**

⚠️ **More complex, requires extracting boot.img and repacking. Use Method 2A instead.**

---

## 🆘 RECOVERY PROCEDURES (IF SOMETHING GOES WRONG)

### **Scenario 1: Device won't boot (bootloop)**

#### **Option A: Restore from backup (if you made one)**
```bash
# Boot to recovery (hold Vol+ + Power)
# In TWRP: Restore > Select Boot backup > Swipe to Restore

# Or via fastboot:
adb reboot bootloader
fastboot flash boot ~/device-backups/boot_backup.img
fastboot reboot
```

#### **Option B: Flash stock boot.img**
```bash
# Download stock ROM for your device
# Extract boot.img from ROM ZIP
adb reboot bootloader
fastboot flash boot boot_stock.img
fastboot reboot
```

#### **Option C: Flash stock ROM (nuclear option)**
```bash
# Download official fastboot ROM from Xiaomi
# Follow official flashing guide
# WARNING: This WILL wipe data (unless you use save-userdata method)
```

### **Scenario 2: Device boots but Docker doesn't work**
```bash
# Kernel is working, but Docker not detected:
# 1. Check kernel version: uname -a
# 2. Check config: cat /proc/config.gz | gunzip | grep DOCKER
# 3. Try reinstalling Docker
# 4. Check dmesg for errors: dmesg | grep -i error

# If nothing works, revert to stock kernel and report issue
```

### **Scenario 3: Device boots but unstable (crashes, reboots)**
```bash
# Kernel has bugs or incompatibilities:
# 1. Boot to recovery
# 2. Flash stock kernel or restore backup
# 3. Collect logs before reverting:
adb shell dmesg > ~/logs/custom-kernel-dmesg.log
adb logcat -d > ~/logs/custom-kernel-logcat.log
```

---

## 🔍 POST-INSTALLATION VERIFICATION

### **Check 1: Kernel version**
```bash
adb shell uname -a
# Expected: Linux version 5.4.191 ... (clang version 17.0.2)
```

### **Check 2: Docker support in dmesg**
```bash
adb shell dmesg | grep -i "docker\|cgroup\|namespace\|overlay"
# Should show cgroup, namespace initialization messages
```

### **Check 3: Config verification**
```bash
adb shell cat /proc/config.gz | gunzip | grep -E "CONFIG_CGROUPS|CONFIG_NAMESPACES|CONFIG_OVERLAY_FS"
# Should show:
# CONFIG_CGROUPS=y
# CONFIG_NAMESPACES=y
# CONFIG_OVERLAY_FS=y
# (and many more)
```

### **Check 4: Install Docker**
```bash
# Follow your preferred Docker installation method
# Termux: pkg install root-repo && pkg install docker
# Or use custom Docker build for Android

# Test Docker:
docker --version
docker run hello-world
```

### **Check 5: Test NetHunter (if needed)**
```bash
# Install Kali NetHunter app
# Try starting chroot environment
# Test HID keyboard emulation
# Test wireless capabilities (hardware dependent)
```

---

## 📊 VERIFICATION CHECKLIST

Use this checklist after installation:

```
POST-FLASH VERIFICATION:
[ ] Device boots to home screen
[ ] No unusual crashes or reboots
[ ] Kernel version shows 5.4.191 (clang 17.0.2)
[ ] dmesg shows cgroup/namespace initialization
[ ] /proc/config.gz contains Docker configs
[ ] Docker installs successfully
[ ] Docker runs simple container (hello-world)
[ ] NetHunter app installs (if needed)
[ ] NetHunter chroot starts (if needed)
[ ] All stock features work (WiFi, calls, camera, etc.)
[ ] Battery life acceptable
[ ] Performance acceptable
```

---

## 📁 IMPORTANT FILES & LOCATIONS

### **On PC:**
```
~/Projetos/android16-kernel/
├── Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip  ← FLASHABLE ZIP
├── successful-builds/
│   ├── Image-v12-20260202-135708.gz                ← KERNEL BACKUP
│   └── config-v12-20260202-135708                  ← CONFIG BACKUP
├── anykernel3-moonstone/                           ← AnyKernel3 source
│   └── Image.gz                                    ← Kernel in AK3
├── BUILD_SUCCESS_REPORT.md                         ← Build details
└── FLASHING_INSTRUCTIONS.md                        ← This file

~/device-backups/  (create this!)
└── boot_backup.img                                 ← YOUR BACKUP!
```

### **On Device:**
```
/sdcard/Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip  ← Transferred ZIP
/dev/block/by-name/boot                                ← Boot partition (slot A)
/dev/block/by-name/boot_a                              ← Boot partition (explicit A)
/dev/block/by-name/boot_b                              ← Boot partition (fallback B)
```

---

## 🎓 UNDERSTANDING SLOT-BASED DEVICES

POCO X5 5G uses A/B (seamless) update system:

- **Slot A:** Currently active boot partition
- **Slot B:** Inactive boot partition (fallback)

**When you flash:**
- AnyKernel3 detects active slot automatically
- Flashes to active slot only
- Inactive slot remains untouched (safety fallback)

**If boot fails:**
- Some recoveries auto-switch to slot B
- Or manually: `fastboot --set-active=b`

---

## 📞 QUICK COMMAND REFERENCE

```bash
# === TESTING ===
fastboot boot test-kernel.img                    # Temporary boot
adb shell uname -a                               # Check kernel version
adb shell dmesg | grep -i docker                 # Check Docker support

# === BACKUP ===
adb shell dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img
adb pull /sdcard/boot_backup.img ~/device-backups/

# === FLASHING ===
adb push Docker-LXC-NetHunter-Kernel-POCO-X5-5G-v1.zip /sdcard/
adb reboot recovery                              # Then flash in recovery

# === RECOVERY ===
fastboot flash boot boot_backup.img              # Restore backup
fastboot --set-active=b                          # Switch to slot B
adb reboot bootloader                            # Enter fastboot
adb reboot recovery                              # Enter recovery

# === VERIFICATION ===
adb shell cat /proc/version                      # Kernel version
adb shell cat /proc/config.gz | gunzip | grep DOCKER
adb logcat -d > logcat.txt                       # Capture logs
adb shell dmesg > dmesg.txt                      # Kernel messages
```

---

## ⚡ TROUBLESHOOTING FAQ

### **Q: Device bootloops after flashing**
**A:** Boot to recovery, restore boot backup or flash stock boot.img via fastboot.

### **Q: Kernel version unchanged after flashing**
**A:** Check active slot (`fastboot getvar current-slot`), may have flashed wrong slot.

### **Q: Docker says "kernel doesn't support cgroups"**
**A:** Check `/proc/config.gz` - if missing Docker configs, kernel didn't flash properly.

### **Q: WiFi/Bluetooth/Camera broken after flashing**
**A:** Kernel broke drivers - restore stock kernel immediately.

### **Q: Battery drains faster**
**A:** Docker features use more CPU/RAM - disable if not needed, or revert kernel.

### **Q: How to uninstall custom kernel?**
**A:** Flash stock boot.img or restore boot backup via recovery/fastboot.

### **Q: Is this safe?**
**A:** As safe as any custom kernel (moderate risk). Always keep backups.

---

## 📝 CHANGELOG

### **Version 1 (Build v12) - 2026-02-02**
- Initial release
- Docker support (cgroups, namespaces, overlayfs)
- LXC container support
- Kali NetHunter compatibility
- USB HID gadget support
- Wireless extensions enabled
- Based on stock 5.4.191 kernel source
- Compiled with Android NDK r26d Clang 17.0.2

---

## 🔗 USEFUL LINKS

- **AnyKernel3:** https://github.com/osm0sis/AnyKernel3
- **Docker on Android:** https://github.com/termux/termux-docker
- **Kali NetHunter:** https://www.kali.org/docs/nethunter/
- **XDA Forums (POCO X5 5G):** Search for "moonstone kernel"

---

## ⚖️ LEGAL DISCLAIMER

This custom kernel is provided "AS IS" without warranty of any kind. The author(s) are not responsible for:
- Bricked devices
- Dead SD cards
- Thermonuclear war
- Job loss because your alarm didn't go off
- Any other damage or issues arising from use of this kernel

**YOU are choosing to make these modifications, and YOU take full responsibility.**

---

**REMEMBER:** Always backup before flashing, test temporarily first, and keep slot B safe as fallback!

**Good luck! 🚀**
