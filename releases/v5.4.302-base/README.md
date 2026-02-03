# 📦 DevSan AGI Kernel 5.4.302 - Base Release

> **Kernel Android 5.4.302 compilado para POCO X5 5G (moonstone/rose)**  
> **Status:** ✅ Compilado | ⏳ Não testado em hardware  
> **Data:** 03/02/2026

---

## 📋 Conteúdo do Release

### 1. **Image.gz** (19MB)
Kernel cru compilado, pronto para:
- Teste temporário: `fastboot boot Image.gz`
- Flash direto: `fastboot flash boot_b Image.gz`

### 2. **DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip**
AnyKernel3 ZIP flashável via Recovery (TWRP/OrangeFox):
- ✅ Força instalação no slot B
- ✅ Device check (moonstone/rose)
- ✅ DevSan AGI branding
- ✅ Systemless

### 3. **anykernel3-template/**
Template AnyKernel3 customizado para POCO X5 5G:
- Script `anykernel.sh` configurado
- Suporte a slot B
- Customizável para builds futuros

---

## 🔧 Especificações Técnicas

| Propriedade | Valor |
|-------------|-------|
| **Versão Kernel** | 5.4.302 |
| **Source** | kernel-moonstone-devs (lineage-23.1) |
| **Toolchain** | Clang 17.0.2 (Android NDK r26d) |
| **Arquitetura** | ARM64 (armv8.2-a) |
| **Device** | POCO X5 5G (moonstone/rose) |
| **SoC** | Snapdragon 695 (SM6375) |
| **Tamanho** | 19MB |

---

## 🛠️ Correções Aplicadas

Este kernel inclui fixes essenciais para compilar com Clang 17.0.2:

1. **Tracing TRACE_INCLUDE_PATH** - Corrigido em todos techpacks
2. **Câmera trace header** - cam_trace.h ajustado
3. **Touchscreen FT3519T** - Firmware stub criado
4. **Power supply** - Include path corrigido
5. **TCPC** - Include tcpci.h ajustado

**Detalhes:** Ver `../../docs/ARQUIVOS-MODIFICADOS.md`

---

## 🚀 Como Usar

### Método 1: Teste Temporário (Recomendado)
```bash
# NÃO grava nada, só testa
adb reboot bootloader
fastboot boot Image.gz

# Verificar se bootou:
adb shell uname -a
# Esperado: Linux localhost 5.4.302 ... aarch64
```

### Método 2: Flash via AnyKernel3 ZIP (Recovery)
```bash
# Transferir ZIP
adb push DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip /sdcard/

# Boot recovery
adb reboot recovery

# No TWRP/OrangeFox:
# Install > Selecionar ZIP > Flash
# O ZIP vai instalar no slot B automaticamente
```

### Método 3: Flash Direto (Fastboot)
```bash
# ATENÇÃO: Só fazer se teste temporário funcionou!
adb reboot bootloader

# Flash no slot B (mantém slot A seguro)
fastboot flash boot_b Image.gz
fastboot set_active b
fastboot reboot
```

---

## ⚠️ Avisos Importantes

1. **NÃO TESTADO EM HARDWARE** - Pode causar bootloop
2. **Sempre teste via `fastboot boot` primeiro**
3. **Faça backup do boot_b atual** antes de flashar:
   ```bash
   adb shell dd if=/dev/block/by-name/boot_b of=/sdcard/boot_b_backup.img
   adb pull /sdcard/boot_b_backup.img ./
   ```
4. **Mantenha slot A intocado** - segurança

---

## ❌ Limitações

- ❌ Sem suporte Docker/LXC (configs ausentes)
- ❌ Sem módulos externos carregáveis
- ❌ Não validado em hardware real
- ❌ Sem configs AppArmor/SELinux custom

**Próxima versão (v5.4.302-docker):** Incluirá suporte completo a containers.

---

## 🆘 Recuperação (se der problema)

### Bootloop:
```bash
# Forçar power off: segurar Power 10s
# Boot recovery: Vol+ + Power
# Ou via fastboot:
fastboot flash boot_b boot_b_backup.img
fastboot set_active a
fastboot reboot
```

---

## 📊 Checksums

```bash
# Image.gz
sha256sum Image.gz

# AnyKernel3 ZIP
sha256sum DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip
```

---

## 📚 Documentação Completa

Ver repositório principal:
- `docs/HISTORICO-BUILDS.md` - Histórico de builds
- `docs/BUILD-5.4.302-RUNBOOK.md` - Como rebuildar
- `docs/INSTRUCOES-FLASH.md` - Guia detalhado de flash
- `README-5.4.302-SLOTB.md` - Guia master

---

## 🎯 Roadmap

- [x] Build kernel 5.4.302 base
- [x] AnyKernel3 ZIP
- [ ] Teste em hardware
- [ ] Validação de drivers
- [ ] Build com suporte Docker/LXC
- [ ] Patches Halium
- [ ] Suporte Ubuntu Touch

---

**Compilado por:** DevSan AGI  
**Device:** POCO X5 5G (moonstone/rose)  
**Versão:** v5.4.302-base  
**Data:** 03/02/2026  
**Licença:** GPL-2.0 (Linux Kernel)
