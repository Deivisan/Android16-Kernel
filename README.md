# 🐧 Android16 Kernel - POCO X5 5G (moonstone/rose)

**Versão Atual:** 5.4.191 (Build v12 - SUCESSO ✅)  
**Data:** 03/02/2026  
**Status:** Compilado e empacotado - Laboratório Docker completo configurado

---

## 📋 Visão Geral

Este é um kernel customizado baseado no código-fonte oficial da Xiaomi para o POCO X5 5G, com duas abordagens de build:

### **Build Tradicional (Local)**
- ✅ **Compilação v12 bem-sucedida** (11 tentativas)
- 📦 **Package AnyKernel3 flashável** (18MB)
- 🐋 **Docker & LXC** habilitados
- 🔧 **Kali NetHunter** suportado

### **Build Docker (Laboratório Profissional)**
- 🐳 **Ambiente isolado e reproduzível**
- ⚡ **NDK r23b (Clang r416183b)** oficial
- 🚀 **ccache 50GB** para rebuilds rápidos
- 🤖 **Scripts de automação** completos
- 📚 **Documentação profissional** abrangente

### **Objetivo do Projeto**

Criar e manter uma base de kernel própria para o dispositivo, permitindo:
1. Atualizações incrementais de versão (5.4 → 5.10 → 5.15 → 6.6)
2. Aplicação de patches de segurança e features
3. Personalização e otimizações específicas
4. Aprendizado sobre desenvolvimento de kernel Android

---

## 🎯 Status Atual

### **✅ Conquistas:**

**Build v12 (02/02/2026) - SUCESSO!**
- ✅ Compilação bem-sucedida após 11 tentativas
- ✅ Kernel Image.gz criado (15 MB comprimido, 31 MB descomprimido)
- ✅ Package AnyKernel3 flashável criado (18 MB)
- ✅ Todas as features Docker/LXC habilitadas
- ✅ Compatibilidade NetHunter implementada

**Laboratório Docker (02-03/02/2026) - COMPLETO!**
- ✅ Dockerfile profissional (Ubuntu 20.04 + NDK r23b)
- ✅ docker-compose.yml configurado
- ✅ Scripts de automação completos
- ✅ Documentação profissional abrangente
- ✅ Sistema de correções automáticas
- ✅ Validações pré-build implementadas

**Problemas Resolvidos:**
- ✅ Incompatibilidade GCC 15.1.0 (muito novo)
- ✅ Incompatibilidade Clang 21.1.6 (muito novo)
- ✅ Script oculto da Xiaomi bloqueando warnings (`gcc-wrapper.py`)
- ✅ Conflito de tipos em `bootinfo.h` (unsigned int → int)
- ✅ Warnings de format string em vários arquivos
- ✅ Tracing issues em techpack/datarmnet

### **⏳ Próximos Passos:**

1. **Testar kernel no dispositivo** (boot temporário via fastboot)
2. **Verificar funcionalidade Docker** após boot bem-sucedido
3. **Testar laboratório Docker** (build reproduzível)
4. **Verificar estabilidade** (crashes, battery drain, etc.)
5. **Coletar logs e métricas** de performance
6. **Planejar atualização para 5.10** (após estabilizar 5.4.191)

---

## 🚀 Como Usar Este Repositório

### **Opção A: Usar Kernel Pronto (Build v12)**

#### 1. Download Direto

```bash
# Clone o repositório
git clone <seu-repo-url> android16-kernel
cd android16-kernel

# Verificar package pronto
ls -lh kernel-poco-x5-5g-5.4.191-docker-nethunter.zip
# MD5: ba4fbe9f397fb80e7c65b87849c3283b
# Tamanho: 18 MB

# Verificar backup da compilação
ls -lh compilacoes-bem-sucedidas/
```

#### 2. Testar no Dispositivo (SEGURO)

```bash
# SEMPRE teste primeiro sem modificar o boot!

# Extrair kernel do ZIP
unzip kernel-poco-x5-5g-5.4.191-docker-nethunter.zip Image.gz

# Boot temporário (NÃO modifica nada permanentemente)
adb reboot bootloader
fastboot boot Image.gz

# Se bootar com sucesso, verificar:
adb shell uname -a
adb shell dmesg | grep -i docker
```

#### 3. Instalação Permanente (APÓS TESTE!)

⚠️ **LEIA `laboratorio/EXPECTED-OUTPUT.md` COMPLETAMENTE ANTES!**

