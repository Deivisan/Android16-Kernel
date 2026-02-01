# Halium Porting Guide - POCO X5 5G

**Guia completo para portar Halium/Linux para o dispositivo rose/moonstone**

---

## 🎯 O que é Halium?

Halium é um projeto que unifica a Hardware Abstraction Layer (HAL) para rodar GNU/Linux em dispositivos Android. Ele funciona como uma "ponte" entre:

- **Kernel Linux** (open source)
- **Android blobs/drivers** (proprietários)
- **Distribuições Linux** (Ubuntu Touch, Droidian, etc)

### Como funciona:
```
┌─────────────────────────────────────────┐
│  Distro Linux (Ubuntu Touch/Droidian)   │
│  ┌─────────────────────────────────────┐│
│  │  Interface (Phosh/Lomiri/Plasma)    ││
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  Halium Middleware                      │
│  - libhybris (Android → Linux)          │
│  - pulseaudio-module-droid              │
│  - qtubuntu-camera                      │
├─────────────────────────────────────────┤
│  Android Container (LXC)                │
│  - Minimal Android (HALs)               │
│  - RIL (modem), WiFi, Bluetooth         │
│  - Sensors, GPS, Camera                 │
├─────────────────────────────────────────┤
│  Kernel Linux (patched)                 │
│  - Binder IPC modificada                │
│  - Ashmem, ION memory                   │
│  - Device Tree                          │
├─────────────────────────────────────────┤
│  Hardware (POCO X5 5G)                  │
│  - Snapdragon 695, RAM, GPU, etc        │
└─────────────────────────────────────────┘
```

---

## ✅ Pré-requisitos

### Hardware
- POCO X5 5G (rose/moonstone)
- 6GB+ RAM (preferencialmente 8GB)
- 128GB+ storage
- Bootloader desbloqueado ✅ (já está)

### Software
- Linux PC (Ubuntu 20.04+ ou Arch)
- 100GB+ espaço livre
- 16GB+ RAM no PC (recomendado)
- Python 3.6+
- Git configurado

### Conhecimento
- Git/GitHub básico
- Compilação kernel Linux
- Android partitions/layout
- Terminal/command line
- **Paciência** (20-40 horas de trabalho)

---

## 📋 Checklist de Porte

### Fase 1: Preparação
- [ ] Verificar kernel source disponível (Xiaomi GitHub)
- [ ] Identificar device trees similares (SM6375/blair)
- [ ] Documentar partições do device
- [ ] Backup completo de todas as partições
- [ ] Preparar ambiente de build

### Fase 2: Kernel
- [ ] Clonar kernel source
- [ ] Extrair config atual (.config)
- [ ] Habilitar configs necessárias (ver kernel-analysis.md)
- [ ] Aplicar hybris-patches
- [ ] Modificar device tree (dts/dtsi)
- [ ] Compilar kernel (Image.gz)
- [ ] Testar via `fastboot boot` (slot B)

### Fase 3: Halium System
- [ ] Inicializar repo Halium (halium-10.0 ou 11.0)
- [ ] Criar manifest do device (rose.xml)
- [ ] Adicionar repos: device, vendor, kernel
- [ ] Ajustar fixup-mountpoints
- [ ] Compilar system.img
- [ ] Compilar halium-boot.img

### Fase 4: Testes
- [ ] Boot kernel Halium (temporário)
- [ ] Verificar dmesg logs
- [ ] Testar LXC android container
- [ ] Verificar logcat
- [ ] Testar hardware básico (tela, touch)
- [ ] Testar conectividade (WiFi, BT)
- [ ] Testar sensores
- [ ] Testar câmera
- [ ] Testar telefonia (RIL)

### Fase 5: Distribuição
- [ ] Escolher distro (Ubuntu Touch/Droidian/PostmarketOS)
- [ ] Adaptar rootfs para device
- [ ] Configurar initramfs
- [ ] Instalar e testar interface gráfica
- [ ] Configurar apps essenciais
- [ ] Documentar funcionalidades

---

## 🔧 Passo a Passo Detalhado

### 1. Preparar Ambiente de Build

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git gnupg flex bison gperf build-essential \
    zip bzr curl libc6-dev libncurses5-dev:i386 x11proto-core-dev \
    libx11-dev:i386 libreadline6-dev:i386 libgl1-mesa-glx:i386 \
    libgl1-mesa-dev g++-multilib mingw-w64-i686-dev tofrodos \
    python3-markdown libxml2-utils xsltproc zlib1g-dev:i386 \
    schedtool repo liblz4-tool bc lzop imagemagick libncurses5 \
    rsync python3-is-python3

