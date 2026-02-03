# 📜 HISTÓRICO COMPLETO DE BUILDS - Android16 Kernel

**Data de criação:** 2026-02-03  
**Última atualização:** 2026-02-03  
**Propósito:** Documentar toda a jornada de tentativas de build, erros encontrados e soluções aplicadas.  
**Contexto:** Workspace limpo para kernel 5.4.302 nativo (AOSP), sem Docker.

---

## 🎯 RESUMO EXECUTIVO

Esta sessão documenta a transição de um ambiente caótico (kernel 5.4.191 HyperOS + Docker experimental) para um workspace coeso focado em **build nativo do kernel 5.4.302 AOSP** para POCO X5 5G.

### Decisões-chave desta sessão:
1. ✅ **Descartar kernel 5.4.191** (Xiaomi HyperOS) - muito específico para MIUI/HyperOS
2. ✅ **Descartar abordagem Docker** - overhead desnecessário, usar build nativo em Arch Linux
3. ✅ **Focar em kernel-moonstone-devs 5.4.302** - código AOSP puro, mantido pela comunidade
4. ✅ **Priorizar build funcional primeiro**, depois adicionar Docker/LXC
5. ✅ **Documentar tudo** - cada erro, cada solução

---

## 📊 TODAS AS TENTATIVAS DE BUILD (Cronologia)

### Fase 1: Kernel 5.4.191 - Tentativas Iniciais (Caóticas)

| Build | Data | Compilador | Método | Resultado | Erro Principal |
|-------|------|------------|--------|-----------|----------------|
| **v1-v6** | 02/02 | GCC 15.1.0 | Local | ❌ FALHA | Incompatibilidade total com kernel 5.4 |
| **v7-v9** | 02/02 | Clang 21.1.6 | Local | ❌ FALHA | Mesmos erros + hardcoded -Werror |
| **v10-v11** | 02/02 | NDK Clang 17.0.2 | Local | ❌ FALHA | gcc-wrapper.py bloqueando warnings |
| **v12** ✅ | 02/02 | **NDK r26d Clang 17.0.2** | **Local** | **✅ SUCESSO** | **Build completo!** |

#### Detalhes do Build v12 (O ÚNICO que funcionou):
- **Kernel:** 5.4.191 (Xiaomi moonstone-s-oss)
- **Compilador:** Android NDK r26d (Clang 17.0.2)
- **Tamanho:** 15MB (Image.gz)
- **Tempo:** ~60 minutos
- **Fixes aplicados:**
  1. `scripts/gcc-wrapper.py` - Desabilitado bloqueio de warnings da Xiaomi
  2. `arch/arm64/include/asm/bootinfo.h` - Corrigido tipo `unsigned int` → `int`
  3. `fs/proc/meminfo.c` - Casts para format strings
  4. `include/trace/events/psi.h` - Removida flag `#` inválida

#### Por que v12 funcionou:
- Usou NDK r26d (Clang 17.0.2) em vez de GCC 15 ou Clang 21
- Aplicou fix no `gcc-wrapper.py` que ignorava `WERROR=0`
- Corrigiu conflito de tipos no header

**ARQUIVOS DESTA FASE:** Movidos para `deprecated/` em 2026-02-03

---

### Fase 2: Docker Experimental (Abordagem descartada)

| Data | O que foi criado | Status |
|------|------------------|--------|
| 02-03/02 | Dockerfile Ubuntu 20.04 + NDK r23b | ❌ **DESCARTADO** |
| 02-03/02 | Scripts de build Docker (vários) | ❌ **DESCARTADO** |
| 02-03/02 | Sistema de correções automáticas de tracing | ✅ **LÓGICA SALVA** |
| 02-03/02 | Documentação Docker extensa | ✅ **CONHECIMENTO EXTRAÍDO** |

#### Problemas identificados na abordagem Docker:
1. **Complexidade desnecessária** - Container adiciona camada de indireção
2. **Download massivo** - Clang r416183b (~800MB) + Ubuntu image
3. **Tempo de build** - 2-4 horas (igual ao nativo, mas com overhead)
4. **Dificuldade de debug** - Logs dentro de container são mais difíceis de acessar

#### Conhecimento valioso extraído do Docker:
- **Problema de tracing:** `TRACE_INCLUDE_PATH .` não funciona com Clang
- **Solução:** Alterar para paths absolutos relativos ao kernel root
- **Arquivos afetados:** 9+ arquivos nos techpacks
- **Toolchain recomendada:** Clang r416183b (NDK r23b) ou Clang 17.0.2 (NDK r26d)

**ARQUIVOS DESTA FASE:** Movidos para `deprecated/laboratorio/` em 2026-02-03

---

### Fase 3: Transição para 5.4.302 (ATUAL - Workspace Limpo)

#### Descobertas importantes (03/02/2026):

