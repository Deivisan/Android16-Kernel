# 🐳 Docker Build Guide - Android Kernel Moonstone

> Guia completo para compilar kernel Android POCO X5 5G (moonstone) usando Docker
> Versão: 1.0.0
> DevSan AGI

---

## 🎯 Objetivo

Compilar kernel Linux MSM 5.4 com patches Android para POCO X5 5G (Snapdragon 695 - codename moonstone) usando Docker com toolchain oficial do Android NDK r23b (Clang r416183b).

**Resultado esperado:** `arch/arm64/boot/Image.gz` (15-25MB)

---

## 💻 Pré-requisitos

### Hardware
- **CPU:** 8+ cores recomendado (Ryzen 7 5700G = 16 threads)
- **RAM:** 8GB+ mínimo (14GB+ recomendado)
- **Storage:** 50GB+ livres

### Software
- **Docker:** 20.10+ (no host)
- **docker-compose:** 1.27+ (no host)
- **Kernel source:** kernel-moonstone-devs
- **Usuário:** Permissões sudo (para setup inicial)

---

## 📚 Arquitetura do Build

```
┌─────────────────────────────────────────────────────────────────┐
│  Docker Host (Arch Linux - Ryzen 7 5700G)          │
│                                                         │
│  ┌───────────────────────────────────────────────────┐    │
│  │  Docker Container (Ubuntu 20.04)          │    │
│  │                                                   │    │
│  │  📦 Android NDK r23b                         │    │
│  │     └─> Clang r416183b (Android 12.0.8)    │    │
│  │                                                   │    │
│  │  📂 Volumes Montados:                         │    │
│  │    /kernel (ro)    ← Kernel source            │    │
│  │    /output (rw)    ← Build artifacts           │    │
│  │    /ccache (rw)    ← Build cache              │    │
│  │    /logs (rw)     ← Build logs               │    │
│  │                                                   │    │
│  │  ⚡ Build Process:                             │    │
│  │    1. validate-build.sh  (pré-checks)        │    │
│  │    2. apply-fixes.sh    (correções)          │    │
│  │    3. make defconfig     (configuração)      │    │
│  │    4. make -jN Image.gz  (compilação)       │    │
│  │    5. verify-results     (validação)          │    │
│  └───────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Guia Rápido

### 1. Setup Inicial (Uma vez)

```bash
# Ir para o laboratório
cd /home/deivi/Projetos/Android16-Kernel/laboratorio

# Executar setup automático
./scripts/setup-docker.sh
```

Este script:
- ✅ Verifica instalação do Docker
- ✅ Cria estrutura de diretórios
- ✅ Configura ccache (50GB)
- ✅ Valida pré-requisitos
- ✅ Prepara scripts auxiliares

### 2. Compilar Kernel

```bash
# Executar build completo
./build-moonstone-docker.sh
```

O script automaticamente:
1. 🔍 Valida ambiente (toolchain, espaço, configs)
2. 🔧 Aplica correções automáticas (tracing, format strings)
3. ⚡ Compila com NDK r23b Clang r416183b
4. ✅ Valida resultado (tamanho, SHA256)
5. 📝 Gera relatório completo

### 3. Customizar Build

```bash
# Compilar com 8 jobs (padrão: todos os CPUs)
JOBS=8 ./build-moonstone-docker.sh

# Compilar com limpeza anterior
CLEAN=yes ./build-moonstone-docker.sh

# Compilar tipo específico
BUILD_TYPE=qgki ./build-moonstone-docker.sh
```

---

## 📂 Estrutura de Diretórios

```
/home/deivi/Projetos/Android16-Kernel/
├── kernel-moonstone-devs/          # Kernel source (read-only)
│   ├── arch/arm64/configs/moonstone_defconfig
│   ├── techpack/
│   │   ├── audio/
│   │   ├── camera/
│   │   ├── datarmnet/           # ← rmnet_trace.h
│   │   ├── datarmnet-ext/
│   │   ├── dataipa/
│   │   ├── display/
│   │   └── video/
│   └── ...
│
└── laboratorio/                     # Workspace de build
    ├── Dockerfile                  # Imagem Docker
    ├── docker-compose.yml           # Configuração Docker Compose
    ├── build-moonstone-docker.sh  # Script principal
    ├── scripts/                   # Scripts auxiliares
    │   ├── setup-docker.sh         # Setup inicial
    │   ├── validate-build.sh       # Validação
    │   └── apply-fixes.sh         # Correções
    ├── out/                       # Output (rw)
    │   └── Image.gz              # ← KERNEL COMPILADO
    ├── logs/                      # Logs (rw)
    │   ├── build-*.log
    │   └── summary-*.txt
    └── cache/                     # Cache temporário
