# 🐳 Kernel 5.4.302 + Docker/LXC - POCO X5 5G

**Release Date:** 2026-02-03  
**Kernel Version:** 5.4.302  
**Device:** POCO X5 5G (moonstone/rose)  
**Codename:** DevSan AGI Kernel - Docker Edition  
**Target Slot:** Slot B (safe testing)

---

## 🎯 WHAT'S NEW

Este kernel adiciona **suporte completo a Docker/LXC/Halium** ao kernel base 5.4.302.

### Features Adicionadas

✅ **Docker/Container Support:**
- User namespaces (USER_NS)
- PID namespaces (PID_NS)
- Network namespaces (NET_NS)
- Cgroup device controller (CGROUP_DEVICE)
- Cgroup PID controller (CGROUP_PIDS)
- OverlayFS (OVERLAY_FS) para storage
- Memory cgroup (MEMCG)

✅ **Networking:**
- Bridge networking (BRIDGE)
- Netfilter/iptables (NETFILTER)
- Advanced routing

✅ **Security:**
- AppArmor support (SECURITY_APPARMOR)
- AppArmor como default security module

✅ **Halium/Ubuntu Touch:**
- System V IPC (SYSVIPC)
- POSIX message queues (POSIX_MQUEUE)
- Checkpoint/restore (CHECKPOINT_RESTORE)

---

## 📦 ARTIFACTS

### 1. Kernel Binary (Image.gz)
```
File:     Image.gz
Size:     19MB
SHA256:   (ver SHA256SUMS.txt)
Location: arch/arm64/boot/Image.gz
```

**Uso:**
```bash
# Boot temporário (não flasha)
fastboot boot Image.gz

# Verificar boot
adb shell uname -a
```

### 2. AnyKernel3 ZIP (Flashável)
```
File:     DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip
Size:     22MB
SHA256:   (ver SHA256SUMS.txt)
Target:   Slot B (boot_b partition)
```

**Instalação:**
```bash
# 1. Copiar ZIP para device
adb push DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip /sdcard/

# 2. Reboot para recovery
adb reboot recovery

# 3. Flash via TWRP:
#    - Install
#    - Selecionar o ZIP
#    - Flash to Slot B
#    - Reboot
```

### 3. Kernel Config
```
File:     kernel-config.txt
Size:     179KB
Format:   Plain text (.config)
```

Configuração completa usada na compilação. Use para:
- Verificar configs habilitadas
- Recompilar com mesmas configurações
- Debug de problemas

---

## 🔧 BUILD DETAILS

### Toolchain
- **Compiler:** Clang 17.0.2 (Android NDK r26d)
- **Target:** ARM64 (aarch64-linux-gnu)
- **Architecture:** ARMv8.2-A (Snapdragon 695)
- **Build Host:** Arch Linux (Kernel Zen 6.18.7)
- **CPU:** AMD Ryzen 7 5700G (16 threads)

### Build Flags
```bash
ARCH=arm64
SUBARCH=arm64
CC=clang
CROSS_COMPILE=aarch64-linux-gnu-
KCFLAGS="-Wno-error"  # Allow compilation with techpack warnings
KAFLAGS="-Wno-error"
```

### Compilation Time
- **Estimated:** 30-60 minutes (incremental build)
- **Jobs:** -j16 (16 parallel threads)

### Base Config
- **Defconfig:** moonstone_defconfig
- **Additions:** 211 Docker/LXC/Halium configs (from configs/docker-lxc.config)

---

## ✅ VERIFIED CONFIGS

Todas as configs críticas foram verificadas e estão **HABILITADAS**:

| Config | Status | Função |
|--------|--------|--------|
| `CONFIG_USER_NS` | ✅ | User namespaces (Docker containers) |
| `CONFIG_PID_NS` | ✅ | PID isolation |
| `CONFIG_NET_NS` | ✅ | Network isolation |
| `CONFIG_CGROUP_DEVICE` | ✅ | Device access control |
| `CONFIG_CGROUP_PIDS` | ✅ | Process limit control |
| `CONFIG_SYSVIPC` | ✅ | System V IPC (Halium) |
| `CONFIG_POSIX_MQUEUE` | ✅ | Message queues |
| `CONFIG_OVERLAY_FS` | ✅ | Docker storage driver |
| `CONFIG_SECURITY_APPARMOR` | ✅ | AppArmor LSM (Halium) |
| `CONFIG_DEFAULT_SECURITY_APPARMOR` | ✅ | AppArmor as default |
| `CONFIG_MEMCG` | ✅ | Memory cgroup |
| `CONFIG_BRIDGE` | ✅ | Bridge networking |
| `CONFIG_NETFILTER` | ✅ | iptables/netfilter |

**Verificação local:**
```bash
grep -E "(USER_NS|CGROUP_DEVICE|OVERLAY_FS)" kernel-config.txt
```

---

## 🧪 TESTING

### Pre-Flash Testing (Recomendado)

Antes de flashar permanentemente, teste temporariamente:

