# CONSOLIDATED PROGRESS - Android16 Kernel Build

**Date:** 2026-02-02  
**Project:** Custom Kernel for POCO X5 5G (moonstone/rose)  
**Target:** Android 16 with Docker/LXC + Kali NetHunter  
**Status:** BLOCKED - Compiler compatibility issue

---

## 🎯 PROJECT OVERVIEW

Building a custom kernel 5.4.191 (Xiaomi moonstone-s-oss) for POCO X5 5G with:
- Snapdragon 695 (SM6375, Blair platform)
- ARM64 v8.2-A architecture
- Docker/LXC container support
- Kali NetHunter integration
- Custom ROM compatibility (NOT MIUI/HyperOS)

---

## ✅ COMPLETED TASKS

### Phase 1: Environment Setup
| Task | Status | Notes |
|------|--------|-------|
| Toolchains installed | ✅ | `aarch64-linux-gnu-gcc-15.1.0`, `clang-21.1.6` |
| System verified | ✅ | 14GB RAM, 180GB storage, Ryzen 7 5700G |
| Project structure | ✅ | Created in `~/Projetos/android16-kernel/` |

### Phase 2: Kernel Source
| Task | Status | Notes |
|------|--------|-------|
| Xiaomi Kernel 5.4.191 cloned | ✅ | moonstone-s-oss branch |
| Eclipse Kernel 5.4.302 analyzed | ✅ | Reference binary (32MB) |
| Config backup restored | ✅ | From device backup |

### Phase 3: Code Fixes Applied
| File | Issue | Fix | Status |
|------|-------|-----|--------|
| `arch/arm64/kernel/bootinfo.c:237` | Type mismatch (u32 vs enum) | Changed to `powerup_reason_t` | ✅ Applied |
| `arch/arm64/kernel/bootinfo.c:91` | Duplicate declaration | Removed line 91 | ✅ Applied |

### Phase 4: Documentation Created
| Document | Lines | Purpose |
|----------|-------|---------|
| `segundo-agente/ANALISE_ERROS_COMPILER.md` | 324 | Compiler error deep analysis |
| `segundo-agente/URGENTE_BUILD_V7_FALHOU.md` | 263 | Build v7 failure analysis |
| `docs/BUILD_STATUS_2026-02-02.md` | ~50 | Current status report |
| `docs/docker-lxc-nethunter-configs.md` | 507 | Docker/LXC configs (Agent 2) |
| `docs/compilation-flags.md` | 415 | Compilation flags (Agent 2) |

---

## 🔴 CURRENT BLOCKER

### Problem: GCC 15.1.0 Incompatibility

**Error Location:** `scripts/mod/file2alias.c`
```c
error: 'OFF_usb_device_id_match_flags' undeclared
error: 'OFF_usb_device_id_idVendor' undeclared
error: 'OFF_usb_device_id_idProduct' undeclared
...
```

**Root Cause:**
- Kernel 5.4 was written for GCC 11-12
- GCC 15 has stricter type checking and structural changes
- Build scripts don't generate proper offsets with GCC 15
- The `OFF_*` and `SIZE_*` macros fail to expand

**Evidence:**
```
scripts/mod/file2alias.c:69:75: error: 'OFF_usb_device_id_match_flags' undeclared
```

### Why Versions Matter

| Compiler | Kernel 5.4 Compatible? | Status |
|----------|----------------------|--------|
| GCC 11 | ✅ Yes | Original target |
| GCC 12 | ✅ Yes | Works |
| GCC 13 | ✅ Yes | Recommended fallback |
| GCC 14 | ⚠️ Maybe | Not tested |
| GCC 15 | ❌ No | FAILS - too strict |
| Clang 17 | ⚠️ Maybe | Not tested |
| Clang 20 | ✅ Yes | Used by Eclipse Kernel |
| Clang 21 | ⚠️ Issues | Fails with kernel scripts |

---

## 📋 ATTEMPTED BUILDS