**1. Repositórios de kernel disponíveis:**
| Repositório | Versão | Branch | Tamanho | Status |
|-------------|--------|--------|---------|--------|
| kernel-moonstone-devs | **5.4.302** | lineage-23.1 | 1.5 GB | ✅ **FOCO ATUAL** |
| kernel-source (Xiaomi) | 5.4.191 | moonstone-s-oss | 3.4 GB | ❌ Deprecated |

**2. Análise do defconfig 5.4.302:**
- ✅ Tem `CONFIG_NAMESPACES=y` (namespaces básicos)
- ❌ **NÃO TEM** `CONFIG_USER_NS` (Docker essencial)
- ❌ **NÃO TEM** `CONFIG_PID_NS` (explicitamente desabilitado)
- ❌ **NÃO TEM** `CONFIG_CGROUP_DEVICE` (device control)
- ❌ **NÃO TEM** `CONFIG_SECURITY_APPARMOR` (Ubuntu Touch)

**3. Build configurations existentes:**
```
build.config.common:
  LLVM=1
  CLANG_PREBUILT_BIN=prebuilts-master/clang/host/linux-x86/clang-r416183b/bin
  KCFLAGS="-D__ANDROID_COMMON_KERNEL__"
  STOP_SHIP_TRACEPRINTK=1
  IN_KERNEL_MODULES=1
  DO_NOT_STRIP_MODULES=1
```

---

## 🔧 FIXES CRÍTICOS IDENTIFICADOS

### 1. Problema: Tracing System com Clang

**Erro:**
```
./include/trace/define_trace.h:95:10: fatal error: './rmnet_trace.h' file not found
```

**Causa raiz:**
- Headers dos techpacks usam: `#define TRACE_INCLUDE_PATH .`
- Clang não resolve paths relativos `.` corretamente em macros
- Macro expande para `#include "./rmnet_trace.h"` que Clang não encontra

**Arquivos afetados (9 total):**
| Arquivo | Header |
|---------|--------|
| techpack/datarmnet/core/rmnet_handlers.c | rmnet_trace.h |
| techpack/datarmnet/core/wda_qmi.c | wda.h |
| techpack/datarmnet/core/dfc_qmi.c | dfc.h |
| techpack/camera/drivers/cam_utils/cam_trace.c | cam_trace.h |
| techpack/display/rotator/sde_rotator_base.c | sde_rotator_trace.h |
| techpack/display/msm/sde/sde_kms.c | sde_trace.h |
| techpack/dataipa/.../ipa.c | ipa_trace.h |
| techpack/dataipa/.../rndis_ipa.c | rndis_ipa_trace.h |
| techpack/video/msm/vidc/msm_vidc_debug.c | msm_vidc_events.h |
| kernel/sched/walt/trace.c | trace.h |

**Solução:**
```c
// ANTES (quebra):
#define TRACE_INCLUDE_PATH .

// DEPOIS (funciona):
#define TRACE_INCLUDE_PATH techpack/datarmnet/core
```

### 2. Problema: gcc-wrapper.py da Xiaomi

**Erro:**
```
warning: ... [treat as error]
```

Mesmo com `WERROR=0`, script da Xiaomi força falha em warnings.

**Solução aplicada no v12:**
```python
# scripts/gcc-wrapper.py
# Comentar/alterar função interpret_warning para não abortar
```

### 3. Problema: Incompatibilidade de compiladores

| Compilador | Versão | Kernel 5.4 | Status |
|------------|--------|------------|--------|
| GCC | 15.1.0 | ❌ Incompatível | Muito novo, stricter |
| Clang | 21.1.6 | ❌ Incompatível | Muito novo |
| Clang | 17.0.2 (NDK r26d) | ✅ **Compatível** | **USAR ESTE** |
| Clang | r416183b (NDK r23b) | ✅ Compatível | Usado pelo Docker lab |

**RECOMENDAÇÃO:** Usar Android NDK r26d (já baixado em ~/Downloads/)

---

## 📝 DECISÕES TOMADAS (03/02/2026)

### 1. Estratégia de Build
- ✅ **Build nativo** em Arch Linux (sem Docker)
- ✅ **NDK r26d** como toolchain (Clang 17.0.2)
- ✅ **Fase 1:** Build base 5.4.302 sem modificações (provar que compila)
- ✅ **Fase 2:** Adicionar configs Docker/LXC (depois de Fase 1 OK)
- ✅ **Fase 3:** Testar no device

### 2. Estrutura de diretórios
```
android16-kernel/
├── kernel-moonstone-devs/          ← Kernel 5.4.302 (não ignorar no git)
├── build/                          ← Scripts de build
│   ├── apply-tracing-fixes.sh      ← Corrige TRACE_INCLUDE_PATH
│   └── build-5.4.302.sh            ← Script principal
├── configs/                        ← Configs adicionais
│   └── aosp-docker-lxc.config      ← Configs Docker/LXC para adicionar
├── anykernel3-poco-x5/             ← Template AnyKernel3
├── docs/                           ← Documentação
├── backups/                        ← Backups do device
└── deprecated/                     ← Arquivos antigos (ignorados)
    ├── kernel-source/              ← 5.4.191 Xiaomi
    ├── laboratorio/                ← Docker experiments
    └── ...
```

