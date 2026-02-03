# 📦 DevSan AGI Kernel - Releases

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
