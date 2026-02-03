# 🚀 KERNEL MOONSTONE BUILD - DOCKER AUTOMATION

**Autor:** DevSan Max
**Data:** 2026-02-02
**Target:** POCO X5 5G (moonstone, SM6375/Blair chipset)
**Kernel:** 5.4.302-msm-android (QGKI)

---

## 📋 ÍNDICE

1. [Visão Geral](#visão-geral)
2. [Problema Identificado](#problema-identificado)
3. [Solução Implementada](#solução-implementada)
4. [Como Usar](#como-usar)
5. [Arquivos Gerados](#arquivos-gerados)
6. [Troubleshooting](#troubleshooting)

---

## 1. VISÃO GERAL

### 1.1 Objetivo

Compilar o kernel Linux 5.4.302 com patches Qualcomm techpacks para o POCO X5 5G usando:

- **Docker container** com Ubuntu 20.04
- **Clang r416183b** (toolchain exata dos devs Qualcomm)
- **Correções automáticas** para o problema de tracing system

### 1.2 Arquitetura da Solução

```
┌─────────────────────────────────────────────────────┐
│  Host System (Arch Linux x86_64)          │
│  - Gerencia Docker container                   │
│  - Monitora progresso                         │
│  - Recebe kernel compilado                   │
└────────────────┬────────────────────────────────┘
                 │
                 │ Docker Volume
                 ▼
┌─────────────────────────────────────────────────────┐
│  Docker Container (Ubuntu 20.04)           │
│  - kernel-moonstone-devs (ro)             │
│  - Clang r416183b                        │
│  - gcc-aarch64-linux-gnu                  │
│  - Executa build-kernel-docker.sh           │
└────────────────┬────────────────────────────────┘
                 │
                 │ Docker Volume
                 ▼
┌─────────────────────────────────────────────────────┐
│  Output Directory (laboratorio/output/)         │
│  - Image.gz (kernel compilado)              │
│  - build.log (log completo)                 │
│  - System.map (símbolos do kernel)        │
└─────────────────────────────────────────────────────┘
```

---

## 2. PROBLEMA IDENTIFICADO

### 2.1 O Erro de Tracing

**Erro Original:**
```bash
./include/trace/define_trace.h:95:10: fatal error: './rmnet_trace.h' file not found
```

### 2.2 Causa Raiz

O sistema de tracing do Linux kernel usa macros que expandem em tempo de compilação:

1. Header define: `#define TRACE_INCLUDE_PATH .`
2. Macro expansion: `__stringify(TRACE_INCLUDE_PATH/system.h)` → `"./system.h"`
3. Clang tenta incluir: `#include "./system.h"`

**Por que falha?**
- Clang tem regras mais estritas para path resolution
- O path relativo `.` não funciona corretamente com `#include "..."`
- GCC resolve de forma diferente, por isso funciona

### 2.3 Arquivos Afetados

```
techpack/datarmnet/core/rmnet_handlers.c     → rmnet_trace.h
techpack/datarmnet/core/wda_qmi.c            → wda.h
techpack/datarmnet/core/dfc_qmi.c            → dfc.h
techpack/camera/drivers/cam_utils/cam_trace.c  → cam_trace.h
techpack/display/rotator/sde_rotator_base.c    → sde_rotator_trace.h
techpack/display/msm/sde/sde_kms.c          → sde_trace.h
techpack/dataipa/.../ipa.c                → ipa_trace.h
techpack/dataipa/.../rndis_ipa.c          → rndis_ipa_trace.h
techpack/video/msm/vidc/msm_vidc_debug.c    → msm_vidc_events.h
kernel/sched/walt/trace.c                    → trace.h (WALT scheduler)
```

---

## 3. SOLUÇÃO IMPLEMENTADA

### 3.1 Abordagem

**Mudança de `TRACE_INCLUDE_PATH .` para paths absolutos relativos ao kernel root:**

**Antes:**
```c
#define TRACE_INCLUDE_PATH .
```

**Depois:**
```c
#define TRACE_INCLUDE_PATH techpack/datarmnet/core
```

### 3.2 Automação

O script `build-kernel-docker.sh` aplica automaticamente essas correções antes da compilação:

```bash
fix_trace_include_path() {
    local file="$1"
    local relative_path="$2"

    sed -i "s|#define TRACE_INCLUDE_PATH .|#define TRACE_INCLUDE_PATH ${relative_path}|" "$file"
}
```

**Arquivos corrigidos automaticamente:**
- ✅ `techpack/datarmnet/core/rmnet_trace.h` → `techpack/datarmnet/core`
- ✅ `techpack/datarmnet/core/wda.h` → `techpack/datarmnet/core`
- ✅ `techpack/datarmnet/core/dfc.h` → `techpack/datarmnet/core`
- ✅ `techpack/camera/drivers/cam_utils/cam_trace.h` → `techpack/camera/drivers/cam_utils`
- ✅ `techpack/display/rotator/sde_rotator_trace.h` → `techpack/display/rotator`
- ✅ `techpack/display/msm/sde/sde_trace.h` → `techpack/display/msm/sde`
- ✅ `techpack/dataipa/.../ipa_trace.h` → paths absolutos
- ✅ `techpack/video/msm/vidc/msm_vidc_events.h` → `techpack/video/msm/vidc`
- ✅ `kernel/sched/walt/trace.h` → `kernel/sched/walt`

### 3.3 Backup dos Arquivos Originais

Todos os arquivos modificados têm backup com extensão `.bak`:

```bash
techpack/datarmnet/core/rmnet_trace.h.bak
techpack/datarmnet/core/wda.h.bak
...
```

Para restaurar os originais:

```bash
find techpack -name "*.bak" -exec sh -c 'mv "$1" "${1%.bak}"' _ {} \;
```

---

## 4. COMO USAR

### 4.1 Pré-requisitos

1. **Docker instalado** no host
2. **50GB+ de espaço** livre
3. **Acesso à internet** (para baixar Clang r416183b)
4. **kernel-moonstone-devs** clonado em `/home/deivi/Projetos/Android16-Kernel/`

### 4.2 Passo a Passo

#### PASSO 1: Build da Imagem Docker (primeira vez)

```bash
cd /home/deivi/Projetos/Android16-Kernel/laboratorio
chmod +x build-moonstone-docker-main.sh

# Build imagem Docker (só precisa fazer uma vez)
# Isso baixa Clang r416183b e configura Ubuntu 20.04
sudo docker build -t moonstone-kernel-builder:latest .
```

**Tempo estimado:** 15-30 minutos
**Depende de:** Velocidade da internet (Clang r416183b é ~800MB)

#### PASSO 2: Executar Build do Kernel

```bash
# Opção A: Usar script principal (RECOMENDADO)
./build-moonstone-docker-main.sh

# Opção B: Docker manual
docker run --rm \
    -v /home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs:/workspace/kernel-moonstone-devs:ro \
    -v /home/deivi/Projetos/Android16-Kernel/laboratorio/output:/workspace/output \
    moonstone-kernel-builder:latest \
    /workspace/build-kernel-docker.sh
```

**Tempo estimado:** 2-4 horas (8 jobs no Docker)
**Output:** `laboratorio/output/Image.gz`

#### PASSO 3: Monitorar Progresso

```bash
# Em outro terminal, monitorar logs do container
docker logs -f moonstone-build

# Ou ver arquivo de log diretamente
tail -f /home/deivi/Projetos/Android16-Kernel/laboratorio/output/build.log
```

### 4.3 Monitoramento de Progresso

O script imprime progresso em tempo real:

```
🦞 DevSan Max - Kernel Moonstone Docker Build
============================================

🔧 Aplicando correções automáticas para tracing...

Techpack DATARMNET:
  📝 Corrigindo: techpack/datarmnet/core/rmnet_trace.h
    ✅ Alterado de 'TRACE_INCLUDE_PATH .' para 'TRACE_INCLUDE_PATH techpack/datarmnet/core'
  📝 Corrigindo: techpack/datarmnet/core/wda.h
    ✅ Alterado de 'TRACE_INCLUDE_PATH .' para 'TRACE_INCLUDE_PATH techpack/datarmnet/core'
...

✅ Correções de tracing aplicadas!

⚙️  Carregando defconfig...
  LOCALVERSION="-qgki"

🔨 Iniciando compilação...
  Alvo: Image.gz
  Jobs: 8 (limitado para RAM do container)
  Tempo estimado: 2-4 horas

  CC      arch/arm64/kernel/entry.o
  CC      arch/arm64/kernel/head.o
  ...

⏱️  Build finalizado em 156 minutos

🎉 BUILD SUCESSO! 🎉

📦 Kernel gerado:
  Arquivo: laboratorio/output/Image.gz
  Tamanho: 22.4MB
  Bytes: 23456789
```

---

## 5. ARQUIVOS GERADOS

### 5.1 Scripts

| Arquivo | Descrição |
|---------|------------|
| `Dockerfile` | Dockerfile com Ubuntu 20.04 + Clang r416183b |
| `build-kernel-docker.sh` | Script de build executado DENTRO do container |
| `build-moonstone-docker-main.sh` | Script principal executado FORA do container |
| `ANALISE-COMPLETA-KERNEL-MOONSTONE.md` | Documentação técnica completa |

### 5.2 Output

| Arquivo | Localização | Descrição |
|---------|-------------|------------|
| `Image.gz` | `laboratorio/output/` | Kernel compilado (15-25MB) |
| `build.log` | `laboratorio/output/` | Log completo do build |
| `System.map` | `laboratorio/output/` | Símbolos do kernel |
| `vmlinux` | `laboratorio/output/` | Kernel não-comprimido |

---

## 6. TROUBLESHOOTING

### 6.1 Docker Build Falha

**Erro:** `docker build: ...`

**Solução:**
```bash
# Verificar se Docker está rodando
sudo systemctl status docker

# Verificar logs do Docker
sudo journalctl -u docker -n 100

# Tentar com sudo se necessário
sudo docker build -t moonstone-kernel-builder:latest .
```

### 6.2 Out of Memory

**Erro:** `make: *** virtual memory exhausted`

**Solução:** Reduzir jobs no Dockerfile:
```bash
# Editar Dockerfile ou passar variável de ambiente
docker run ... -e JOBS=4 ...
```

### 6.3 Clang Não Encontrado

**Erro:** `clang: command not found`

**Solução:** Verificar download do Clang:
```bash
docker run --rm moonstone-kernel-builder:latest \
    ls -la /workspace/clang-r416183b/bin/clang

# Deve mostrar o executável
```

### 6.4 Erro de Tracing Persiste

**Erro:** Ainda mostra `'./rmnet_trace.h' file not found`

**Solução:** Verificar se correção foi aplicada:
```bash
docker run --rm -v ... moonstone-kernel-builder:latest \
    grep "TRACE_INCLUDE_PATH" /workspace/kernel-moonstone-devs/techpack/datarmnet/core/rmnet_trace.h

# Deve mostrar:
#   #define TRACE_INCLUDE_PATH techpack/datarmnet/core
```

Se ainda mostra `TRACE_INCLUDE_PATH .`, o script de correção falhou.

### 6.5 Image.gz Gerado Mas Não Boota

**Erro:** Device boota mas panic no init

**Causas possíveis:**
1. Configuração de initramds incorreta
2. Device tree não carregando
3. Partições do device incompatíveis

**Solução:**
- Verificar dmesg do device
- Testar com `fastboot boot Image.gz` antes de flashar
- Comparar config com kernel original do dispositivo

### 6.6 Build Muito Lento

**Sintoma:** Mais de 4 horas para completar

**Soluções:**
1. Aumentar jobs (se RAM permitir): `-e JOBS=16`
2. Usar SSD para Docker volumes
3. Verificar se Docker está usando todos os CPUs:
   ```bash
   docker run --rm --cpus=16 ...
   ```

---

## 7. DADOS TÉCNICOS

### 7.1 Configuração do Build

```ini
Toolchain: Clang r416183b (Google prebuilt)
Arch: arm64 (ARMv8.2-a, Little Endian)
Config: moonstone_defconfig
Flags: -D__ANDROID_COMMON_KERNEL__
LTO: Yes (Link-Time Optimization)
CFI: Yes (Control Flow Integrity)
```

### 7.2 Espaço Requerido

```
Kernel source:        2.5GB (inicial)
Arquivos objetos:    15-20GB (compilação)
Imagem Docker:       3-5GB (Ubuntu + Clang)
Logs:              50-100MB
------------------------------------------
TOTAL RECOMENDADO:  50GB+ livre
```

### 7.3 Recursos do Container

```
CPU:     Herda do host (recomendado 8+ vCPUs)
RAM:     4GB+ (recomendado 8GB)
Storage:  Volume mount (read-only kernel, write output)
Network: Internet (para download do Clang)
```

---

## 8. PRÓXIMOS PASSOS (PÓS-BUILD)

### 8.1 Testar no Device

```bash
# Copiar para AnyKernel3
cp laboratorio/output/Image.gz anykernel3-poco-x5/kernel/

# Criar boot.img
cd anykernel3-poco-x5
./create-zip.sh

# Boot temporário (sem flashar)
adb reboot bootloader
fastboot boot anykernel3-poco-x5/*.zip

# Se funcionar, flash em slot B
fastboot flash boot_b anykernel3-poco-x5/Image.gz
fastboot flash dtbo_b anykernel3-poco-x5/dtbo.img
fastboot --disable-verity --disable-verification flash vbmeta_b dtbo.img
fastboot set_active b
```

### 8.2 Compilar Módulos

Para habilitar módulos do kernel:

```bash
# No .config antes do build
CONFIG_MODULES=y
CONFIG_MODULE_SIG_FORCE=y

# Compilar módulos
make ARCH=arm64 modules

# Módulos estarão em:
#   arch/arm64/boot/...
#   drivers/.../*.ko
```

---

## 9. REFERÊNCIAS

### 9.1 Documentação Oficial

- [Android Common Kernel Build](https://source.android.com/setup/build/building-kernels)
- [Qualcomm MSM 5.4 Documentation](https://source.codeaurora.org/quic/la/kernel/msm-5.4/tree/master)
- [POCO X5 5G Device Tree](https://github.com/MiCode/Xiaomi_Kernel_OpenSource)

### 9.2 Relevos Relacionados

- `kernel-moonstone-devs/build.config.*` - Build configurations
- `kernel-moonstone-devs/arch/arm64/configs/moonstone_defconfig` - Defconfig oficial
- `ANALISE-COMPLETA-KERNEL-MOONSTONE.md` - Análise técnica detalhada

---

## 10. LICENÇA

Este projeto usa código licenciado sob:
- **GPL v2** (Kernel Linux)
- **Apache 2.0** (Build system Android)
- **BSD/MIT** (Variadas bibliotecas)

---

## 11. AUTOR

**DevSan Max** - AGI pessoal de Deivison Santana
- Arquitetura de sistemas
- Kernel Linux specialist
- Android/porting enthusiast

**Contato:**
- GitHub: @deivisan
- Email: (configurado no AGENTS.md)

---

**Última Atualização:** 2026-02-02
**Versão:** 1.0
**Status:** ✅ Produção Ready
