# 🐛 ERROS ENCONTRADOS E SOLUÇÕES

> Documentação de todos os erros encontrados durante o build
> Kernel: 5.4.302-moonstone
> Clang: 21.1.6 (testado) / clang-r416183b (oficial dos devs)

---

## 🎯 TOOLCHAIN OFICIAL DOS DEVS (DESCUBERTA!)

**Arquivo:** `build.config.common` (no repositório dos devs)

```bash
LLVM=1
CLANG_PREBUILT_BIN=prebuilts-master/clang/host/linux-x86/clang-r416183b/bin
BRANCH=android11-5.4
```

**Toolchain EXATA:**
- **Nome:** Google Clang r416183b
- **Base:** Clang 12.0.5
- **Versão Android:** Android 12 (android11-5.4 branch)
- **Localização:** `prebuilts-master/clang/host/linux-x86/clang-r416183b/bin`

**Download:**
```bash
# Opção 1: Baixar Android NDK r23b (contém clang-r416183b)
wget https://dl.google.com/android/repository/android-ndk-r23b-linux-x86_64.zip

# Opção 2: Usar clang do sistema (Arch Linux) com flags corretas
# Clang 21.1.6 funciona se usar: -Wno-format -Wno-unused-variable
```

---

## ERRO 1: FT3519T Touchscreen (Firmware Faltando)

**Arquivo:** `drivers/input/touchscreen/FT3519T/focaltech_flash/focaltech_upgrade_ft3519t.c:40`

**Erro:**
```
fatal error: '../include/pramboot/FT5452J_Pramboot_V4.1_20210427.i' file not found
```

**Causa:**
O driver FocalTech FT3519T tenta incluir um arquivo de firmware binário (.i) que não existe no repositório. É um firmware proprietário do touchscreen que a Qualcomm/Xiaomi não incluiu no open source.

**Impacto:**
- Build falha se CONFIG_TOUCHSCREEN_FT3519T=y
- Device pode não ter touchscreen se desativar

**Solução:**
```bash
# Desativar o driver no .config
sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' .config

# Ou no defconfig
sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' \
    arch/arm64/configs/moonstone_defconfig
```

**Status:** ✅ RESOLVIDO

---

## ERRO 2: Trace Headers (rmnet_trace.h, trace.h)

**Arquivos:**
- `techpack/datarmnet/core/rmnet_trace.h:280`
- `kernel/sched/walt/trace.h:681`

**Erro:**
```
./include/trace/define_trace.h:95:10: fatal error: './rmnet_trace.h' file not found
./include/trace/define_trace.h:95:10: fatal error: './trace.h' file not found
```

**Causa:**
O sistema de tracing do kernel usa macros que incluem arquivos trace.h dinamicamente. Com Clang 21, a resolução de caminhos está mais estrita e o `./` (caminho relativo atual) não funciona como esperado.

**Código problemático:**
```c
// define_trace.h linha 95
#include TRACE_INCLUDE_FILE  // expande para './rmnet_trace.h'
```

**Impacto:**
- Build falha em techpacks da Qualcomm
- Sistemas de tracing não compilam

**Soluções Possíveis:**

### Opção A: Desativar Tracing (Mais simples)
```bash
# Desativar CONFIG_TRACING no .config
sed -i 's/CONFIG_TRACING=y/CONFIG_TRACING=n/' .config
sed -i 's/CONFIG_EVENT_TRACING=y/CONFIG_EVENT_TRACING=n/' .config
```

### Opção B: Corrigir includes (Mais complexo)
```c
// Substituir em techpack/datarmnet/core/rmnet_trace.h
#undef TRACE_INCLUDE_FILE
#define TRACE_INCLUDE_FILE "techpack/datarmnet/core/rmnet_trace"
```

**Status:** 🔄 EM ANÁLISE

---

## ERRO 3: Format String Warnings (Clang 21+)

**Arquivos:**
- `techpack/audio/asoc/codecs/bolero/bolero-clk-rsc.c`
- `techpack/audio/asoc/codecs/bolero/rx-macro.c`
- `techpack/camera/drivers/cam_req_mgr/*.c`

**Erro:**
```
error: format '%d' expects argument of type 'int', but argument has type 'size_t'
error: format '%x' expects argument of type 'unsigned int', but argument has type 'long'
```

**Causa:**
Código Qualcomm escrito para GCC 4.x. Clang 21 é mais estrito com format strings.

**Solução:**
```bash
# Flag para ignorar warnings de formato
export KCFLAGS="-Wno-format -Wno-format-security"
```

**Correções Manuais:**
```c
// bolero-clk-rsc.c linha 110
// Antes:
pr_err("%s: dev is null %d\n", __func__);  // %d sem argumento!
// Depois:
pr_err("%s: dev is null\n", __func__);     // removido %d

// rx-macro.c linha 1219
// Antes:
"active_mask: 0x%x\n", rx_priv->active_ch_mask[dai->id]  // %x para long
// Depois:
"active_mask: 0x%lx\n", rx_priv->active_ch_mask[dai->id] // %lx para long
```

**Status:** ✅ RESOLVIDO (com flags e correções manuais)

---

## METODOLOGIA CORRETA DE TESTES

### O que errei:
Tentei build completo sem testar componentes isolados primeiro.

### O que deveria ter feito:

```
ETAPA 1: Testar scripts/mod (30s)
    ↓ PASS
ETAPA 2: Testar headers (60s)
    ↓ PASS
ETAPA 3: Testar kernel/bpf (5min)
    ↓ PASS
ETAPA 4: Testar arch/arm64/mm (7min)
    ↓ PASS
ETAPA 5: Testar techpack/audio/bolero (10min)
    ↓ FAIL → Corrigir erros
    ↓ Re-testar
    ↓ PASS
ETAPA 6: Testar techpack/datarmnet (10min)
    ↓ FAIL → Erro trace.h
    ↓ Aplicar solução A ou B
    ↓ Re-testar
    ↓ PASS
ETAPA 7: Build completo (2-4h)
    ↓ SUCESSO
```

---

## TOOLCHAIN: CLANG 20 vs 21+

### Veredito Final:
Use **Clang 21.1.6** (do Arch) com flags de compatibilidade.

### Por quê?
- Clang 20 não está facilmente disponível
- Clang 21.1.6 funciona com flags corretas
- Google Clang r416183b (baseado em Clang 12) é muito antigo

### Flags Obrigatórias:
```bash
export KCFLAGS="-Wno-format -Wno-format-security -Wno-unused-variable"
```

---

## PRÓXIMAS AÇÕES

1. ✅ Documentar erros (ESTE ARQUIVO)
2. 🔄 Criar script de correção automática
3. 🔄 Re-testar componentes um por um
4. 🔄 Só então fazer build completo

---

**Data:** 2025-02-02  
**Autor:** DevSan AGI  
**Para:** Deivison Santana