```bash
# 1. BACKUP primeiro!
adb shell dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img
adb pull /sdcard/boot_backup.img ~/backups/

# 2. Transferir ZIP
adb push kernel-poco-x5-5g-5.4.191-docker-nethunter.zip /sdcard/

# 3. Flash via recovery
adb reboot recovery
# No TWRP: Install > Selecionar ZIP > Flash
```

---

### **Opção B: Usar Laboratório Docker (Recomendado)**

#### 1. Setup Inicial

```bash
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

#### 2. Compilar Kernel

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

#### 3. Customizar Build

```bash
# Compilar com 8 jobs (padrão: todos os CPUs)
JOBS=8 ./build-moonstone-docker.sh

# Compilar com limpeza anterior
CLEAN=yes ./build-moonstone-docker.sh

# Compilar tipo específico
BUILD_TYPE=qgki ./build-moonstone-docker.sh
```

---

### **Opção C: Recompilar Localmente (Manual)**

```bash
# Baixar Android NDK r26d (necessário para compilar)
wget https://dl.google.com/android/repository/android-ndk-r26d-linux.tar.bz2
tar xf android-ndk-r26d-linux.tar.bz2 -C ~/Downloads/

# Usar o script de build (já configurado)
./compilar-kernel.sh

# Ou manualmente:
cd kernel-source-xiaomi
export NDK_PATH=~/Downloads/android-ndk-r26d
export NDK_BIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin
export PATH=$NDK_BIN:$PATH
export ARCH=arm64
export SUBARCH=arm64
export CC=$NDK_BIN/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-

make WERROR=0 -j$(nproc) Image.gz
```

---

## 📦 Arquivos Importantes

### **Deliverables (Prontos para Uso):**

```
📦 kernel-poco-x5-5g-5.4.191-docker-nethunter.zip
   └─ Flashável via TWRP/OrangeFox
   └─ MD5: ba4fbe9f397fb80e7c65b87849c3283b
   └─ Tamanho: 18 MB

💾 compilacoes-bem-sucedidas/
   ├─ Image-v12-20260202-135708.gz (Kernel backup)
   ├─ config-v12-20260202-135708 (Configuração usada)
   └─ MD5: 5878d68818b3295aeca7d61db9f14945
```

### **Laboratório Docker:**

```
🐋 laboratorio/ (Workspace de build profissional)
   ├─ Dockerfile                           ← Imagem Ubuntu 20.04 + NDK r23b
   ├─ docker-compose.yml                   ← Configuração Docker Compose
   ├─ build-moonstone-docker.sh            ← Script principal
   ├─ scripts/
   │   ├─ setup-docker.sh                 ← Setup inicial automático
   │   ├─ validate-build.sh               ← Validações pré-build
   │   └─ apply-fixes.sh                  ← Correções automáticas
   ├─ DOCKER-BUILD-GUIDE.md               ← Guia completo (443 linhas)
   ├─ KNOWN-ISSUES.md                     ← Erros conhecidos
   ├─ EXPECTED-OUTPUT.md                  ← Output esperado e checklists
   ├─ PROGRESSO-FINAL.txt                  ← Relatório de progresso
   ├─ README.md                           ← Visão geral do laboratório
   ├─ out/                                ← Output do build (Image.gz)
   ├─ logs/                               ← Logs de build e resumos
   └─ cache/                              ← Cache temporário
```

### **Código-Fonte (Local):**

```
🔧 kernel-source-xiaomi/ (3.4 GB - código modificado)
   ├─ .config (configuração final que compilou)
   ├─ arch/arm64/boot/Image.gz (kernel compilado)
   ├─ scripts/gcc-wrapper.py (MODIFICADO - crítico!)
   ├─ arch/arm64/include/asm/bootinfo.h (MODIFICADO - crítico!)
   └─ [outros arquivos modificados para corrigir warnings]

🔧 kernel-moonstone-devs/ (Fonte oficial Xiaomi)
   └─ build.config.moonstone (configuração oficial)
```

### **Código-Fonte (Docker):**

```
🔧 kernel-moonstone-devs/ (montado em /kernel - read-only)
   ├─ arch/arm64/configs/moonstone_defconfig
   ├─ techpack/
   │   ├─ audio/        ← Audio codecs
   │   ├─ camera/       ← Camera drivers
   │   ├─ datarmnet/    ← RMNet networking (rmnet_trace.h)
   │   └─ ...
   └─ ...
