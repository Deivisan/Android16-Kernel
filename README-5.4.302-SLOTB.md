# 🦞 DevSan AGI - Kernel 5.4.302 POCO X5 5G

> **Projeto completo de build e flash de kernel customizado para POCO X5 5G (moonstone/rose)**  
> **Status:** ✅ Build OK | ⏳ Aguardando teste em hardware

---

## 📦 Artefatos Disponíveis

| Arquivo | Local | Descrição |
|---------|-------|-----------|
| **Image.gz** | `kernel-moonstone-devs/arch/arm64/boot/Image.gz` | Kernel raw (19MB) |
| **Image (backup)** | `build/out/Image-20260203-105954.gz` | Cópia do build |
| **DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip** | `build/out/` | **AnyKernel3 ZIP pronto** |
| **Build Log** | `build/build-5.4.302-20260203-105423.log` | Log completo do build |

---

## 🚀 Métodos de Flash (Escolha um)

### Método 1: ZIP AnyKernel3 (Recomendado para Recovery)

**Local:** `build/out/DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip`

```bash
# Transferir para o device
adb push build/out/DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip /sdcard/

# Boot no TWRP
adb reboot recovery

# No TWRP: Install > selecionar ZIP > Flash
# O ZIP força slot B automaticamente via anykernel.sh
```

**Características do ZIP:**
- ✅ Força instalação no **slot B** (`block=/dev/block/bootdevice/by-name/boot_b`)
- ✅ DevSan AGI branding (banner ASCII art)
- ✅ Device check (moonstone/rose)
- ✅ Suporte a módulos
- ✅ Systemless (não modifica /system)

---

### Método 2: fastboot direto (Rápido, sem ZIP)

```bash
# Boot temporário (teste seguro - não grava nada)
fastboot boot kernel-moonstone-devs/arch/arm64/boot/Image.gz

# Se funcionar, flash permanente no slot B:
fastboot flash boot_b kernel-moonstone-devs/arch/arm64/boot/Image.gz
fastboot set_active b
fastboot reboot
```

---

### Método 3: boot.img via magiskboot (Avançado)

```bash
# Usar o script fornecido
./build/make-bootimg-slot-b.sh

# O script gera:
# build/out/boot-b-5.4.302-<timestamp>.img

# Flash:
fastboot flash boot_b build/out/boot-b-5.4.302-XXXXXXXX.img
fastboot set_active b
fastboot reboot
```

---

## ✅ Checklist Pré-Flash

1. **Backup do boot atual (slot B)**
```bash
adb shell dd if=/dev/block/by-name/boot_b of=/sdcard/boot_b_backup.img
adb pull /sdcard/boot_b_backup.img ~/Projetos/android16-kernel/backups/
```

2. **Verificar slot ativo**
```bash
adb shell getprop ro.boot.slot_suffix
# Deve ser _a (vamos mudar para _b)
```

3. **Bateria > 50%**

4. **Cabos USB em boas condições**

---

## 🔧 Correções Aplicadas no Kernel Source

### 1. Tracing (Clang include path)
**Script:** `build/apply-tracing-fixes.sh`
- Corrige `TRACE_INCLUDE_PATH` para Clang 17.0.2
- Afeta: techpack/datarmnet, display, dataipa, camera, video, walt

### 2. Câmera trace header
**Arquivo:** `techpack/camera/drivers/cam_utils/cam_trace.h`
- `TRACE_INCLUDE_FILE cam_trace`
- `TRACE_INCLUDE_PATH techpack/camera/drivers/cam_utils`

### 3. Touchscreen FT3519T (firmware ausente)
**Arquivos:**
- `drivers/input/touchscreen/FT3519T/focaltech_flash/focaltech_upgrade_ft3519t.c`
  - Remove include de pramboot inexistente
  - `pb_file_ft5452j[] = { }`
  - `pramboot_supported = false`
  - `write_pramboot_private = NULL`
- `drivers/input/touchscreen/FT3519T/focaltech_config.h`
  - Macros apontam para stub
- **Novo:** `drivers/input/touchscreen/FT3519T/include/firmware/fw_stub.i`