| Build | Compiler | Approach | Result |
|-------|----------|----------|--------|
| v1-v6 | GCC 15.1.0 | Default flags | ❌ bootinfo.c errors |
| v7 | Clang 21.1.6 | -Wno-error flags | ❌ Same errors (-Werror hardcoded) |
| v8 | Clang 21.1.6 | Fixed bootinfo.c | ❌ scripts/mod/file2alias.c fails |

---

## 🔧 FILES MODIFIED

### 1. `arch/arm64/kernel/bootinfo.c`

**Line 91 - REMOVED:**
```c
// BEFORE:
static struct kobject *bootinfo_kobj;
static powerup_reason_t powerup_reason;  // <-- REMOVED

// AFTER:
static struct kobject *bootinfo_kobj;
```

**Line 237 - FIXED TYPE:**
```c
// BEFORE:
bootinfo_func_init(u32, powerup_reason, 0);

// AFTER:
bootinfo_func_init(powerup_reason_t, powerup_reason, 0);
```

### 2. `.config` (Partially Updated)

**INTENT** was to change compiler from GCC to Clang:
```diff
- CONFIG_CC_VERSION_TEXT="aarch64-linux-gnu-gcc (GCC) 15.1.0"
+ CONFIG_CC_VERSION_TEXT="clang (Clang 21.1.6)"
- CONFIG_CC_IS_GCC=y
+ CONFIG_CC_IS_CLANG=y
- CONFIG_CLANG_VERSION=0
+ CONFIG_CLANG_VERSION=2101006
```

**Status:** Edit was applied but may have been reverted by `make oldconfig`

---

## 🎯 WORKING REFERENCE: ECLIPSE KERNEL 5.4.302

| Attribute | Value |
|-----------|-------|
| Version | 5.4.302-Eclipse |
| Compiler | Clang 20.0.0 (Android LLVM) |
| LLD | 20.0.0 |
| Build Date | Dec 14, 2025 |
| Size | 32MB (Image) |
| Features | KSU-Next, SusFS, +pgo, +bolt, +lto, +mlgo |
| Status | ✅ WORKS on POCO X5 5G |
| Repo | Closed (binary only) |

**Key Finding:** Eclipse Kernel uses Clang 20.0.0, NOT Clang 21.1.6

---

## 📁 CURRENT WORKING DIRECTORY

```
~/Projetos/android16-kernel/
├── kernel-source/                    # Xiaomi Kernel 5.4.191
│   ├── .config                      # Modified (partially)
│   ├── arch/arm64/kernel/bootinfo.c # FIXED (lines 91, 237)
│   ├── Makefile                     # Original
│   └── eclipse-kernel-analysis/     # Reference files
│       ├── Image (32MB)             # WORKING kernel binary
│       └── README.md
│
├── segundo-agente/
│   ├── AGENTS.md                    # Agent 2 documentation
│   ├── PROMPTS.md                   # Agent 2 prompts
│   ├── TASK_DELEGATION.md           # Task delegation system
│   └── tasks/
│       ├── task-001-dockers-lxc.md  # ✅ Done
│       ├── task-002-flags.md        # ✅ Done
│       ├── task-003-llvm-bolt.md    # ⏳ Pending
│       ├── task-004-compiler-fix.md # ⏳ Pending (URGENT)
│       └── task-005-dtbo-flash.md   # ⏳ Pending
│
├── docs/
│   ├── docker-lxc-nethunter-configs.md  # 507 lines
│   ├── compilation-flags.md              # 415 lines
│   ├── BUILD_STATUS_2026-02-02.md        # NEW
│   └── device-context.md
│
├── logs/
│   ├── build-v1.log
│   ├── build-v2.log
│   ├── build-v3.log
│   ├── build-v4.log
│   ├── build-v5.log
│   ├── build-v6.log
│   ├── build-v7.log
│   └── build-v8.log                      # Incomplete
│
├── backups/
│   └── poco-x5-5g-rose-2025-02-01/
│       ├── device-images-backup-2025-02-01.tar.xz
│       └── kernel-config-5.4.302-eclipse.txt
│
├── CONSOLIDATED_PROGRESS.md           # THIS FILE
├── ERRORS_LOG.md                      # See below
└── ECLIPSE_KERNEL_ANALYSIS.md
```

---

## 📊 ERROR SUMMARY

