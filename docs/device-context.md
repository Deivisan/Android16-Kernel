# Device Context - POCO X5 5G (Rose/Moonstone)

**Documentação completa de hardware, partições e arquitetura para porte Halium/Linux**

---

## 📱 Informações Gerais

| Especificação | Valor |
|--------------|-------|
| **Modelo Comercial** | POCO X5 5G |
| **Codename Android** | rose |
| **Codename Xiaomi** | moonstone |
| **Fabricante** | Xiaomi (POCO é sub-marca) |
| **Ano de Lançamento** | 2023 |
| **Região** | Global (codename rose) / China (moonstone) |

---

## 🔧 Hardware Técnico

### System on Chip (SoC)
| Componente | Especificação |
|------------|---------------|
| **SoC** | Qualcomm Snapdragon 695 |
| **Plataforma** | SM6375 |
| **Processo** | 6nm TSMC |
| **Arquitetura** | ARM64 v8.2-A |
| **Big Cores** | 2x Cortex-A78 @ 2.2 GHz |
| **Little Cores** | 6x Cortex-A55 @ 1.8 GHz |
| **Total Cores** | 8 (2+6 configuração) |
| **GPU** | Qualcomm Adreno 619 |
| **DSP** | Hexagon (Qualcomm) |
| **NPU** | Não dedicada (usa GPU para AI) |
| **ISP** | Qualcomm Spectra (tripple 12-bit) |

### Memória e Armazenamento
| Componente | Especificação |
|------------|---------------|
| **RAM** | 6GB / 8GB LPDDR4X |
| **RAM Atual** | 7.3GB detectado (8GB versão) |
| **Swap** | 9GB configurado |
| **Armazenamento** | 128GB / 256GB UFS 2.2 |
| **MicroSD** | Sim, até 1TB (slot híbrido) |

### Display
| Componente | Especificação |
|------------|---------------|
| **Tipo** | AMOLED |
| **Tamanho** | 6.67 polegadas |
| **Resolução** | 1080 x 2400 (FHD+) |
| **Proporção** | 20:9 |
| **Densidade** | ~395 PPI |
| **Refresh Rate** | 120Hz |
| **Touch Sampling** | 240Hz |
| **Brilho Máx** | 1200 nits (peak) |
| **HDR** | HDR10+, Dolby Vision |
| **Proteção** | Corning Gorilla Glass 3 |

### Conectividade
| Componente | Especificação |
|------------|---------------|
| **Rede** | 5G NSA/SA, 4G LTE, 3G, 2G |
| **WiFi** | Wi-Fi 5 (802.11 a/b/g/n/ac) |
| **Bluetooth** | 5.1 (A2DP, LE) |
| **NFC** | Sim |
| **GPS** | Sim (GPS, GLONASS, BDS, GALILEO, QZSS) |
| **USB** | USB Type-C 2.0 |
| **OTG** | Sim |
| **Audio Jack** | Sim, 3.5mm |
| **Infrared** | Sim (blaster) |
| **FM Radio** | Não (desabilitado em software) |

### Câmeras
| Câmera | Especificação |
|--------|---------------|
| **Principal** | 48MP, f/1.8, PDAF |
| **Ultra-wide** | 8MP, f/2.2, 118° |
| **Macro** | 2MP, f/2.4 |
| **Frontal** | 13MP, f/2.5 |
| **Vídeo** | 1080p@30fps (principal e frontal) |

### Sensores
| Sensor | Disponibilidade |
|--------|-----------------|
| Acelerômetro | ✅ Sim |
| Giroscópio | ✅ Sim |
| Proximidade | ✅ Sim |
| Luz Ambiente | ✅ Sim |
| Bússola (Magnetômetro) | ✅ Sim |
| Barômetro | ❌ Não |
| Leitor de Impressão Digital | ✅ Lateral (montado no power) |
| Face Unlock | ✅ Software-based |