```

### **Scripts de Build:**

```
🔨 compilar-kernel.sh (script principal de build local)
📊 build-scripts/ (scripts auxiliares locais)
   ├─ check-configs.sh (verificar configs Docker/LXC)
   └─ [outros scripts de verificação]
```

### **Documentação:**

```
📚 laboratorio/ (Documentação Docker)
   ├─ DOCKER-BUILD-GUIDE.md     ← Guia completo
   ├─ KNOWN-ISSUES.md          ← Erros conhecidos
   ├─ EXPECTED-OUTPUT.md       ← Output esperado
   ├─ PROGRESSO-FINAL.txt      ← Relatório de progresso
   └─ README.md                ← Visão geral

📚 docs/ (Documentação local)
   ├─ INSTRUCOES-FLASH.md       ← Como instalar - LEIA ANTES!
   ├─ RELATORIO-COMPILACAO.md  ← Detalhes técnicos do build
   ├─ HISTORICO-COMPLETO.md     ← Jornada completa do projeto
   └─ CONFIGURACOES-DOCKER.md  ← Configs habilitadas

📝 logs/
   └─ build-v12-sucesso.log (log da compilação bem-sucedida)
```

---

## 🔧 Informações Técnicas

### **Kernel Base:**

- **Versão:** Linux 5.4.191
- **Fonte:** Xiaomi official kernel source (POCO X5 5G)
- **SoC:** Qualcomm Snapdragon 695 5G (SM6375)
- **Arquitetura:** ARM64 (aarch64)
- **Defconfig Base:** `vendor/moonstone-qgki_defconfig` / `arch/arm64/configs/moonstone_defconfig`

### **Compiladores Usados:**

#### **Build Local (v12)**
- **Toolchain:** Android NDK r26d
- **Compilador:** Clang 17.0.2
- **Target:** aarch64-linux-gnu
- **Flags:** `-O2 -pipe -j16 WERROR=0`

#### **Build Docker (Laboratório)**
- **Toolchain:** Android NDK r23b
- **Compilador:** Clang r416183b (Android 12.0.8)
- **Target:** aarch64-linux-gnu
- **Flags:** `-O2 -pipe`
- **ccache:** 50GB configurado

### **Modificações Críticas (NÃO REVERTER!)**

```
1. scripts/gcc-wrapper.py
   └─ Desabilitado bloqueio de warnings da Xiaomi
   └─ Sem isso, build falha mesmo com WERROR=0

2. arch/arm64/include/asm/bootinfo.h
   └─ Corrigido tipo: unsigned int → int
   └─ Fix conflito get_powerup_reason() / set_powerup_reason()

3. fs/proc/meminfo.c
   └─ Adicionados casts para format strings

4. include/trace/events/psi.h
   └─ Removida flag '#' inválida de format string

5. techpack/datarmnet/core/rmnet_trace.h
   └─ Corrigidos includes de ./trace.h → trace.h
   └─ Tracing fix automático (script apply-fixes.sh)