# Arch Linux
sudo pacman -S base-devel git repo
# Instalar halium-devel do AUR
```

### 2. Verificar Kernel Source

```bash
# Verificar se Xiaomi liberou source para moonstone/rose
# https://github.com/MiCode/Xiaomi_Kernel_OpenSource

# Procurar branch: moonstone-q-oss, moonstone-r-oss, etc.
# Se não tiver, extrair do device ou usar generic msm-5.4

# Extrair config atual:
adb shell zcat /proc/config.gz > kernel_defconfig
```

### 3. Obter Device Tree

```bash
# Extrair DTB do device atual:
adb shell dd if=/dev/block/by-name/dtbo_a of=/sdcard/dtbo.img
adb pull /sdcard/dtbo.img

# Extrair DTBs individuais:
# Usar dtc (device tree compiler) para descompilar
for f in *.dtb; do
    dtc -I dtb -O dts "$f" -o "${f%.dtb}.dts"
done

# Documentar compatíveis (strings no DTB):
strings dtbo.img | grep -E "qcom|compatible"
```

### 4. Configurar Kernel

```bash
# Clonar kernel source
git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource -b moonstone-q-oss
# OU usar generic msm-5.4:
git clone https://github.com/android-linux-stable/msm-5.4

cd kernel_source

# Copiar config atual
cp /path/to/kernel_defconfig arch/arm64/configs/rose_defconfig

# Editar config (menu interativo)
make ARCH=arm64 rose_defconfig
make ARCH=arm64 menuconfig

# OU editar manualmente:
# nano arch/arm64/configs/rose_defconfig
```

#### Configs ESSENCIAIS para adicionar:
```
# LXC/Containers
CONFIG_USER_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_MEM_RES_CTLR=y
CONFIG_CGROUP_RDMA=y
CONFIG_CGROUP_PERF=y
CONFIG_SYSVIPC=y
CONFIG_POSIX_MQUEUE=y
CONFIG_IKCONFIG_PROC=y

# Security (Ubuntu Touch)
CONFIG_SECURITY_APPARMOR=y
CONFIG_SECURITY_APPARMOR_DEBUG=y
CONFIG_DEFAULT_SECURITY_APPARMOR=y
CONFIG_DEFAULT_SECURITY="apparmor"

# Virtualization (opcional)
CONFIG_VIRTUALIZATION=y
CONFIG_KVM=y
CONFIG_KVM_ARM_HOST=y
CONFIG_VHOST=y
CONFIG_VHOST_NET=y
```

### 5. Aplicar Patches Halium

```bash
# Clonar hybris-patches
git clone https://github.com/Halium/hybris-patches

cd hybris-patches

# Aplicar patches no kernel
./apply-patches.sh --mb /path/to/kernel_source

# Verificar quais patches foram aplicados:
git log --oneline -20

# Se falhar, aplicar manualmente:
cd /path/to/kernel_source
patch -p1 < /path/to/hybris-patches/patches/0001-binder.patch
patch -p1 < /path/to/hybris-patches/patches/0002-ashmem.patch
# ... etc
```

### 6. Modificar Device Tree

Arquivos a editar (exemplo moonstone):
```
arch/arm64/boot/dts/qcom/
├── moonstone.dts           # Entry point
├── moonstone-pinctrl.dtsi  # GPIO/pinmux
├── blair.dtsi              # SoC base
└── blair-*.dtsi            # Subsistemas
```

Modificações necessárias:
```dts
// Adicionar nó de firmware (se faltando)
firmware: firmware {
    compatible = "android,firmware";
    android,slot-suffixes = "_a", "_b";
    
    fstab: fstab {
        compatible = "android,fstab";
        
        vendor {
            compatible = "android,vendor";
            dev = "/dev/block/by-name/vendor${androidboot.slot_suffix}";
            type = "ext4";
            mnt_flags = "ro,barrier=1";
            fsmgr_flags = "wait,slotselect";
        };
        
        userdata {
            compatible = "android,userdata";
            dev = "/dev/block/by-name/userdata";
            type = "f2fs";
            mnt_flags = "discard,nosuid,nodev,noatime";
            fsmgr_flags = "wait,checkpoint=fs";
        };
    };
};
```

### 7. Compilar Kernel

```bash
cd kernel_source

# Limpar builds anteriores (opcional)
make clean
make mrproper