### Bateria
| Especificação | Valor |
|--------------|-------|
| **Capacidade** | 5000 mAh |
| **Tipo** | Li-Po (Polímero) |
| **Carregamento** | 33W wired |
| **Tecnologia** | Quick Charge 3+ / PD3.0 |
| **Removível** | Não |

---

## 💾 Layout de Partições

### Partições A/B (Sistema)
O dispositivo usa **partições A/B** (seamless updates):

```
Slot A (ativo atualmente):
├── boot_a        → /dev/block/sde9     (Kernel + Ramdisk)
├── dtbo_a        → /dev/block/sde13    (Device Tree Binary Overlay)
├── vbmeta_a      → /dev/block/sde12    (Verified Boot Metadata)
├── system_a      → Parte de super      (Android System)
├── vendor_a      → Parte de super      (Vendor Blobs)
├── product_a     → Parte de super      (Product apps)
└── vbmeta_system_a → /dev/block/sda9   (System VBMeta)

Slot B (vazio/disponível para testes):
├── boot_b        → /dev/block/sde28
├── dtbo_b        → /dev/block/sde32
├── vbmeta_b      → /dev/block/sde31
├── system_b      → Parte de super
├── vendor_b      → Parte de super
├── product_b     → Parte de super
└── vbmeta_system_b → /dev/block/sda10
```

### Partições Estáticas (Não A/B)
```
Partições Críticas (NUNCA MEXER):
├── persist       → Calibrações sensores, IMEI, MAC
├── modem         → Firmware baseband (4G/5G)
├── fsg/fsc       → Configurações modem
├── ddr           → Configurações memória
├── tz            → TrustZone (segurança ARM)
├── devinfo       → Info bootloader
└── abl           → Application Bootloader

Partições de Recuperação:
├── recovery      → Recovery mode (não existe em A/B puro)
├── misc          → Comandos bootloader
└── metadata      → Criptografia metadata

Partições de Dados:
├── userdata      → /data (apps, arquivos usuário)
├── cache         → Cache (obsoleto em A/B)
└── super         → Partição dinâmica (system+vendor+product)
```

### Partições Dinâmicas (Logical)
O Android usa **Dynamic Partitions** via dm-linear:
```
super (partição física enorme):
├── system_a      → Android OS (slot A)
├── system_b      → Android OS (slot B) - vazio para Linux
├── vendor_a      → Drivers Qualcomm (slot A)
├── vendor_b      → Drivers Qualcomm (slot B)
├── product_a     → Apps pré-instalados (slot A)
└── product_b     → Apps pré-instalados (slot B)
```

---

## 🔐 Esquema de Boot e Segurança

### Android Verified Boot (AVB)
- **Versão:** AVB 2.0 (Android Verified Boot)
- **Vbmeta:** Assinado, verificação ativa
- **Rollback Protection:** Ativo
- **Bootloader:** Desbloqueado (confirmado via KernelSU)

### Kernel Boot
- **Formato:** Android Bootimg v2
- **Base Address:** 0x00000000
- **Kernel Offset:** 0x00008000
- **Ramdisk Offset:** 0x01000000
- **Tags Offset:** 0x00000100
- **Pagesize:** 4096 (4KB)

### DTBO (Device Tree Binary Overlay)
- **Formato:**qcom DTBO v2
- **Plataforma:** Moonstone QRD (Qualcomm Reference Design)
- **SoC:** SM6375 (blair)
- **Device:** qcom,blair-qrd

---

## 🐧 Informações de Software Atual

### Android
- **Versão:** 13 (Tiramisu)
- **API Level:** 33
- **MIUI:** 14 (Xiaomi)
- **Security Patch:** Atualizado
- **Kernel:** 5.4.302-Eclipse (Custom)
- **Build:** QG1A.220913.001

### Kernel
- **Versão:** Linux 5.4.302
- **Localversion:** -qgki
- **Compiler:** ClangBuiltLinux clang version 20.1.7
- **Config:** /proc/config.gz disponível
- **Architecture:** ARM64
- **Byte Order:** Little Endian