```bash
# 1. Boot device em fastboot mode
adb reboot bootloader

# 2. Boot temporário (NÃO flasha)
fastboot boot Image.gz

# 3. Device boota com novo kernel (se falhar, reboot restaura original)

# 4. Verificar versão do kernel
adb shell uname -a
# Output esperado: Linux localhost 5.4.302-...

# 5. Testar Docker (se instalado)
adb shell
su
docker info

# 6. Verificar dmesg para erros
adb shell dmesg | grep -i error
adb shell dmesg | grep -i warn
```

### Post-Flash Validation

Após flashar via AnyKernel3 ZIP:

```bash
# 1. Verificar slot ativo
adb shell getprop ro.boot.slot_suffix
# Output esperado: _b

# 2. Verificar versão
adb shell uname -a

# 3. Testar configs Docker
adb shell
su
cat /proc/config.gz | gunzip | grep -E "(USER_NS|OVERLAY_FS|CGROUP_DEVICE)"
# Todos devem mostrar =y
```

---

## 📝 CHECKSUMS

Verificar integridade dos arquivos:

```bash
# No diretório do release:
sha256sum -c SHA256SUMS.txt

# Saída esperada:
# Image.gz: SUCESSO
# DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip: SUCESSO
# kernel-config.txt: SUCESSO
```

**SHA256SUMS.txt:**
```
4db63467d9961781feb8ab0e1430da2a09a5bb9aeff418e91f3bfd8b9c6c00d4  Image.gz
...
```

---

## ⚠️ IMPORTANT NOTES

### 1. Slot B Target
Este kernel **força instalação no Slot B** via AnyKernel3:
- **Slot A permanece intocado** (seu kernel original Android)
- Se algo falhar, reboot e mude para Slot A via fastboot
- Sempre mantenha Slot A funcional como backup

### 2. Warnings During Build
Build compilado com `-Wno-error` devido a warnings não-críticos em:
- `techpack/audio/` (format string mismatches)
- `techpack/display/` (type conversions)
- `techpack/video/` (enum conversions)

**Impacto:** Nenhum conhecido. Kernel base sem Docker compila perfeitamente, warnings são apenas nos techpacks proprietários.

### 3. Halium/Ubuntu Touch
Se você planeja rodar Ubuntu Touch/Halium:
- Este kernel tem as configs necessárias
- Ainda precisa de rootfs Halium
- Consulte: https://docs.halium.org/

### 4. Bootloader Unlocked Required
**Device PRECISA ter bootloader desbloqueado:**
```bash
fastboot oem device-info
# Saída deve mostrar: Device unlocked: true
```

Se bloqueado, desbloqueie primeiro (APAGA TODOS OS DADOS):
```bash
fastboot oem unlock
```

---

## 🔄 ROLLBACK

Se kernel não funcionar:

### Método 1: Via Fastboot (Rápido)
```bash
adb reboot bootloader
fastboot set_active a  # Volta para Slot A (kernel original)
fastboot reboot
```

### Método 2: Via Recovery
```bash
adb reboot recovery
# Em TWRP:
# - Advanced > Reboot to Slot A
```

### Método 3: Reflash Stock Boot
```bash
# Use backup em: backups/poco-x5-5g-rose-2025-02-01/device-images/boot.img
adb reboot bootloader
fastboot flash boot_b boot.img
fastboot reboot
```

---

## 📚 DOCUMENTATION

- **Master Guide:** `/README-5.4.302-SLOTB.md`
- **Build Runbook:** `/docs/BUILD-5.4.302-RUNBOOK.md`
- **Build History:** `/docs/HISTORICO-BUILDS.md`
- **Docker Configs:** `/configs/docker-lxc.config`

---

## 🐛 KNOWN ISSUES

### None reported yet

Este é o primeiro release público do kernel Docker/LXC.

**Report issues:**
- GitHub: (seu repo)
- Telegram: @deivisan

---

## 🚀 NEXT STEPS

Após boot bem-sucedido:

1. **Install Docker:**
   ```bash
   # Termux ou root shell
   pkg install docker  # (se disponível)
   # OU compile Docker para ARM64
   ```

2. **Test Containers:**
   ```bash
   docker run hello-world
   docker run -it alpine sh
   ```

3. **Install Halium** (opcional):
   - https://docs.halium.org/en/latest/porting/first-steps.html

4. **Monitor Logs:**
   ```bash
   adb shell dmesg | grep -i docker
   adb shell dmesg | grep -i cgroup
   ```

---

## 🎉 SUCCESS CRITERIA

Kernel considerado **funcional** quando:
- ✅ Device boota sem bootloop
- ✅ `uname -a` mostra versão 5.4.302
- ✅ `/proc/config.gz` contém configs Docker
- ✅ Nenhum kernel panic no dmesg
- ✅ `docker info` funciona (se Docker instalado)

---

## 📜 LICENSE

Este kernel é baseado em código GPL-2.0 da Xiaomi e AOSP.

**Sources:**
- Kernel base: https://github.com/moonstone-devs/android_kernel_xiaomi_moonstone
- Docker configs: Custom (DevSan AGI)
- Build scripts: Custom (DevSan AGI)

**GPL-2.0 Compliance:**
Código-fonte completo disponível em: `/home/deivi/Projetos/android16-kernel/`

---

**Built with ❤️ by DevSan AGI**  
**Date:** 2026-02-03  
**Build ID:** 20260203-131637  
**Toolchain:** Clang 17.0.2 (Android NDK r26d)
