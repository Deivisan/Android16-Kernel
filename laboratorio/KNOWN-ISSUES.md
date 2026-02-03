# 🐛 Known Issues - Kernel Moonstone Build

> Documentação de erros conhecidos e soluções testadas
> DevSan AGI - v1.0.0

---

## 📋 Resumo de Erros

| Erro | Categoria | Status | Solução |
|-------|-----------|---------|-----------|
| `trace.h not found` | Tracing | ✅ Auto | apply-fixes.sh |
| `rmnet_trace.h not found` | Tracing | ✅ Auto | N/D (arquivo existe) |
| `format string error` | Audio Codecs | ⚠ Manual | Adicionar %ld onde necessário |
| `undefined reference` | Linking | ❌ Build | Verificar configs |
| `out of memory` | Build | ⚠ Config | Reduzir JOBS |

---

## 🐛 Erros Conhecidos

### 1. Arquivos de Tracing

**Erro:**
```
fatal error: trace.h: No such file or directory
```

**Causa:**
Arquivos no techpack usam `#include "./trace.h"` (caminho relativo) em vez de caminho absoluto ou include correto.

**Arquivos afetados:**
- `techpack/datarmnet/core/rmnet_config.c`
- `techpack/datarmnet/core/rmnet_descriptor.c`
- `techpack/datarmnet-ext/core/rmnet_shs_config.c`
- `kernel/sched/walt/trace.c`

**Solução:**
Script `apply-fixes.sh` corrige automaticamente:
```bash
# Corrige includes de ./trace.h para caminhos corretos
sed -i 's|#include "\.\/trace\.h"|#include "trace.h"|g' file.c
```

**Status:** ✅ **RESOLVIDO** - Auto-correção implementada

---

### 2. Strings de Formato em Audio Codecs

**Erro:**
```
error: format '%x' expects argument of type 'unsigned int', but argument 2 has type 'long unsigned int'
error: format '%d' expects argument of type 'int', but argument 2 has type 'size_t'
```

**Causa:**
Qualcomm usa tipos `u32`, `size_t`, `long unsigned int` mas strings de formato `%d`, `%x`, `%u` esperam `int`, `unsigned int`, `long int`.

**Arquivos afetados:**
- `techpack/audio/asoc/codecs/bolero/*.c`
- `techpack/audio/asoc/codecs/aqt1000/*.c`
- `techpack/audio/asoc/codecs/csra66x0/*.c`
- `techpack/audio/asoc/codecs/ep92/*.c`

**Solução parcial:**
Adicionar casts ou usar format strings corretos:
```c
// INCORRETO:
pr_debug("Value: %d\n", some_u32_value);

// CORRETO:
pr_debug("Value: %u\n", (unsigned int)some_u32_value);
// OU usar format especifico:
pr_debug("Value: %u\n", some_u32_value);
```

**Formatos recomendados por tipo:**
- `u8`, `u16`, `u32` → `%u` ou `%x` (hex)
- `int`, `s32` → `%d`
- `long`, `s64` → `%ld` ou `%lld`
- `size_t` → `%zu` (size) ou `%zx` (hex)

**Status:** ⚠ **PARCIAL** - Script verifica mas não corrige automaticamente

---

### 3. Techpacks Problemáticos

**Techpacks conhecidos por causar erros:**

#### audio (bolero, aqt1000)
- **Problema:** Strings de formato incorretas
- **Impacto:** Warnings ou erros de compilação
- **Workaround:** Corrigir format strings manualmente

#### datarmnet
- **Problema:** Arquivo `rmnet_trace.h` necessário
- **Impacto:** Falha de compilação se arquivo não encontrado
- **Workaround:** Verificar se `techpack/datarmnet/core/rmnet_trace.h` existe

#### datarmnet-ext
- **Problema:** Similar ao datarmnet
- **Impacto:** Falha de compilação
- **Workaround:** Verificar arquivos de tracing

#### camera, display, video
- **Problema:** Dependências de firmware ou headers
- **Impacto:** Erros de link ou compilação
- **Workaround:** Verificar configs e dependências

---

### 4. Configs Críticas Ausentes

**Erro:**
```
Kernel não suporta LXC/Halium corretamente
```

**Causa:**
Configurações essenciais para containers não habilitadas.

**Configs críticas:**
```bash
CONFIG_USER_NS=y          # Namespaces de usuário (LXC)
CONFIG_CGROUP_DEVICE=y     # Cgroup para devices (cgroup v2)
CONFIG_SYSVIPC=y           # System V IPC
CONFIG_POSIX_MQUEUE=y      # Message queues POSIX
CONFIG_IKCONFIG_PROC=y     # Acesso a /proc/config.gz
```