### 3. O que NÃO fazer agora
- ❌ Não adicionar configs Docker/LXC antes de provar build base
- ❌ Não usar Docker (overhead desnecessário)
- ❌ Não modificar código fonte além do necessário para tracing
- ❌ Não buildar com GCC 15 ou Clang 21

---

## 🎯 ESTADO ATUAL DO WORKSPACE (Pós-limpeza)

### Estrutura limpa:
```
android16-kernel/
├── AGENTS.md                       ← OK
├── .gitignore                      ← Atualizado (ignora deprecated/)
├── README.md                       ← Desatualizado (fala de 5.4.191)
├── RESUMO-FINAL.md                 ← Desatualizado (fala de 5.4.191)
├── VERSAO.txt                      ← Desatualizado (5.4.191)
├── compilar-kernel.sh              ← Script antigo (5.4.191)
├── anykernel3-poco-x5/             ← OK (template funcional)
├── backups/                        ← OK (device backups)
├── build-scripts/                  ← OK (scripts antigos)
├── build/                          ← NOVO (vazio, para scripts novos)
├── configs/                        ← NOVO (vazio, para configs)
├── deprecated/                     ← NOVO (com conteúdo movido)
├── docs/                           ← OK (documentação existente)
│   ├── HISTORICO-COMPLETO.md       ← Antigo (5.4.191)
│   ├── HISTORICO-BUILDS.md         ← ESTE ARQUIVO
│   └── ...
└── kernel-moonstone-devs/          ← Kernel 5.4.302 (1.5GB)
```

### Kernel disponível:
- **kernel-moonstone-devs/**: 5.4.302, branch lineage-23.1
- **Versão confirmada:** Linux 5.4.302 (Makefile)
- **Defconfig:** arch/arm64/configs/moonstone_defconfig
- **Build configs:** build.config.common, build.config.aarch64, etc.

---

## 🚀 PRÓXIMOS PASSOS (Antes do Build)

### Pré-requisitos verificados:
- ✅ Android NDK r26d disponível em ~/Downloads/android-ndk-r26d
- ✅ kernel-moonstone-devs clonado e em 5.4.302
- ✅ Workspace limpo e organizado
- ✅ .gitignore atualizado

### Antes de buildar:
1. [ ] Criar `build/apply-tracing-fixes.sh` (script de correções)
2. [ ] Criar `build/build-5.4.302.sh` (script principal)
3. [ ] Criar `configs/aosp-docker-lxc.config` (configs para Fase 2)
4. [ ] Atualizar README.md para refletir foco em 5.4.302
5. [ ] Documentar toolchain exata (NDK r26d)
6. [ ] **PAUSA** - Revisar tudo antes do primeiro build

### Critérios de sucesso para Fase 1 (Build Base):
- ✅ `arch/arm64/boot/Image.gz` gerado
- ✅ Sem erros fatais de compilação
- ✅ Warnings aceitáveis (< 1000)
- ✅ Build completa sem intervenção manual

---

## 📚 REFERÊNCIAS E RECURSOS

### Documentos úteis extraídos do Docker lab (deprecated/):
- `ANALISE-COMPLETA-KERNEL-MOONSTONE.md` - Análise técnica detalhada
- `README-DOCKER-BUILD.md` - Conhecimento sobre tracing
- `KNOWN-ISSUES.md` - Erros conhecidos

### Toolchain:
- **Recomendada:** Android NDK r26d (Clang 17.0.2)
- **Local:** ~/Downloads/android-ndk-r26d
- **Alternativa:** Clang r416183b (NDK r23b) - mais estável segundo docs

### Repositórios:
- **kernel-moonstone-devs:** https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_moonstone
- **Branch:** lineage-23.1
- **Versão:** 5.4.302

---

## ⚠️ NOTAS IMPORTANTES

### Sobre o kernel 5.4.191:
- Foi compilado uma única vez (build v12)
- **NUNCA foi testado em hardware real**
- Código específico para HyperOS (não AOSP)
- Movido para deprecated/ para preservar história, mas não usar

### Sobre o kernel 5.4.302:
- **Código AOSP puro** (lineage-23.1)
- Mantido pela comunidade xiaomi-sm6375-devs
- Provavelmente já tem patches de segurança mais recentes
- Defconfig precisa ser modificado para Docker/LXC (Fase 2)

### Sobre builds futuros:
- Cada build deve ser documentado neste arquivo
- Erros novos = atualizar este documento
- Soluções = registrar para referência futura

---

**Próxima ação:** Criar scripts de build para 5.4.302  
**Status:** ✅ Workspace limpo, pronto para iniciar builds limpos  
**Data:** 2026-02-03 10:00 BRT