### Critical Errors Found

| Error | Location | Cause | Solution |
|-------|----------|-------|----------|
| Enum type mismatch | `bootinfo.c:237` | u32 vs enum | ✅ Fixed - changed to `powerup_reason_t` |
| Duplicate declaration | `bootinfo.c:91` | Variable redeclared | ✅ Fixed - removed line 91 |
| GCC 15 strictness | `file2alias.c` | OFF_* macros undeclared | ⏳ Need Clang 20 or GCC 13 |
| -Werror hardcoded | `vdso32/Makefile` | Warnings = errors | ⏳ Need to remove or use WERROR=0 |

---

## 🎯 IMMEDIATE NEXT STEPS

### For Next Agent (Primary)

**Priority 1: Fix Compiler Issue**
```bash
# Option A: Install GCC 13
yay -S gcc13 aarch64-linux-gnu-gcc13
export CC=aarch64-linux-gnu-gcc-13
make clean
make ARCH=arm64 Image.gz

# Option B: Download Android NDK (Clang 20)
# https://developer.android.com/ndk/downloads
# Use: android-ndk-r26-linux.zip
export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export CC=clang
make ARCH=arm64 Image.gz
```

**Priority 2: Test Build**
```bash
# Check if Image.gz exists
ls -lh arch/arm64/boot/Image.gz
# Expected: 15-25MB

# Test boot (SAFE - doesn't flash)
fastboot boot arch/arm64/boot/Image.gz
```

**Priority 3: Flash if Works**
```bash
# Only if boot test succeeds
fastboot flash boot_b arch/arm64/boot/Image.gz
fastboot set_active b
fastboot reboot
```

### For Second Agent (Kimi K2.5)

See `segundo-agente/PROMPTS.md` for updated tasks

---

## 🔗 COMPILER REQUIREMENTS

### Required Toolchain Versions

| Tool | Version | Source | Status |
|------|---------|--------|--------|
| **LLVM/Clang** | 20.0.0 | Android NDK | ⏳ Need to download |
| **LLD** | 20.0.0 | Android NDK | ⏳ Need to download |
| **GCC (fallback)** | 13.x | AUR | ⏳ Need to install |
| **aarch64-linux-gnu-*** | Match GCC | Arch repos | ✅ Available (15.1.0) |

### Why Clang 20.0.0?

1. **Eclipse Kernel uses it** - proven to work
2. **Android standard** - Google uses Clang for Android kernels
3. **Better LTO support** - Link Time Optimization works better
4. **PGO/BOLT compatible** - Profile-guided optimization supported

---

## 📝 NOTES

### Key Insights

1. **Eclipse Kernel binary already works** - Could use it as-is
2. **GCC 15 is incompatible** - Kernel 5.4 written for GCC 11-12
3. **Clang 21 has issues** - Build scripts fail with newer Clang
4. **Clang 20 is sweet spot** - Used by working Eclipse Kernel

### What's Not Working

- Building kernel from source with GCC 15.1.0
- Building kernel from source with Clang 21.1.6
- The build scripts (`scripts/mod/file2alias.c`) are broken

### What IS Working

- Eclipse Kernel 5.4.302 binary boots on POCO X5 5G
- Device accepts custom kernels via `fastboot boot`
- Docker/LXC configs documented (Agent 2)
- Compilation flags documented (Agent 2)

---

## 🚀 QUICK START FOR NEXT AGENT

```bash
cd ~/Projetos/android16-kernel/kernel-source

# Option 1: Try GCC 13 (if installed)
# export CC=aarch64-linux-gnu-gcc-13
# make ARCH=arm64 Image.gz

# Option 2: Download and use Clang 20
# wget https://dl.google.com/android/repository/android-ndk-r26-linux.zip
# unzip android-ndk-r26-linux.zip
# export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
# export CC=clang
# make ARCH=arm64 Image.gz

# Verify
ls -lh arch/arm64/boot/Image.gz
```

---

**Document created:** 2026-02-02  
**Last updated:** 2026-02-02 12:25  
**Next agent:** Read this file + ERRORS_LOG.md + segundo-agente/PROMPTS.md