# Configurar
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
# Ou para Clang (recomendado para Android):
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

# Carregar config
make ARCH=arm64 rose_defconfig

# Compilar (ajustar -j conforme CPUs)
make ARCH=arm64 -j$(nproc) Image.gz

# Verificar resultado:
ls -lh arch/arm64/boot/Image.gz
# Tamanho esperado: 15-25MB
```

**Tempo estimado:** 2-8 horas dependendo do PC

### 8. Testar Kernel (Seguro)

```bash
# Boot temporário (NÃO FLASHA, só testa):
adb reboot bootloader
fastboot boot arch/arm64/boot/Image.gz

# Device vai bootar com novo kernel temporariamente
# Se não funcionar, reboot volta ao kernel antigo

# Capturar logs:
adb shell dmesg > dmesg_halium.log
adb shell /system/bin/logcat > logcat_halium.log

# Verificar se bootou:
adb shell uname -a
# Deve mostrar novo kernel version
```

### 9. Setup Halium Source Tree

```bash
# Criar diretório de build
mkdir -p ~/halium && cd ~/halium

# Inicializar repo (escolher versão)
# Para Android 13 (API 33):
repo init -u https://github.com/Halium/android -b halium-11.0 --depth=1

# Ou halium-10.0 para Android 11:
repo init -u https://github.com/Halium/android -b halium-10.0 --depth=1

# Sincronizar (vai demorar!):
repo sync -c -j8

# Tempo estimado: 2-6 horas (depende da internet)
```

### 10. Criar Manifest do Device

```bash
# Criar arquivo: halium/devices/manifests/xiaomi_rose.xml

mkdir -p halium/devices/manifests/
cat > halium/devices/manifests/xiaomi_rose.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="github" fetch="https://github.com/" />
    <remote name="deivisan" fetch="https://github.com/Deivisan" />
    
    <!-- Device tree -->
    <project path="device/xiaomi/rose" name="android_device_xiaomi_rose" 
             remote="deivisan" revision="halium-11.0" />
    
    <!-- Kernel (usar o que compilamos) -->
    <project path="kernel/xiaomi/rose" name="android_kernel_xiaomi_rose" 
             remote="deivisan" revision="halium-patches" />
    
    <!-- Vendor blobs -->
    <project path="vendor/xiaomi/rose" name="android_vendor_xiaomi_rose" 
             remote="deivisan" revision="halium-11.0" />
    
    <!-- Opcional: Common tree se compartilhado com outros -->
    <!-- <project path="device/xiaomi/sm6375-common" ... /> -->
</manifest>
EOF
```

### 11. Setup Device Tree

```bash
# Criar estrutura device/xiaomi/rose
mkdir -p device/xiaomi/rose
cd device/xiaomi/rose

# Arquivos necessários:
# - Android.bp (build config)
# - AndroidProducts.mk
# - BoardConfig.mk
# - device.mk
# - extract-files.sh
# - setup-makefiles.sh
# - lineage_rose.mk (ou halium_rose.mk)
# - vendorsetup.sh

# Exemplo BoardConfig.mk:
cat > BoardConfig.mk << 'EOF'
# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a55

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := moonstone
TARGET_NO_BOOTLOADER := false

# Platform
TARGET_BOARD_PLATFORM := blair
TARGET_BOARD_PLATFORM_GPU := qcom-adreno619

# Kernel
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_SOURCE := kernel/xiaomi/rose
TARGET_KERNEL_CONFIG := rose_defconfig
TARGET_KERNEL_CLANG_COMPILE := true

# Partições
BOARD_BOOTIMAGE_PARTITION_SIZE := 134217728  # 128MB
BOARD_DTBOIMG_PARTITION_SIZE := 25165824     # 24MB
BOARD_SUPER_PARTITION_SIZE := 9126805504     # ~8.5GB
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor product
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9122611200

BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 92160000
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE := 30720000

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product

# Recovery
TARGET_RECOVERY_FSTAB := $(LOCAL_PATH)/recovery.fstab
BOARD_INCLUDE_RECOVERY_DTBO := true
TARGET_USERIMAGES_USE_F2FS := true

# HALIUM específico
TARGET_HALIUM_BUILD := true
TARGET_USES_LOGD := true
EOF
```

### 12. Ajustar fixup-mountpoints

```bash
# Editar halium/hybris-boot/fixup-mountpoints

# Adicionar entrada para rose/moonstone:
cat >> fixup-mountpoints << 'EOF'

