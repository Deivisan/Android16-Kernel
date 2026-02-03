# 📘 RUNBOOK - BUILD KERNEL 5.4.302 (moonstone/rose)

**Objetivo:** build nativo do kernel 5.4.302 com NDK r26d (Clang 17.0.2) e correções aplicadas.  
**Status atual:** ✅ build OK, ❌ ainda não testado no device.

---

## ✅ Pré-requisitos

- NDK r26d instalado em: `~/Downloads/android-ndk-r26d`
- Kernel source: `~/Projetos/android16-kernel/kernel-moonstone-devs`
- Script de build: `~/Projetos/android16-kernel/build/build-5.4.302.sh`

---

## ✅ Script consolidado (build que funciona)

```bash
cd ~/Projetos/android16-kernel/build
./build-5.4.302.sh --tracing-fix -j12
```

**Saída esperada:**
- `arch/arm64/boot/Image.gz` gerado
- Build log salvo em `build/build-5.4.302-<timestamp>.log`

---

## ✅ Ambiente obrigatório (se fizer build manual)

```bash
export NDK_PATH=~/Downloads/android-ndk-r26d
export CLANG_BIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin
export ARCH=arm64
export SUBARCH=arm64
export CC=$CLANG_BIN/clang
export CXX=$CLANG_BIN/clang++
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LLVM=1
export PATH=$CLANG_BIN:$PATH

make ARCH=arm64 moonstone_defconfig
make ARCH=arm64 olddefconfig
make ARCH=arm64 scripts
make ARCH=arm64 -j12 Image.gz
```

---

## ✅ Fixes aplicados (não reverter)

### 1) Tracing (Clang include path)
- Script: `build/apply-tracing-fixes.sh`
- Corrige `TRACE_INCLUDE_PATH` em techpacks e walt

### 2) Câmera (trace header)
- `techpack/camera/drivers/cam_utils/cam_trace.h`
- `TRACE_INCLUDE_FILE cam_trace`
- `TRACE_INCLUDE_PATH techpack/camera/drivers/cam_utils`

### 3) Touchscreen FT3519T (firmware ausente)
- `drivers/input/touchscreen/FT3519T/focaltech_flash/focaltech_upgrade_ft3519t.c`
  - remove include de pramboot inexistente
  - `pb_file_ft5452j[] = { }`
  - `pramboot_supported = false`
  - `write_pramboot_private = NULL`
- `drivers/input/touchscreen/FT3519T/focaltech_config.h`
  - macros apontam para stub
- Novo: `drivers/input/touchscreen/FT3519T/include/firmware/fw_stub.i`

### 4) Power supply include
- `drivers/power/supply/pd_policy_manager.h`
- include ajustado para `../../usb/typec/tcpc/inc/tcpm.h`

### 5) TCPC include
- `drivers/usb/typec/tcpc/inc/pd_dpm_pdo_select.h`
- include ajustado para `"tcpci.h"`

---

## ✅ Estratégia de teste (slot B)

1) **Boot temporário (não grava nada):**
```bash
fastboot boot ~/Projetos/android16-kernel/kernel-moonstone-devs/arch/arm64/boot/Image.gz
```

2) **Se OK, flash no slot B:**
```bash
fastboot flash boot_b ~/Projetos/android16-kernel/kernel-moonstone-devs/arch/arm64/boot/Image.gz
fastboot set_active b
fastboot reboot
```

---

## 📦 Artefatos

- Kernel final: `kernel-moonstone-devs/arch/arm64/boot/Image.gz`
- Cópia: `build/out/Image-<timestamp>.gz`
- Log: `build/build-5.4.302-<timestamp>.log`

---

## ❌ O que **NÃO** fazer

- Não usar GCC 15.x ou Clang 21.x
- Não buildar sem `olddefconfig` (vai abrir prompts)
- Não flashar em slot A antes de testar

---

## ✅ Status

- Build: **OK**
- Teste em device: **PENDENTE**
- Flash: **PENDENTE** (aguardando OK do teste)
