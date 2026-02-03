# AGENTS.MD - Android16-Kernel Build System

> Documentação técnica para agents de IA - Compilação de kernel Android ARM64 em PC x86_64 Arch Linux  
> **⚠️ PROMPT ESPECIALIZADO:** Use `/kernel-builder-pro-5.4.302` para builds automatizados

---

## 🚀 PROMPT ESPECIALIZADO RECOMENDADO

**Para compilações automatizadas e persistentes, use o prompt especializado:**

📄 **`/prompts/kernel-builder-pro-5.4.302.md`**

Este prompt inclui:
- ✅ Leitura obrigatória de toda a documentação
- ✅ Estratégia completa de build (Fase 1 + Fase 2)
- ✅ Uso de MCPs (tavily, webfetch, codesearch) para debug
- ✅ Web search para erros desconhecidos
- ✅ Máximo poder do PC (Ryzen 7 5700G, 16 threads)
- ✅ Protocolo de persistência (nunca desistir)
- ✅ Troubleshooting avançado

**Como usar:**
```bash
# Copiar o prompt completo do arquivo:
cat /home/deivi/Projetos/android16-kernel/prompts/kernel-builder-pro-5.4.302.md
```

---

## 🎯 OBJETIVO TÉCNICO

Compilar kernel Linux 5.4.302 com patches Halium para POCO X5 5G (rose/moonstone, Snapdragon 695) usando cross-compilação ARM64 em PC Arch Linux x86_64.

**Resultado esperado:** `arch/arm64/boot/Image.gz` bootável no device via fastboot.

---

## 💻 AMBIENTE DE BUILD (Verificado)

### Hardware - PC Lenovo (DeiviPC)
| Componente | Especificação | Status |
|------------|---------------|--------|
| CPU | AMD Ryzen 7 5700G (8C/16T @ 4.6GHz) | ✅ |
| RAM | 14GB total (9.7GB disponível) | ✅ |
| Storage | SSD NVMe | ✅ |
| OS | Arch Linux (Kernel Zen 6.18.7) | ✅ |

### Toolchain Requerida (Instalar se faltar)
```bash
# Verificar instalação
which aarch64-linux-gnu-gcc
which clang
which make
which bc  # required for kernel version

# Instalar se necessário
sudo pacman -S aarch64-linux-gnu-gcc clang llvm make bc cpio kmod
```

### Estrutura de Diretórios (Atualizada - Fev/2026)
```
~/Projetos/android16-kernel/
├── 📦 kernel-moonstone-devs/       ← Kernel 5.4.302 AOSP (clonado)
│   ├── arch/arm64/configs/moonstone_defconfig
│   ├── build.config.common
│   └── ...
├── 🔧 build/                        ← Scripts de build (NOVO)
│   ├── apply-tracing-fixes.sh      ← Corrige TRACE_INCLUDE_PATH
│   ├── build-5.4.302.sh            ← Script principal
│   ├── PAUSA-ANTES-DO-BUILD.md     ← Documento de contexto
│   └── out/                        ← Output dos builds
├── ⚙️ configs/                      ← Configs adicionais
│   └── docker-lxc.config           ← Configs Docker/LXC (Fase 2)
├── 📚 docs/                         ← Documentação completa
│   ├── HISTORICO-BUILDS.md         ← Histórico de todas as tentativas
│   ├── HISTORICO-COMPLETO.md       ← Jornada 5.4.191
│   ├── INSTRUCOES-FLASH.md         ← Como instalar
│   ├── halium-porting.md           ← Guia Halium
│   └── ...
├── 🎁 anykernel3-poco-x5/           ← Template AnyKernel3
├── 💾 backups/                      ← Backups do device
│   └── poco-x5-5g-rose-2025-02-01/
├── 🗂️ deprecated/                  ← Arquivos antigos (5.4.191, Docker)
│   ├── kernel-source/              ← Kernel 5.4.191 (Xiaomi)
│   ├── laboratorio/                ← Docker experiments
│   └── ...
└── 🎯 prompts/
    └── kernel-builder-pro-5.4.302.md  ← PROMPT ESPECIALIZADO
```

---

## 📱 DEVICE TARGET (POCO X5 5G)

### Especificações Críticas
| Atributo | Valor | Impacto no Build |
|----------|-------|------------------|
| Codename | rose / moonstone | Usar em defconfig |
| SoC | Snapdragon 695 (SM6375) | Blair platform |
| Kernel Base | 5.4.302 | Versão a compilar |
| Arquitetura | ARM64 (armv8.2-a) | ARCH=arm64 |
| Endianness | Little | Padrão |
| Toolchain | Clang (Android) | CC=clang |
| Bootloader | A/B slots | Testar em slot B |

