# 🚀 Android 16 Kernel - POCO X5 5G (moonstone)

> KernelSU-Next v3.0.1 + SUSFS + Docker + Touchscreen Fix

## 📱 Sobre

Repositório para desenvolvimento de kernel Android 16 (kernel 5.4.302) para POCO X5 5G (moonstone) com suporte completo para modding.

### ✅ Features Integradas:
- **KernelSU-Next v3.0.1**: Root system com AllowList
- **SUSFS**: Hide modules from detection
- **Docker/LXC**: Container support para Ubuntu Touch 
- **Touchscreen Fix**: FT3519T driver corrigido
- **Performance**: Otimizado para Ryzen 7 5700G (16 threads)

---

## 🏷️ Hardware Target

| Componente | Especificação |
|------------|-------------|
| Device | POCO X5 5G |
| Codename | rose / moonstone |
| SoC | Snapdragon 695 (SM6375) |
| Touch | FocalTech FT3519T |
| Display | FHD+ 10800×24000 |
| Architecture | ARM64 |

---

## 📦 Releases

### v3.0.1-TOUCHFIX-FINAL (2026-02-04)
**Arquivo**: `KernelSU-Next-v3.0.1-SUSFS-Docker-POCO-X5-5G-20260204-FINAL.zip`  
**Status**: 🧪 EM TESTE  
**Tamanho**: 22MB

#### 🎯 Correções Implementadas:
- ✅ **FT3519T Firmware Fix**: Array preenchido com header válido (0x89, 0x00, 0x35, 0x19)
- ✅ **Configurações Habilitadas**: CONFIG_TOUCHSCREEN_FT3519T=y por padrão
- ✅ **DTBO Completo**: moonstone-overlay com project-name e ic-type
- ✅ **Debug Ativado**: FTS_DEBUG_EN=1 para troubleshooting
- ✅ **KernelSU + SUSFS**: Root + hide modules
- ✅ **Docker Support**: Container runtime

#### 📥 Histórico:
- **v3.0.1** (2026-02-04): Build inicial - Touch não funciona
- **v3.0.1-DTBO-FIX** (2026-02-04): DTBO atualizado - Touch ainda não funciona  
- **v3.0.1-FINAL** (2026-02-04): Correção completa - Em teste

---

## 🔧 Build System

### Ambiente:
- **OS**: Arch Linux (Kernel Zen 6.18.7)
- **CPU**: AMD Ryzen 7 5700G (8C/16T @ 4.6GHz)
- **Toolchain**: Clang + aarch64-linux-gnu-gcc
- **Build Time**: ~2-4 horas (16 threads)

### Comando:
```bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
make -j$(nproc) Image.gz
```

---

## 📋 Documentação

### Installation:
```bash
adb reboot recovery
adb sideload KernelSU-Next-v3.0.1-SUSFS-Docker-POCO-X5-5G-20260204-FINAL.zip
```

### Troubleshooting:
```bash
# Logs do touchscreen
adb shell dmesg | grep -i focaltech

# Verificar device tree
adb shell cat /proc/device-tree/focaltech@38/status

# Teste touch
adb shell getevent | grep focaltech
```

---

## 🗂️ Workspace

### 📁 Estrutura:
```
kernel-moonstone-devs/          # Source kernel 5.4.302
├── drivers/input/touchscreen/FT3519T/    # Driver corrigido
├── arch/arm64/boot/dts/vendor/xiaomi/  # Device tree
├── .config                        # Config otimizada
└── arch/arm64/boot/Image.gz          # Kernel compilado

workspace/                          # Logs e documentação
└── 2026-02-04.md                 # Session atual

anykernel3-poco-x5/            # Pacote flash
└── moonstone-overlay.dtbo         # DTBO específico
```

### 📊 Status Atual:
- **Build**: FINAL completo e commitado
- **Flash**: Boot original restaurado (comparação)
- **Teste**: Aguardando feedback do usuário
- **Próximo**: Firmware real extraction (se necessário)

---

## 🔗 Links Úteis

- **Source**: [Xiaomi Kernel Source](https://github.com/MiCode/Xiaomi_Kernel_OpenSource)
- **Device Tree**: `arch/arm64/boot/dts/vendor/xiaomi/moonstone.dts`
- **Touch Driver**: `drivers/input/touchscreen/FT3519T/`
- **Build Logs**: `workspace/` directory

---

## ⚡ Quick Start

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/android16-kernel.git

# Entrar no diretório
cd android16-kernel

# Verificar workspace
cat workspace/$(date +%Y-%m-%d).md

# Build (se necessário)
cd kernel-moonstone-devs
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
make -j$(nproc) Image.gz

# Empacotar
cp arch/arm64/boot/Image.gz anykernel3-poco-x5/
cd anykernel3-poco-x5
zip -r ../kernel-novo.zip .
```

---

**Maintainer**: @deivisan  
**License**: GPL-2.0  
**Last Updated**: 2026-02-04