```

---

## 🔧 Variáveis de Ambiente

### Dentro do Docker

```bash
# Arquitetura (fixo)
ARCH=arm64
SUBARCH=arm64

# Toolchain (NDK r23b)
CC=clang
CLANG_TRIPLE=aarch64-linux-gnu-
CROSS_COMPILE=aarch64-linux-gnu-

# Flags de otimização
KCFLAGS="-O2 -pipe"
KAFLAGS="-O2 -pipe"

# ccache
CCACHE_DIR=/ccache
PATH=/usr/lib/ccache:$PATH
```

### No Host (variáveis do script)

```bash
JOBS=${JOBS:-$(nproc)}      # Jobs de paralelismo
BUILD_TYPE=${BUILD_TYPE:-qgki}  # Tipo de build
CLEAN=${CLEAN:-no}        # Limpar builds anteriores
```

---

## 🐛 Troubleshooting

### Erro: Docker not running

**Solução:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Erro: Permission denied (docker)

**Solução:**
```bash
sudo usermod -aG docker $USER
# Desconecte e reconecte
```

### Erro: Out of memory durante build

**Causa:** Container com muitos jobs e pouca RAM

**Solução:**
```bash
# Reduzir jobs
JOBS=4 ./build-moonstone-docker.sh

# Ou ajustar no docker-compose.yml
deploy:
  resources:
    limits:
      memory: 12G  # Aumentar RAM
```

### Erro: trace.h not found

**Solução:** Script apply-fixes.sh corrige automaticamente

### Erro: format string error in codecs

**Solução:** Script apply-fixes.sh corrige automaticamente

### Build muito lento

**Causas:**
1. Primeiro build (sem ccache)
2. Poucos jobs
3. Docker I/O lento

**Soluções:**
```bash
# Verificar ccache stats
docker-compose exec kernel-build ccache -s

# Aumentar jobs se tiver RAM suficiente
JOBS=16 ./build-moonstone-docker.sh

# Usar volume com cache (já configurado)
```

---

## 📊 Tempo de Build Estimado

| Hardware | Jobs | Tempo (1° build) | Tempo (rebuild com ccache) |
|----------|-------|------------------|------------------------------|
| Ryzen 7 5700G (16T) | 16 | 2-3 horas | 30-45 minutos |
| Ryzen 7 5700G (16T) | 8  | 3-4 horas | 45-60 minutos |
| Ryzen 7 5700G (16T) | 4  | 4-5 horas | 60-90 minutos |

**Nota:** Primeiro build sempre é mais lento (sem cache). Rebuilds subsequentes são muito mais rápidos graças ao ccache.

---

## 📦 Output Esperado

### Arquivos Gerados

```
out/
├── Image.gz              # Kernel comprimido (15-25MB)
├── vmlinux              # ELF não-comprimido (50-100MB)
├── System.map           # Símbolos do kernel (10-20MB)
└── dts/                 # Device Tree Blobs
    ├── qcom/
    │   └── *.dtb        # Device trees
    └── xiaomi/
        └── moonstone*.dtb
```

### Validação do Kernel

```bash
# Verificar tamanho (deve ser 15-25MB)
ls -lh out/Image.gz

# Extrair informações
file out/Image.gz
# Saída: data (compressed kernel)

# Calcular SHA256
sha256sum out/Image.gz

# Verificar versão
strings out/Image.gz | grep "Linux version" | head -1
# Saída esperada: Linux version 5.4.302...
```

---

## 🚀 Testando no Device

### Boot Temporário (Não flasha)

```bash
# Conectar device em fastboot
adb reboot bootloader

