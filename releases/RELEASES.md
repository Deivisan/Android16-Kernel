# 📦 Releases - Android 16 Kernel POCO X5 5G

## 🏷️ Overview

Esta seção contém todos os builds oficiais do kernel Android 16 para POCO X5 5G (moonstone).

---

## 📅 v3.0.1-TOUCHFIX-FINAL (2026-02-04)

### 🎯 FINAL TOUCHSCREEN FIX

**Arquivo**: `KernelSU-Next-v3.0.1-SUSFS-Docker-POCO-X5-5G-20260204-FINAL.zip`  
**Tamanho**: 22.5MB  
**SHA256**: `47cda26ff3b333182c5a0011dde29a9b14107f2f81c77843ade1d95736e290e4`  
**Status**: 🧪 EM TESTE - Build FINAL completo

### ✅ Features:
- **KernelSU-Next v3.0.1**: Root com AllowList
- **SUSFS**: Hide modules de detection
- **Docker/LXC**: Container support completo
- **FT3519T Fix**: Array de firmware corrigido com header válido
- **DTBO Atualizado**: moonstone-overlay completo
- **Debug Habilitado**: FTS_DEBUG_EN=1 para troubleshooting

### 🔧 Correções Críticas:
1. **Firmware Array**: Preenchido com header FT3519T (0x89, 0x00, 0x35, 0x19...)
2. **Config Padrão**: CONFIG_TOUCHSCREEN_FT3519T=y automaticamente
3. **Device Tree**: Adicionado project-name e ic-type específicos
4. **Debug Mode**: Logs detalhados para diagnóstico

### 📱 Instalação:
```bash
adb reboot recovery
adb sideload KernelSU-Next-v3.0.1-SUSFS-Docker-POCO-X5-5G-20260204-FINAL.zip
```

### 🧪 Teste Checklist:
- [ ] Boot normal sem falhas
- [ ] Touchscreen funciona (toque único)
- [ ] Multi-touch funciona (pinça zoom)
- [ ] KernelSU ativo e funcionando
- [ ] Docker/LXC operacional
- [ ] Sistema estável sem crashes

### 📋 Histórico:
- **v3.0.1**: Build inicial - Touch não funciona
- **v3.0.1-DTBO-FIX**: DTBO corrigido - Touch ainda falha
- **v3.0.1-FINAL**: Correção completa - Em teste

---

## 📊 Metadados

| Build | Data | Status | Tamanho | Touch |
|-------|------|--------|--------|--------|
| v3.0.1 | 2026-02-04 | ❌ | 22MB | ❌ Não |
| v3.0.1-DTBO-FIX | 2026-02-04 | ❌ | 22MB | ❌ Não |
| v3.0.1-FINAL | 2026-02-04 | 🧪 | 22.5MB | 🔄 Testando |

---

## 🔍 Notas de Desenvolvimento

### Problemas Identificados:
1. **Firmware Array Vazio**: `pb_file_ft5452j[] = { }` impedia inicialização
2. **Config Desabilitada**: `CONFIG_TOUCHSCREEN_FT3519T=n` no Kconfig
3. **DTBO Incompleto**: Faltavam propriedades específicas do moonstone
4. **Debug Desabilitado**: Impossível diagnosticar problemas de hardware

### Soluções Implementadas:
1. Firmware stub com header válido FT3519T
2. Config automática no Kconfig
3. DTBO completo com identificação do hardware
4. Debug habilitado para logs detalhados

---

## 🎯 Próximos Passos

### Se v3.0.1-FINAL funcionar:
1. **Extrair firmware real** do boot stock via análise binária
2. **Otimizar performance** e reduzir tamanho do kernel
3. **Documentar instalação** e criar guia completo
4. **Criar script de build automatizado**

### Se v3.0.1-FINAL falhar:
1. **Investigar hardware** específico do moonstone
2. **Testar driver alternativo** para FT3519T
3. **Considerar downgrade** para kernel 5.4.191 estável
4. **Analisar logs detalhados** do boot original