"rose"|"moonstone")
    sed -i \
        -e 's block/bootdevice/by-name/boot sde9 ' \
        -e 's block/bootdevice/by-name/boot_a sde9 ' \
        -e 's block/bootdevice/by-name/boot_b sde28 ' \
        -e 's block/bootdevice/by-name/dtbo sde13 ' \
        -e 's block/bootdevice/by-name/dtbo_a sde13 ' \
        -e 's block/bootdevice/by-name/dtbo_b sde32 ' \
        -e 's block/bootdevice/by-name/vbmeta sde12 ' \
        -e 's block/bootdevice/by-name/vbmeta_a sde12 ' \
        -e 's block/bootdevice/by-name/vbmeta_b sde31 ' \
        -e 's block/bootdevice/by-name/userdata sda31 ' \
        -e 's block/bootdevice/by-name/persist sda4 ' \
        -e 's block/bootdevice/by-name/modem sde21 ' \
        "$@"
    ;;
EOF
```

### 13. Compilar Halium

```bash
cd ~/halium

# Inicializar ambiente
source build/envsetup.sh

# Escolher device
breakfast rose

# Compilar hybris-boot (kernel + initramfs Halium)
make hybris-boot

# Compilar system.img (Android minimal para container)
make systemimage

# Ou tudo de uma vez:
mka halium-boot systemimage

# Resultados em:
# out/target/product/rose/hybris-boot.img
# out/target/product/rose/system.img
```

### 14. Testar Halium Boot

```bash
# Boot temporário para testes:
adb reboot bootloader

# Flash imagens em slot B (mantém A seguro):
fastboot flash boot_b out/target/product/rose/hybris-boot.img
fastboot flash system_b out/target/product/rose/system.img
fastboot --disable-verity --disable-verification flash vbmeta_b stock_vbmeta.img

# Ativar slot B e bootar:
fastboot set_active b
fastboot reboot

# Se não bootar, volta para A:
fastboot set_active a
fastboot reboot
```

### 15. Debug e Troubleshooting

```bash
# Capturar logs durante boot:
adb shell dmesg > dmesg_rose.log
adb shell /system/bin/logcat -b all > logcat_all.log

# Verificar LXC container:
adb shell lxc-checkconfig
adb shell systemctl status lxc@android

# Testar hardware:
adb shell test_hwcomposer
adb shell test_sensors
adb shell test_gps
adb shell test_wifi

# Verificar binder:
adb shell ls -la /dev/binder*
adb shell ls -la /dev/anbox-binder

# Strace para debug:
adb shell strace -f /usr/bin/lxc-start
```

---

## 🐛 Troubleshooting Comum

### Problema: Kernel não boota (bootloop)
**Causas:**
- Config faltando (verity, etc)
- DTB incorreto
- Boot image formato errado

**Solução:**
```bash
# Verificar configs obrigatórias:
CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP=y
CONFIG_KALLSYMS=y
CONFIG_DEBUG_KERNEL=y

# Gerar boot.img correto:
mkbootimg --kernel Image.gz --ramdisk ramdisk.cpio.gz \
    --cmdline "console=ttyMSM0,115200n8 androidboot.hardware=qcom" \
    --base 0x00000000 --pagesize 4096 \
    --os_version 13.0.0 --os_patch_level 2025-02 \
    -o boot.img
```

### Problema: LXC container não inicia
**Causas:**
- Cgroups não configurados
- Binder nodes não criados
- Permissões incorretas

**Solução:**
```bash
# Verificar cgroups:
adb shell cat /proc/cgroups
adb shell mount | grep cgroup

# Criar binder nodes manualmente (se necessário):
adb shell mkdir -p /dev/binder
adb shell mount -t binder binder /dev/binder

# Verificar permissões:
adb shell ls -la /var/lib/lxc/android/
```

### Problema: Tela preta (display não funciona)
**Causas:**
- HWC (Hardware Composer) falhando
- DRM driver incorreto
- Framebuffer não inicializado

**Solução:**
```bash
# Testar SW rendering:
adb shell export EGL_PLATFORM=surfaceflinger
adb shell test_hwcomposer

# Verificar DRM:
adb shell ls -la /sys/class/drm/
adb shell cat /sys/kernel/debug/dri/state

# Logs do compositor:
adb shell journalctl -u lxc@android | grep -i hwc
```

### Problema: WiFi/Bluetooth não funcionam
**Causas:**
- Firmware não carregado
- HAL não comunicando
- MAC address não setado

**Solução:**
```bash
# Verificar firmware:
adb shell ls -la /vendor/firmware/
adb shell dmesg | grep -i firmware