# Bootar kernel temporariamente (SEGURO)
fastboot boot /path/to/Image.gz

# Se funcionar, device vai bootar com novo kernel
# Se falhar, reboot normal volta ao kernel anterior
```

### Flash Permanente (Slot B - Seguro)

```bash
# SÓ fazer após testar via fastboot boot!
adb reboot bootloader

# Flashar em slot B (mantém A funcional)
fastboot flash boot_b /path/to/Image.gz

# Flashar DTBO se necessário
fastboot flash dtbo_b /path/to/dtbo.img

# Desabilitar verity (para system custom)
fastboot --disable-verity --disable-verification flash vbmeta_b /path/to/vbmeta.img

# Ativar slot B
fastboot set_active b

# Reboot
fastboot reboot
```

---

## 📝 Logs e Debugging

### Logs de Build

```bash
# Log completo de build
cat laboratorio/logs/build-YYYYMMDD-HHMMSS.log

# Resumo do build
cat laboratorio/logs/summary-YYYYMMDD-HHMMSS.txt

# Logs do ccache
docker-compose exec kernel-build ccache -s
```

### Logs do Kernel (no device)

```bash
# Verificar dmesg
adb shell dmesg > dmesg-boot-$(date +%Y%m%d).log

# Verificar versão do kernel
adb shell uname -a

# Verificar se carregou
adb shell cat /proc/version
```

---

## 🎯 Critérios de Sucesso

Build considerado **SUCESSO** quando:

- ✅ `out/Image.gz` existe (15-25MB)
- ✅ Todas configs críticas habilitadas (`USER_NS`, `CGROUP_DEVICE`, etc)
- ✅ SHA256 calculado
- ✅ Sem erros de compilação
- ✅ Kernel boota no device (via `fastboot boot`)
- ✅ `uname -a` mostra nova versão
- ✅ Sem kernel panics no dmesg

Build considerado **FALHA** quando:

- ❌ Erro de compilação
- ❌ Image.gz não encontrado
- ❌ Tamanho incorreto (< 10MB ou > 30MB)
- ❌ Bootloop ou panic
- ❌ Configs críticas ausentes

---

## 🔧 Scripts Auxiliares

### setup-docker.sh
- Verifica Docker instalado
- Cria estrutura de diretórios
- Configura ccache
- Valida pré-requisitos

### validate-build.sh
- Verifica kernel source
- Verifica toolchain (Clang)
- Valida configs críticas
- Verifica espaço em disco
- Verifica RAM disponível
- Verifica ccache

### apply-fixes.sh
- Corrige arquivos de tracing
- Corrige strings de formato em codecs
- Verifica techpacks problemáticos
- Ajusta configs críticas
- Ajusta permissões

### build-moonstone-docker.sh
- Script principal
- Orquestra todo o processo
- Gera logs detalhados
- Cria relatório final

---

## 📚 Referências

### Documentação Android
- [Building Kernels](https://source.android.com/setup/build/building-kernels)
- [Android Build System](https://source.android.com/setup/build)

### Qualcomm Snapdragon 695
- [SM6375 (Lahaina/Blair)](https://www.qualcomm.com/products/snapdragon-695-mobile-platform)
- [MSM 5.4 Kernel](https://source.codeaurora.org/quic/la/kernel/msm-5.4)

### Docker
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose](https://docs.docker.com/compose/)

---

## 🤝 Contribuindo

Se encontrar problemas ou melhorias:

1. Documentar o erro em `ERROS-ENCONTRADOS.md`
2. Criar correção em `apply-fixes.sh`
3. Testar e validar
4. Documentar em este guia

---

**🦞 DevSan AGI - v1.0.0 - 2026**  
**Target Device:** POCO X5 5G (moonstone/rose)  
**SoC:** Snapdragon 695 (SM6375)  
**Kernel:** MSM 5.4 + Android Patches  
**Toolchain:** Clang r416183b (Android NDK r23b)  
**Author:** Deivison Santana (@deivisan)