### 4. Power supply include path
**Arquivo:** `drivers/power/supply/pd_policy_manager.h`
- Include ajustado: `../../usb/typec/tcpc/inc/tcpm.h`

### 5. TCPC include path
**Arquivo:** `drivers/usb/typec/tcpc/inc/pd_dvm_pdo_select.h`
- Include ajustado: `"tcpci.h"`

---

## 🏗️ Como Rebuildar (se necessário)

```bash
cd ~/Projetos/android16-kernel/build
./build-5.4.302.sh --tracing-fix -j12
```

**Pré-requisitos:**
- NDK r26d em `~/Downloads/android-ndk-r26d`
- Kernel source: `kernel-moonstone-devs/`

**Saída esperada:**
- `kernel-moonstone-devs/arch/arm64/boot/Image.gz` (19MB)
- Build log em `build/build-5.4.302-<timestamp>.log`

---

## 📚 Documentação Relacionada

| Documento | Propósito |
|-----------|-----------|
| `docs/HISTORICO-BUILDS.md` | Histórico completo de builds |
| `docs/BUILD-5.4.302-RUNBOOK.md` | Runbook objetivo do build |
| `docs/INSTRUCOES-FLASH.md` | Instruções detalhadas de flash |
| `docs/ARQUIVOS-MODIFICADOS.md` | Lista de arquivos modificados |
| `docs/kernel-analysis.md` | Análise técnica do kernel 5.4.302 |

---

## ⚠️ O que NÃO funciona / Limitações

1. **Kernel NÃO testado em hardware real**
   - Pode causar bootloop
   - Pode não bootar
   - Drivers podem ter problemas

2. **Não inclui configs Docker/LXC ainda**
   - Kernel base compilado
   - Configs adicionais (USER_NS, CGROUP_DEVICE) na Fase 2

3. **Sem módulos externos**
   - Kernel compilado built-in
   - Sem módulos carregáveis extras

4. **Toolchain específica**
   - Só funciona com Clang 17.0.2 (NDK r26d)
   - GCC 15 ou Clang 21 não funcionam

---

## 🆘 Recuperação (se der problema)

### Bootloop após flash:
```bash
# Forçar power off: segure Power 10s
# Boot recovery: Vol+ + Power
# Ou via fastboot:
fastboot flash boot_b ~/Projetos/android16-kernel/backups/boot_b_backup.img
fastboot set_active b
fastboot reboot
```

### Sem backup:
```bash
# Extrair do backup original
# Usar ROM stock boot.img
fastboot flash boot_b boot_stock.img
fastboot reboot
```

---

## 📊 Status Atual

| Componente | Status |
|------------|--------|
| Build kernel 5.4.302 | ✅ OK |
| AnyKernel3 ZIP | ✅ OK |
| Teste temporário (fastboot boot) | ⏳ Pendente |
| Flash permanente | ⏳ Pendente (aguardando OK do teste) |
| Validação em hardware | ⏳ Pendente |

---

## 📝 Notas para Próximos Agentes

1. **NÃO reverter os fixes aplicados** - são necessários para compilar
2. **Sempre usar `olddefconfig`** - evita prompts interativos
3. **Testar via `fastboot boot` primeiro** - mais seguro
4. **Documentar resultados** - sucesso ou falha
5. **Fase 2:** Adicionar configs Docker/LXC (USER_NS, CGROUP_DEVICE, etc.)

---

## 🎯 Próximos Passos (após você confirmar que funciona)

1. ✅ Teste temporário: `fastboot boot Image.gz`
2. ✅ Se OK: flash permanente via ZIP ou fastboot
3. ✅ Validar: `uname -a` mostra 5.4.302
4. ⏳ Fase 2: Adicionar configs Docker/LXC
5. ⏳ Rebuild com configs adicionais
6. ⏳ Testar Docker/LXC em hardware

---

**Criado:** 2026-02-03  
**DevSan AGI** - Kernel Build System  
**Versão:** 5.4.302 + fixes  
**Device:** POCO X5 5G (moonstone/rose)  
**Slot:** B (only)