### Root e Modificações
- **Root:** KernelSU (Kernel-based SU)
- **Chroot:** Arch Linux ARM64 em /mnt/sdcard/Projetos
- **Runtime:** 100% Bun (Node.js purged)
- **Gestor Pacotes:** Pacman (Arch)

---

## 📊 Recursos de Hardware para Porting

### O que facilita porte Halium/Linux:
1. ✅ **Kernel 5.4 moderno** - Acima do mínimo 3.10/3.4
2. ✅ **Kernel source disponível** - Xiaomi libera sources
3. ✅ **ARM64 puro** - Sem complicações ARMv7
4. ✅ **Partições A/B** - Dual boot seguro possível
5. ✅ **Bootloader desbloqueado** - Flash permitido
6. ✅ **Dynamic partitions** - Flexibilidade de tamanho
7. ✅ **6-8GB RAM** - Suficiente para Linux completo
8. ✅ **Qualcomm SoC** - Halium tem bom suporte QC

### O que dificulta porte:
1. ❌ **GPU Adreno 619** - Drivers blobs fechados (não Mesa3D)
2. ❌ **Modem 5G** - Firmware proprietário complexo
3. ❌ **Câmera Qualcomm** - HAL proprietário, difícil libcamera
4. ❌ **Sensores** - Alguns via Qualcomm SSP (blobs)
5. ❌ **DRM/Widevine** - Proteção de conteúdo limita drivers abertos

---

## 🎯 Checklist de Compatibilidade

### Hardware suportado por Halium (esperado):
- [x] CPU ARM64 (Cortex-A78/A55)
- [x] RAM (6-8GB)
- [x] USB (Host + Gadget)
- [x] MMC/SDCard
- [x] Bluetooth (via Android container)
- [x] WiFi (via Android container)
- [ ] GPU aceleração (só software ou lima/panfrost se abrir)
- [ ] Câmera (via Android container/libhybris)
- [ ] Modem/Rede (via Android container/rild)
- [ ] GPS (via Android container/location)
- [ ] Sensores (via Android container/sensors HAL)

---

## 📁 Localização de Blobs Proprietários

```
/vendor (em super partition):
├── lib64/hw/          → HALs de hardware (.so)
├── lib64/egl/         → Drivers GPU (eglSubDriverAndroid)
├── lib/               → Libs 32-bit (compatibilidade)
├── bin/               → Binários HAL (android.hardware.*)
├── firmware/          → Firmwares (wifi, modem, etc)
└── etc/vintf/         → Manifests HAL (XML)

/firmware (partição separada):
├── image/             → Firmware modem (mpss)
├── wcnss/             → Firmware WiFi/BT (wlanmdsp)
└── venus/             → Firmware Vídeo/Codec

/persist:
├── calibration/       → Calibrações sensores
├── bluetooth/         → MAC BT (único por device)
└── wifi/              → MAC WiFi (único por device)
```

---

## 🔗 Referências e Recursos

### Documentação Xiaomi/Qualcomm
- **Xiaomi Kernel Source:** https://github.com/MiCode/Xiaomi_Kernel_OpenSource
- **Qualcomm Open Source:** https://www.codeaurora.org/
- **SM6375 Platform:** Blair (Snapdragon 695)

### Comunidades de Porting
- **Halium Project:** https://halium.org
- **Halium Docs:** https://docs.halium.org
- **Droidian:** https://droidian.org
- **Ubuntu Touch:** https://ubuntu-touch.io
- **PostmarketOS:** https://postmarketos.org

### Device Trees Similares (Referência)
- **SM6375/Blair:** Procurar dispositivos com mesmo SoC
- **Qualcomm 695:** Motorola, Samsung, outros Xiaomi
- **Moonstone:** Possível referência com Redmi Note 12 series

---

**Documentação criada em:** 2025-02-01  
**Autor:** @Deivisan  
**Próximo passo:** Ver [Kernel Analysis](kernel-analysis.md)