# Carregar manualmente:
adb shell insmod /vendor/lib/modules/wlan.ko

# Verificar MAC:
adb shell cat /persist/wifi/macaddress
adb shell ifconfig wlan0
```

### Problema: Modem/RIL não funciona
**Causas:**
- Firmware modem não encontrado
- RIL library não carregando
- Permissões de rádio

**Solução:**
```bash
# Verificar firmware modem:
adb shell ls -la /vendor/firmware/image/
adb shell dmesg | grep -i mpss

# Verificar RIL:
adb shell getprop | grep ril
adb shell logcat -b radio | grep -i error

# Logs do RIL:
adb shell logcat -s RILQmiLog:RILCLog
```

---

## 📊 Status de Funcionalidades

### Esperado para Snapdragon 695:

| Componente | Dificuldade | Status Esperado |
|------------|-------------|-----------------|
| **Boot** | ⭐ Fácil | ✅ Funciona com kernel correto |
| **Display** | ⭐⭐ Médio | ✅ Funciona (hwcomposer ou software) |
| **Touch** | ⭐ Fácil | ✅ Funciona (input event) |
| **WiFi** | ⭐⭐ Médio | ✅ Funciona (via Android HAL) |
| **Bluetooth** | ⭐⭐ Médio | ✅ Funciona (via Android HAL) |
| **Audio** | ⭐⭐⭐ Difícil | ⚠️ Pulseaudio com droid module |
| **Câmera** | ⭐⭐⭐⭐ Muito Difícil | ⚠️ Via Android container (slow) |
| **GPS** | ⭐⭐ Médio | ✅ Funciona (via HAL) |
| **Sensores** | ⭐⭐ Médio | ✅ Funciona (via HAL) |
| **Modem/3G/4G/5G** | ⭐⭐⭐⭐ Muito Difícil | ⚠️ RIL complexo |
| **GPU Aceleração** | ⭐⭐⭐⭐⭐ Extremo | ❌ Software rendering (no Mesa) |
| **USB/Gadget** | ⭐⭐ Médio | ✅ Funciona |
| **NFC** | ⭐⭐⭐ Difícil | ⚠️ Depende de HAL específico |
| **Fingerprint** | ⭐⭐⭐ Difícil | ⚠️ Driver específico |
| **Bateria/Power** | ⭐⭐ Médio | ✅ Funciona (bq27xxx) |
| **LEDs** | ⭐ Fácil | ✅ Funciona |
| **Vibração** | ⭐ Fácil | ✅ Funciona |

---

## 🎯 Critérios de Sucesso

### Mínimo Viável (MVP):
- [ ] Kernel boota sem panics
- [ ] Display funciona (mesmo que software rendering)
- [ ] Touch responde
- [ ] WiFi conecta
- [ ] LXC container inicia
- [ ] Interface gráfica abre

### Funcional Completo:
- [ ] Tudo do MVP +
- [ ] Bluetooth funciona
- [ ] Audio funciona (chamadas, media)
- [ ] Câmera tira fotos
- [ ] Sensores funcionam
- [ ] GPS funciona
- [ ] Bateria reporta corretamente
- [ ] Suspend/resume funciona

### Excelente:
- [ ] Tudo do Funcional +
- [ ] GPU aceleração (se drivers liberados)
- [ ] 5G funciona (modem completo)
- [ ] NFC funciona
- [ ] Fingerprint funciona
- [ ] Performance fluida

---

## 📚 Recursos Adicionais

### Documentação Oficial:
- [Halium Docs](https://docs.halium.org)
- [Halium Porting Guide](https://docs.halium.org/en/latest/porting/index.html)
- [Droidian Docs](https://docs.droidian.org)

### Comunidades:
- Matrix: #halium:matrix.org
- Telegram: @halium
- GitHub: github.com/halium

### Device Trees Similares (Referência):
- Devices com Snapdragon 695 (SM6375)
- Motorola G series (2022+)
- Samsung A series com 695
- Outros Xiaomi com blair SoC

### Ferramentas Úteis:
- `dtc` - Device Tree Compiler
- `mkbootimg` - Criar boot images
- `simg2img` - Converter sparse images
- `android-bootimg-tools` - Manipular boot.img

---

**Criado em:** 2025-02-01  
**Device:** POCO X5 5G (rose/moonstone)  
**Kernel Base:** 5.4.302-Eclipse  
**Autor:** @Deivisan

**Próximo passo:** Implementar e testar