### Partições Importantes
```
Slot A (Android atual):
- boot_a: /dev/block/sde9 (128MB)
- dtbo_a: /dev/block/sde13 (24MB)  
- vbmeta_a: /dev/block/sde12 (64KB)

Slot B (Para testes):
- boot_b: /dev/block/sde28
- dtbo_b: /dev/block/sde32
- vbmeta_b: /dev/block/sde31
```

---

## 🔧 CHECKLIST DE BUILD

### Fase 1: Setup (Pré-requisitos)
- [ ] Verificar toolchain instalada
- [ ] Verificar espaço em disco (50GB+ livre)
- [ ] Verificar RAM disponível (8GB+ recomendado)
- [ ] Clonar kernel source
- [ ] Extrair config atual do backup

### Fase 2: Configuração
- [ ] Copiar defconfig
- [ ] Modificar configs (menuconfig ou editar)
- [ ] Verificar configs críticas para Halium
- [ ] Salvar .config

### Fase 3: Patches
- [ ] Clonar hybris-patches
- [ ] Aplicar patches no kernel
- [ ] Verificar aplicação bem-sucedida

### Fase 4: Compilação
- [ ] Configurar variáveis de ambiente
- [ ] Executar make (4-8 horas)
- [ ] Verificar Image.gz gerado
- [ ] Verificar tamanho (15-25MB)

### Fase 5: Teste
- [ ] Conectar device em fastboot
- [ ] Boot temporário: `fastboot boot Image.gz`
- [ ] Verificar dmesg
- [ ] Se funciona: flash em slot B

---

## 📝 COMANDOS EXATOS

### 1. Obter Kernel Source

**Opção A - Xiaomi Source (Preferido):**
```bash
cd ~/Projetos/Android16-Kernel/

# Verificar disponibilidade em:
# https://github.com/MiCode/Xiaomi_Kernel_OpenSource
# Procurar branch: moonstone-q-oss ou moonstone-r-oss

# Se disponível:
git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git -b moonstone-q-oss kernel-source

# Se não tiver, usar generic msm-5.4:
git clone https://github.com/android-linux-stable/msm-5.4.git kernel-source
```

**Opção B - Kernel Genérico (Fallback):**
```bash
git clone --depth=1 https://github.com/torvalds/linux.git -b v5.4 kernel-source
# NOTA: Requer mais patches para Android/Halium
```

### 2. Preparar Config

```bash
cd kernel-source

# Copiar config do backup
cp ../backups/poco-x5-5g-rose-2025-02-01/kernel-config-5.4.302-eclipse.txt .config

# OU carregar defconfig padrão se existir:
# make ARCH=arm64 moonstone_defconfig

# Verificar configs críticas:
grep -E "CONFIG_(USER_NS|CGROUP_DEVICE|SYSVIPC)" .config
# Deve mostrar =y para todos
```

### 3. Modificar Configs (Menuconfig)

```bash
make ARCH=arm64 menuconfig

# Navegar e habilitar:
General setup --->
  [*] Namespaces support --->
    [*] User namespace

General setup --->
  [*] System V IPC

General setup --->
  [*] POSIX Message Queues

General setup --->
  [*] Kernel .config support
  [*] Enable access to .config through /proc/config.gz

Control Group support --->
  [*] Memory controller
  [*] I/O controller
  [*] Device controller
  [*] PIDs controller

Security options --->
  [*] AppArmor support
  (apparmor) Default security module
```

**Alternativa: Editar .config diretamente:**
```bash
# Usar sed para modificar configs
sed -i 's/# CONFIG_USER_NS is not set/CONFIG_USER_NS=y/' .config
sed -i 's/# CONFIG_CGROUP_DEVICE is not set/CONFIG_CGROUP_DEVICE=y/' .config
sed -i 's/# CONFIG_SYSVIPC is not set/CONFIG_SYSVIPC=y/' .config
sed -i 's/# CONFIG_POSIX_MQUEUE is not set/CONFIG_POSIX_MQUEUE=y/' .config
sed -i 's/# CONFIG_SECURITY_APPARMOR is not set/CONFIG_SECURITY_APPARMOR=y/' .config
sed -i 's/CONFIG_DEFAULT_SECURITY="selinux"/CONFIG_DEFAULT_SECURITY="apparmor"/' .config
```

### 4. Obter e Aplicar Patches Halium

```bash
cd ~/Projetos/Android16-Kernel/

# Clonar patches
git clone https://github.com/Halium/hybris-patches.git

# Aplicar (dentro do kernel-source)
cd kernel-source
../hybris-patches/apply-patches.sh --mb

# Verificar se aplicou:
git log --oneline -10
# Deve mostrar commits dos patches

# Se falhar, aplicar manualmente:
# for patch in ../hybris-patches/patches/*.patch; do
#   patch -p1 < "$patch" || echo "Falhou: $patch"
# done
```