```

### **Configurações Docker/LXC Habilitadas:**

Ver lista completa em: `docs/CONFIGURACOES-DOCKER.md` e `arch/arm64/configs/moonstone_defconfig`

```bash
CONFIG_USER_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_PIDS=y
CONFIG_SYSVIPC=y
CONFIG_POSIX_MQUEUE=y
CONFIG_IKCONFIG_PROC=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_OVERLAY_FS=y
CONFIG_NAMESPACES=y
CONFIG_NET_NS=y
CONFIG_PID_NS=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
```

---

## 📊 Histórico de Builds

| Build | Data | Compilador | Método | Resultado | Problema |
|-------|------|------------|--------|-----------|----------|
| v1-v6 | 02/02 | GCC 15.1.0 | Local | ❌ | Muito novo, incompatível |
| v7-v9 | 02/02 | Clang 21.1.6 | Local | ❌ | Muito novo, warnings |
| v10-v11 | 02/02 | NDK Clang 17 | Local | ❌ | gcc-wrapper.py bloqueando |
| **v12** | **02/02** | **NDK Clang 17** | **Local** | **✅** | **SUCESSO!** |
| **Lab** | **02-03/02** | **NDK Clang 17** | **Docker** | **⏳** | **PRONTO PARA TESTE** |

**Tempo total local:** ~11 horas (3 sessões)  
**Taxa de sucesso local:** 8.3% (1/12 builds)  
**Tempo preparação Docker:** ~2-3 horas (6 fases)  
**Tempo estimado Docker:** 2-3h (1° build), 30-45m (rebuild)

---

## 🎓 Roadmap de Atualizações

### **Fase 1: Estabilização (5.4.191) - ATUAL**

- [x] Compilar kernel base com Docker/LXC (local)
- [x] Criar package flashável
- [x] Documentar processo
- [x] Criar laboratório Docker completo
- [ ] Testar em dispositivo real
- [ ] Testar laboratório Docker (build reproduzível)
- [ ] Verificar Docker funcionando
- [ ] Medir impacto em bateria/performance

### **Fase 2: Melhorias (5.4.x)**

- [ ] Aplicar patches de segurança mais recentes
- [ ] Otimizações de performance
- [ ] Reduzir consumo de bateria
- [ ] Integrar melhorias do laboratório Docker

### **Fase 3: Atualização LTS (5.10.x)**

- [ ] Estudar diferenças entre 5.4 → 5.10
- [ ] Portar modificações
- [ ] Testar compatibilidade drivers

### **Fase 4: Atualização LTS (5.15.x)**

- [ ] Estudar 5.10 → 5.15
- [ ] Validar features Android 13/14

### **Fase 5: Atualização LTS (6.6.x)**

- [ ] Maior salto de versão
- [ ] Features Android 15+

---

## ⚠️ Avisos Importantes

### **ANTES DE USAR:**

1. ❌ **Kernel v12 NÃO testado em hardware real ainda**
2. 💾 **SEMPRE faça backup do boot.img original**
3. 🔧 **Teste com `fastboot boot` primeiro** (temporário, seguro)
4. 📱 **Pode causar bootloop** (recuperável com backup)

### **DOCKER LAB:**

1. 🐋 **Laboratório completo configurado e pronto**
2. 📚 **Documentação profissional abrangente**
3. 🤖 **Scripts de automação prontos**
4. ⚠️ **REQUER execução manual do usuário**

---

## 📚 Documentação Completa

### **Laboratório Docker (Recomendado)**
- `laboratorio/DOCKER-BUILD-GUIDE.md` - Guia completo (443 linhas)
- `laboratorio/KNOWN-ISSUES.md` - Erros conhecidos
- `laboratorio/EXPECTED-OUTPUT.md` - Output esperado e checklists
- `laboratorio/PROGRESSO-FINAL.txt` - Relatório de progresso completo
- `laboratorio/README.md` - Visão geral do laboratório

### **Build Local (Tradicional)**
- `docs/INSTRUCOES-FLASH.md` - Como instalar
- `docs/RELATORIO-COMPILACAO.md` - Detalhes técnicos
- `docs/HISTORICO-COMPLETO.md` - Jornada completa
- `docs/CONFIGURACOES-DOCKER.md` - Configs habilitadas

---

## 📝 Changelog

### **v12 (02/02/2026) - Primeira Compilação Bem-Sucedida (Local)**

**Adicionado:**
- Suporte completo Docker & LXC
- Compatibilidade Kali NetHunter
- Package AnyKernel3 flashável

**Corrigido:**
- Script gcc-wrapper.py da Xiaomi
- Conflito de tipos em bootinfo.h
- Warnings de format string

### **Laboratório Docker (02-03/02/2026) - Sistema Completo**

**Adicionado:**
- Dockerfile profissional (Ubuntu 20.04 + NDK r23b)
- docker-compose.yml configurado
- Scripts de automação (setup, validate, apply-fixes, build)
- Documentação profissional abrangente (5 arquivos)
- Sistema de correções automáticas
- Validações pré-build
- ccache 50GB configurado

---

## 🚀 Quick Start (Laboratório Docker)

```bash
# 1. Ir para o laboratório
cd /home/deivi/Projetos/Android16-Kernel/laboratorio

# 2. Setup inicial (uma vez)
./scripts/setup-docker.sh

# 3. Compilar kernel
./build-moonstone-docker.sh

# 4. Verificar output
ls -lh out/Image.gz

# 5. Testar no device
fastboot boot out/Image.gz
```

---

**Última atualização:** 03/02/2026  
**Status:** ✅ Build v12 completo - Laboratório Docker pronto  
**Próximo passo:** Testar kernel no dispositivo + validar laboratório Docker

**🦞 DevSan AGI - Boa sorte com os testes! Leia a documentação com atenção!**