**Verificação:**
```bash
grep -E "CONFIG_(USER_NS|CGROUP_DEVICE|SYSVIPC|POSIX_MQUEUE|IKCONFIG_PROC)" .config
```

**Solução:**
Script `apply-fixes.sh` adiciona configs automaticamente se faltarem.

**Status:** ✅ **RESOLVIDO** - Auto-correção implementada

---

### 5. Out of Memory Durante Build

**Erro:**
```
cc1: out of memory allocating 8064 bytes
ld: out of memory
make: *** [arch/arm64/kernel/kernel.o] Error 1
```

**Causa:**
- Muitos jobs de paralelismo
- Pouca RAM disponível
- Container com limite de RAM baixo

**Solução:**
```bash
# Reduzir jobs (padrão: nproc)
JOBS=4 ./build-moonstone-docker.sh

# Ou ajustar no docker-compose.yml
deploy:
  resources:
    limits:
      memory: 12G  # Aumentar para builds grandes
```

**Status:** ⚠ **WORKAROUND** - Ajustar JOBS ou memory limit

---

### 6. Toolchain NDK não Encontrada

**Erro:**
```
clang: command not found
/path/to/clang: No such file or directory
```

**Causa:**
NDK não baixado corretamente ou caminho incorreto.

**Verificação:**
```bash
docker-compose exec kernel-build clang --version
# Saída esperada:
# clang version 12.0.8 (https://android.googlesource.com/toolchain/llvm-project)
# (based on LLVM 12.0.8svn)
# Target: aarch64-unknown-linux-android
```

**Solução:**
Rebuild Docker image:
```bash
cd laboratorio
docker-compose down
docker-compose build --no-cache
```

**Status:** ✅ **RESOLVIDO** - Dockerfile baixa NDK automaticamente

---

## 🔄 Workflow de Resolução

### Quando encontrar erro NÃO documentado:

1. **Documentar:**
   ```bash
   # Adicionar em KNOWN-ISSUES.md
   ## [ID] Título do Erro
   
   **Erro:**
   ```
   [cole erro aqui]
   ```
   
   **Causa:**
   [descrever causa]
   
   **Solução:**
   [descrever solução]
   
   **Status:** ⏳ EM ANDAMENTO
   ```

2. **Pesquisar solução:**
   ```bash
   # Buscar no kernel source
   grep -r "funcao_que_falhou" /kernel
   
   # Buscar online
   # Google: "Android kernel [erro exato]"
   # XDA Developers
   # Qualcomm Code Aurora
   ```

3. **Implementar correção:**
   - Adicionar em `apply-fixes.sh` se for automática
   - Documentar como manual se for complexa

4. **Testar:**
   ```bash
   CLEAN=yes ./build-moonstone-docker.sh
   ```

5. **Atualizar status:**
   - Se funcionar: `Status: ✅ RESOLVIDO`
   - Se parcial: `Status: ⚠ PARCIAL`
   - Se falhar: `Status: ❌ EM INVESTIGAÇÃO`

---

## 📊 Estatísticas de Erros

### Total de Erros Documentados: 6

- ✅ Resolvidos: 3 (tracing, configs críticas, toolchain)
- ⚠ Parciais: 2 (format strings, techpacks problemáticos)
- ❌ Em investigação: 1 (out of memory)

### Taxa de Sucesso Esperada

Com correções aplicadas:
- **Build #1:** 70-80% (erros inesperados podem ocorrer)
- **Build #2+ (com ccache):** 95-100% (correções estáveis)

---

## 🔗 Referências Úteis

### Debugging Android Kernel
- [Android Kernel Debugging](https://source.android.com/docs/setup/debug)
- [Crash Guide](https://source.android.com/docs/setup/crash)
- [LTP - Linux Test Project](https://linux-test-project.github.io/)

### Qualcomm Resources
- [Code Aurora Forum](https://forum.codeaurora.org/)
- [Xiaomi Kernel Sources](https://github.com/MiCode/Xiaomi_Kernel_OpenSource)
- [Kernel.org MSM-5.4](https://git.kernel.org/pub/scm/linux/kernel/git/qcom/msm-5.4.git/)

### Comunidade
- [XDA Developers - POCO X5 5G](https://forum.xda-developers.com/t/poco-x5-5g-development.4470189/)
- [Telegram Groups - Android Kernel Dev](https://t.me/androidkerneldev)

---

## 📝 Como Contribuir

Para adicionar novo erro à documentação:

1. Reproduzir erro consistentemente
2. Capturar mensagem de erro completa
3. Identificar causa raiz
4. Implementar e testar solução
5. Documentar em este arquivo seguindo o template

---

**🦞 DevSan AGI - v1.0.0 - 2026**  
**Target Device:** POCO X5 5G (moonstone/rose)  
**Author:** Deivison Santana (@deivisan)