### 5. Compilar Kernel

```bash
cd ~/Projetos/Android16-Kernel/kernel-source

# Limpar builds anteriores (opcional)
# make clean && make mrproper

# Configurar ambiente
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Usar Clang (recomendado para Android 13+)
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

# Flags de otimização (opcional)
export KCFLAGS="-O2 -pipe"
export KAFLAGS="-O2 -pipe"

# Tempo estimado: 4-8 horas (Ryzen 7 5700G, 16 threads)
time make -j$(nproc) Image.gz

# Resultado esperado:
# arch/arm64/boot/Image.gz (15-25MB)
```

### 6. Verificar Build

```bash
# Verificar arquivo gerado
ls -lh arch/arm64/boot/Image.gz
file arch/arm64/boot/Image.gz

# Extrair info:
# file deve mostrar: "data" (compressed kernel)
# Tamanho: 15-25MB

# Verificar versão (se possível):
strings arch/arm64/boot/Image.gz | grep "Linux version" | head -1
```

### 7. Criar Boot Image (Opcional)

```bash
# Extrair ramdisk do boot.img original
cd ~/Projetos/Android16-Kernel/
mkdir -p temp && cd temp

tar -xJf ../backups/poco-x5-5g-rose-2025-02-01/device-images-backup-2025-02-01.tar.xz

# Extrair boot.img original
mkdir boot-extract
cd boot-extract

# Usar magiskboot ou unpackbootimg (instalar via AUR)
# yay -S android-tools

magiskboot unpack ../device-images/boot.img
# Gera: kernel, ramdisk.cpio, second, dtb, etc

# Substituir kernel
 cp ../kernel-source/arch/arm64/boot/Image.gz kernel

# Repack
magiskboot repack boot.img boot-halium.img
```

### 8. Testar no Device

```bash
# No PC, com device em fastboot:
adb reboot bootloader

# Boot temporário (NÃO FLASHA, só testa):
fastboot boot kernel-source/arch/arm64/boot/Image.gz

# OU se criou boot.img completo:
# fastboot boot temp/boot-extract/boot-halium.img

# Device vai bootar com novo kernel
# Se falhar, reboot normal volta ao antigo

# Capturar logs:
adb shell dmesg > ~/logs/dmesg-halium-$(date +%Y%m%d-%H%M%S).log
adb shell uname -a
```

### 9. Flash Permanente (Slot B)

```bash
# SÓ fazer se boot temporário funcionou!
adb reboot bootloader

# Flash em slot B (mantém A seguro)
fastboot flash boot_b kernel-source/arch/arm64/boot/Image.gz
fastboot flash dtbo_b backups/poco-x5-5g-rose-2025-02-01/device-images/dtbo.img

# Desabilitar verity (necessário para system.img custom)
fastboot --disable-verity --disable-verification flash vbmeta_b backups/poco-x5-5g-rose-2025-02-01/device-images/vbmeta.img

# Ativar slot B
fastboot set_active b

# Reboot
fastboot reboot
```

---

## ⚠️ CONFIGS CRÍTICAS (Verificação Obrigatória)

Antes de compilar, garantir que estas configs estão habilitadas:

```bash
cd kernel-source

# Verificar todas configs críticas:
for CONFIG in USER_NS CGROUP_DEVICE CGROUP_PIDS SYSVIPC POSIX_MQUEUE IKCONFIG_PROC SECURITY_APPARMOR; do
    echo -n "CONFIG_$CONFIG: "
    grep "CONFIG_$CONFIG[= ]" .config || echo "AUSENTE"
done
```

**Saída esperada:**
```
CONFIG_USER_NS: CONFIG_USER_NS=y
CONFIG_CGROUP_DEVICE: CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_PIDS: CONFIG_CGROUP_PIDS=y
CONFIG_SYSVIPC: CONFIG_SYSVIPC=y
CONFIG_POSIX_MQUEUE: CONFIG_POSIX_MQUEUE=y
CONFIG_IKCONFIG_PROC: CONFIG_IKCONFIG_PROC=y
CONFIG_SECURITY_APPARMOR: CONFIG_SECURITY_APPARMOR=y
```

Se alguma mostrar "AUSENTE" ou "is not set", o kernel não vai suportar LXC/Halium corretamente.

---

## 🔍 TROUBLESHOOTING

### Erro: "aarch64-linux-gnu-gcc: command not found"
**Solução:** `sudo pacman -S aarch64-linux-gnu-gcc`

### Erro: "bc: command not found"  
**Solução:** `sudo pacman -S bc`

### Erro: "No rule to make target 'Image.gz'"
**Causa:** Não carregou ARCH=arm64
**Solução:** `export ARCH=arm64` antes do make