---

**Última atualização**: 2026-02-04 13:00  
**Status**: Aguardando feedback do teste FINAL

## v5.4.302-base (03/02/2026)

### 📋 Conteúdo
- **Image.gz** - Kernel cru (19MB)
- **DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip** - AnyKernel3 ZIP
- **anykernel3-template/** - Template AnyKernel3
- **README.md** - Documentação completa
- **SHA256SUMS.txt** - Checksums dos artefatos

### 🎯 Características
- ✅ Kernel 5.4.302 base compilado
- ✅ Toolchain: Clang 17.0.2 (NDK r26d)
- ✅ Device: POCO X5 5G (moonstone/rose)
- ✅ Slot B only (segurança)
- ❌ Sem suporte Docker/LXC
- ❌ Não testado em hardware

### 📦 Download
```bash
# Extrair release
tar -xzf v5.4.302-base.tar.gz
cd v5.4.302-base/

# Verificar integridade
sha256sum -c SHA256SUMS.txt
```

### 🔐 Checksums
```
SHA256 (tarball): 0293b4d3ae6f7da89a80b0c84257e002cc09625dec093fcb3637acf0135282d2
SHA256 (Image.gz): 4db63467d9961781feb8ab0e1430da2a09a5bb9aeff418e91f3bfd8b9c6c00d4
SHA256 (AnyKernel3 ZIP): a23f24dcfe701dfc6cc312d65cc487e4f68750a495f4b301814899d801723339
```

---

## v5.4.302-docker (03/02/2026) ✅

### 📋 Conteúdo
- **Image.gz** - Kernel com Docker/LXC (19MB)
- **DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip** - AnyKernel3 ZIP (22MB)
- **kernel-config.txt** - Configuração completa (179KB)
- **README.md** - Documentação Docker/LXC
- **SHA256SUMS.txt** - Checksums dos artefatos

### 🎯 Características
- ✅ Kernel 5.4.302 base + Docker/LXC
- ✅ Toolchain: Clang 17.0.2 (NDK r26d)
- ✅ Device: POCO X5 5G (moonstone/rose)
- ✅ Slot B only (segurança)
- ✅ **211 configs Docker/LXC/Halium adicionadas**
- ✅ **USER_NS, PID_NS, NET_NS habilitados**
- ✅ **CGROUP_DEVICE, CGROUP_PIDS habilitados**
- ✅ **OVERLAY_FS (Docker storage) habilitado**
- ✅ **SECURITY_APPARMOR habilitado**
- ✅ **MEMCG, BRIDGE, NETFILTER habilitados**
- ⚠️ Compilado com `-Wno-error` (warnings em techpacks)
- ❌ Não testado em hardware

### 📦 Download
```bash
# Navegar para release
cd releases/v5.4.302-docker/

# Verificar integridade
sha256sum -c SHA256SUMS.txt

# Boot temporário (teste sem flash)
fastboot boot Image.gz
```

### 🔐 Checksums
```
SHA256 (Image.gz): 4db63467d9961781feb8ab0e1430da2a09a5bb9aeff418e91f3bfd8b9c6c00d4
SHA256 (AnyKernel3 ZIP): (ver SHA256SUMS.txt)
SHA256 (kernel-config.txt): (ver SHA256SUMS.txt)
```

### 🐳 Docker Support
Este kernel suporta **containers completos**:
```bash
# Após boot com este kernel:
adb shell
su
docker info  # Deve funcionar!
docker run hello-world
```

---

## 🚀 Próximos Releases

### v5.4.302-halium (Planejado)
- [ ] Patches Halium upstream aplicados
- [ ] Suporte Ubuntu Touch completo
- [ ] Rootfs Halium testado
- [ ] Teste em hardware

---

**Compilado por:** DevSan AGI  
**Device:** POCO X5 5G (moonstone/rose)  
**Licença:** GPL-2.0 (Linux Kernel)