### Erro: "Compiler lacks asm-goto support"
**Causa:** GCC muito antigo ou Clang não configurado
**Solução:** Usar Clang: `export CC=clang`

### Erro: Out of memory durante compilação
**Causa:** RAM insuficiente (14GB pode ser pouco para -j16)
**Solução:** Reduzir paralelismo: `make -j8` em vez de `-j16`

### Kernel boota mas panic no init
**Causa:** Config faltando ou initramfs incorreto
**Solução:** Verificar configs de initrd, verificar dmesg

### Device não entra em fastboot
**Causa:** Driver USB ou cabo
**Solução:** `sudo pacman -S android-udev`, reconectar cabo

---

## 📊 ESTIMATIVAS DE TEMPO

| Fase | Tempo Estimado | PC Ryzen 7 5700G |
|------|----------------|------------------|
| Setup/Clone | 30-60 min | Depende da internet |
| Configuração | 15-30 min | Menuconfig interativo |
| Patches | 10-20 min | Auto ou manual |
| **Compilação** | **4-8 horas** | **-j16, kernel completo** |
| Verificação | 5-10 min | Testes locais |
| Teste no device | 15-30 min | Boot + verificação |
| **Total** | **5-10 horas** | **Primeira vez** |

Rebuilds subsequentes (após `make clean`):
- Compilação: 2-4 horas (menos tempo)

---

## 🚀 AUTOMATION SCRIPTS (Criar)

### build-kernel.sh
```bash
#!/bin/bash
set -e

KERNEL_DIR="${1:-kernel-source}"
JOBS="${2:-$(nproc)}"

cd "$KERNEL_DIR"

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

echo "🔧 Configurando kernel..."
make moonstone_defconfig 2>/dev/null || make defconfig

echo "⚡ Compilando com $JOBS jobs..."
time make -j"$JOBS" Image.gz

echo "✅ Build completo!"
echo "📦 Output: arch/arm64/boot/Image.gz"
ls -lh arch/arm64/boot/Image.gz
```

### check-configs.sh
```bash
#!/bin/bash

CONFIGS="USER_NS CGROUP_DEVICE CGROUP_PIDS SYSVIPC POSIX_MQUEUE IKCONFIG_PROC SECURITY_APPARMOR"

for CONFIG in $CONFIGS; do
    VALUE=$(grep "CONFIG_$CONFIG[= ]" .config 2>/dev/null || echo "NOT_FOUND")
    if echo "$VALUE" | grep -q "=y"; then
        echo "✅ CONFIG_$CONFIG: OK"
    else
        echo "❌ CONFIG_$CONFIG: FALTANDO ($VALUE)"
    fi
done
```

---

## 🎯 CRITÉRIOS DE SUCESSO

Build considerado **SUCESSO** quando:
1. ✅ `arch/arm64/boot/Image.gz` existe (15-25MB)
2. ✅ Todas configs críticas estão habilitadas (=y)
3. ✅ Patches Halium aplicados sem erros
4. ✅ Kernel boota no device (via `fastboot boot`)
5. ✅ `uname -a` mostra nova versão
6. ✅ Sem kernel panics no dmesg

Build considerado **FALHA** quando:
- ❌ Erro de compilação
- ❌ Kernel não boota
- ❌ Bootloop ou panic
- ❌ Configs críticas ausentes

---

## 📝 NOTAS PARA AGENTS

**REGRAS:**
1. **NUNCA** assumir que configs estão corretas - sempre verificar
2. **SEMPRE** testar via `fastboot boot` antes de flashar
3. **SEMPRE** manter slot A funcional
4. **NUNCA** flashar em ambos slots simultaneamente
5. **SEMPRE** documentar erros encontrados

**DECISÕES AUTÔNOMAS PERMITIDAS:**
- Instalar pacotes faltantes (com pacman)
- Modificar configs via sed/menuconfig
- Escolher entre Clang/GCC
- Ajustar -j conforme RAM disponível

**DECISÕES QUE REQUEREM CONFIRMAÇÃO:**
- Flash permanente no device
- Alterar partições críticas
- Modificar device tree

**WORKFLOW OBRIGATÓRIO:**
1. Ler docs/kernel-analysis.md
2. Verificar toolchains instaladas
3. Executar check-configs.sh
4. Compilar
5. Testar via fastboot boot
6. Documentar resultados

---

**Criado em:** 2025-02-01  
**Target Device:** POCO X5 5G (rose/moonstone)  
**Build Host:** Arch Linux x86_64 (Ryzen 7 5700G, 14GB RAM)  
**Target Arch:** ARM64  
**Kernel Version:** 5.4.302 + Halium patches  
**Author:** @Deivisan
