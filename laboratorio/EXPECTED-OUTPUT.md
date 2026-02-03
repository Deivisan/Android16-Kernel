# 📦 Expected Output - Kernel Moonstone Build

> O que esperar do build do kernel POCO X5 5G (moonstone)
> DevSan AGI - v1.0.0

---

## 🎯 Build Result Esperado

### Arquivos Gerados

```
out/
├── Image.gz                    # ✓ KERNEL PRINCIPAL (15-25MB)
├── vmlinux                    # ✓ ELF não-comprimido (50-100MB)
├── System.map                 # ✓ Símbolos do kernel (10-20MB)
└── dts/                       # ✓ Device Tree Blobs
    ├── qcom/
    │   └── *.dtb             # Device trees Qualcomm
    └── xiaomi/
        └── moonstone*.dtb    # Device trees Xiaomi
```

### Image.gz - Arquivo Principal

**Tamanho esperado:** 15-25 MB (comprimido)
**Tamanho descomprimido:** 50-100 MB
**SHA256:** Variável (calculado no build)

**Comando de verificação:**
```bash
ls -lh out/Image.gz
# Output esperado:
# -rwxr-xr-x 1 deivi deivi  18M fev  2 20:00 Image.gz

file out/Image.gz
# Output esperado:
# Image.gz: data (compressed kernel)

sha256sum out/Image.gz
# Output esperado:
# a1b2c3d4e5f67890abc123def4567890abcdef123456  out/Image.gz
```

---

## 📊 Métricas de Build

### Tempo de Compilação

| Hardware | Jobs | 1° Build | Rebuild (ccache) |
|----------|-------|-----------|------------------|
| Ryzen 7 5700G (16T) | 16 | 2-3h | 30-45m |
| Ryzen 7 5700G (16T) | 8  | 3-4h | 45-60m |
| Ryzen 7 5700G (16T) | 4  | 4-5h | 60-90m |

**Nota:** Tempos aproximados. Variam com configurações específicas.

### Espaço em Disco

**Necessário:**
- Build completo: ~20-30 GB
- ccache: 20-50 GB (primeiro build)
- Logs: < 100 MB

**Recomendado:** 50+ GB livres

### Uso de RAM

**Peak durante build:**
- 8 jobs: 6-8 GB
- 16 jobs: 10-12 GB

**Recomendado:** 8+ GB de RAM disponível

---

## 🔍 Validação do Kernel

### Verificar Tamanho

```bash
# Deve ser 15-25MB
SIZE=$(stat -c%s out/Image.gz)
SIZE_MB=$((SIZE / 1024 / 1024))

if [ $SIZE_MB -ge 15 ] && [ $SIZE_MB -le 25 ]; then
    echo "✅ Tamanho OK: ${SIZE_MB}MB"
else
    echo "❌ Tamanho incorreto: ${SIZE_MB}MB"
fi
```

### Extrair Versão

```bash
# Extrair string de versão
strings out/Image.gz | grep "Linux version" | head -1

# Saída esperada:
# Linux version 5.4.302-gabcdef123456 (android11-5.4-qgki) (gcc version 12.0.8 (Android) ) #1 SMP PREEMPT Thu Feb  2 20:00:00 BRT 2026

# Componentes:
# - 5.4.302               ← Versão do kernel
# - gabcdef123456         ← Commit hash
# - android11-5.4-qgki     ← Branch/variant
# - gcc version 12.0.8     ← Toolchain
```

### Verificar Arquitetura

```bash
file out/Image.gz
# Saída esperada:
# Image.gz: data (compressed kernel)

# Se decomprimido:
gunzip -c out/Image.gz > out/Image
file out/Image
# Saída esperada:
# Image: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV)...
```

### Verificar Assinatura

```bash
# Se assinado (kernel oficial)
dumpimage -l out/Image.gz | grep "Signature"
# Saída (se assinado):
# Signature: Valid (SHA256: abc123...)

# Se não assinado (kernel custom):
# Signature: None / Not signed
```

---

## 🧪 Boot no Device

### Verificar Carregamento

```bash
# Conectar em ADB
adb shell

# Verificar versão
uname -a
# Saída esperada:
# Linux localhost 5.4.302-gabcdef123456 #1 SMP PREEMPT <timestamp> aarch64

# Verificar /proc/version
cat /proc/version
# Saída esperada:
# Linux version 5.4.302-gabcdef123456 (android11-5.4-qgki)...

# Verificar dmesg
dmesg | head -20
# Saída esperada: Mensagens de boot normais, sem panics
```

### Verificar Funcionalidades

```bash
# Verificar namespaces (LXC/Halium)
cat /proc/self/ns/user
# Saída esperada:
# user:[4026531837]

# Verificar cgroups
cat /proc/self/cgroup
# Saída esperada:
# 0::/user.slice/user-1000.slice/session-1.scope
# OU (cgroup v2):
# 0::/user.slice

# Verificar System V IPC
ls /proc/sysvipc/
# Saída esperada:
# msg  sem  shm  (todos existem)
```

---

## 🎯 Critérios de Build Bem-Sucedido

Build considerado **SUCESSO** quando:

✅ **Arquivos presentes:**
- [ ] `out/Image.gz` existe (15-25MB)
- [ ] `out/vmlinux` existe (50-100MB)
- [ ] `out/System.map` existe (10-20MB)

✅ **Tamanho correto:**
- [ ] Image.gz: 15-25 MB
- [ ] vmlinux: 50-100 MB

✅ **Formato válido:**
- [ ] Image.gz: "data (compressed kernel)"
- [ ] vmlinux: "ELF 64-bit LSB executable, ARM aarch64"

✅ **Versão esperada:**
- [ ] Kernel: 5.4.302+
- [ ] Toolchain: Clang 12.0.8
- [ ] Branch: android11-5.4-qgki

✅ **Configs habilitadas:**
- [ ] CONFIG_USER_NS=y
- [ ] CONFIG_CGROUP_DEVICE=y
- [ ] CONFIG_SYSVIPC=y
- [ ] CONFIG_POSIX_MQUEUE=y
- [ ] CONFIG_IKCONFIG_PROC=y

✅ **Boot funcional:**
- [ ] Device boota sem kernel panic
- [ ] `uname -a` mostra versão correta
- [ ] `dmesg` sem erros críticos
- [ ] Systema funcional (WiFi, audio, touchscreen)

✅ **LXC/Halium compatível:**
- [ ] Namespaces de usuário funcionando
- [ ] Cgroups v2 funcionando
- [ ] System V IPC disponível

---

## 🚫 Sinais de Build com Problemas

Build considerado **PROBLEMÁTICO** quando:

⚠️ **Erros durante build:**
- [ ] Erros de compilação (fatal error:)
- [ ] Erros de link (undefined reference)
- [ ] Warnings tratados como erros (-Werror)

⚠️ **Arquivos incompletos:**
- [ ] Image.gz faltando
- [ ] Tamanho incorreto (< 10MB ou > 30MB)
- [ ] Formato inválido

⚠️ **Kernel não funcional:**
- [ ] Bootloop (reinicia infinitamente)
- [ ] Kernel panic no boot
- [ ] Sistema não carrega
- [ ] Peripherals não funcionam

⚠️ **Features faltando:**
- [ ] Namespaces não funcionando
- [ ] Cgroups não funcionando
- [ ] IPC não disponível
- [ ] Halium não inicializa

---

## 📝 Checklist Pré-Teste no Device

Antes de flashar no POCO X5 5G, verificar:

- [ ] Build completou sem erros
- [ ] Image.gz existe e tem tamanho correto
- [ ] SHA256 calculado e registrado
- [ ] Versão do kernel verificada (strings | grep)
- [ ] Formato do arquivo validado (file)
- [ ] Configs críticas habilitadas
- [ ] Device conectado em fastboot
- [ ] Backup do kernel atual feito
- [ ] Slot B disponível para testes
- [ ] Backup de dados do device feito

**Se TODOS checkmarks, pronto para teste!**

---

## 🚀 Checklist de Teste no Device

Após flashar kernel no POCO X5 5G, verificar:

- [ ] Device boota
- [ ] Sem bootloops
- [ ] `uname -a` mostra versão correta
- [ ] `dmesg` sem panics
- [ ] WiFi funciona
- [ ] Audio funciona
- [ ] Touchscreen funciona
- [ ] Câmera funciona
- [ ] Bluetooth funciona
- [ ] USB funciona
- [ ] GPS funciona
- [ ] Senha/desbloqueio funciona
- [ ] ADB funciona
- [ ] Fastboot funciona
- [ ] Bateria reporta corretamente
- [ ] Temperaturas normais
- [ ] Performance aceitável

**Se TODOS checkmarks, build bem-sucedido!**

---

## 📊 Logs Esperados

### Build Log

```
[2026-02-02 20:00:00] 🦞 DevSan Kernel Build System v1.0.0
[2026-02-02 20:00:01] 📁 Kernel: /kernel
[2026-02-02 20:00:02] 📤 Output: /output
[2026-02-02 20:00:03] 🔧 Configurando ambiente de build...
[2026-02-02 20:00:04] 📝 Carregando moonstone_defconfig...
[2026-02-02 20:00:05] ✅ Verificando configs críticas...
[2026-02-02 20:00:06]    ✓ CONFIG_USER_NS = OK
[2026-02-02 20:00:07]    ✓ CONFIG_CGROUP_DEVICE = OK
[2026-02-02 20:00:08]    ✓ CONFIG_SYSVIPC = OK
[2026-02-02 20:00:09]    ✓ CONFIG_POSIX_MQUEUE = OK
[2026-02-02 20:00:10]    ✓ CONFIG_IKCONFIG_PROC = OK
[2026-02-02 20:00:11] ⚡ Compilando com 16 jobs...
[...]
[2026-02-02 23:45:30] ✅ Build concluído! Tamanho: 18MB
[2026-02-02 23:45:31] 📦 Artefatos copiados para /output
[2026-02-02 23:45:32] ✅ Compilação concluída com sucesso!
[2026-02-02 23:45:33] ✅ Tempo: 225 minutos e 30 segundos
```

### Summary Log

```
╔══════════════════════════════════════════════════════════╗
║  🦞 DevSan AGI - Build Report - Moonstone Kernel            ║
╚════════════════════════════════════════════════════════╝

📅 Data: 2026-02-02 23:45:30

🎯 Target:
   Device: POCO X5 5G (moonstone/rose)
   SoC: Snapdragon 695 (SM6375)
   Arch: ARM64 (armv8.2-a)
   Kernel: MSM 5.4 + Android Patches
   Toolchain: Clang r416183b (Android 12.0.8)

🔧 Build Configurações:
   Jobs: 16
   Arch: arm64
   Subarch: arm64
   Build Type: qgki

📊 Artefatos:
   ✓ Image.gz: 18MB (18874368 bytes)
   ✓ vmlinux: 89456721 bytes
   ✓ System.map: 12345678 bytes

📋 Logs:
   Build Log: /home/deivi/Projetos/Android16-Kernel/laboratorio/logs/build-20260202-200030.log
   Summary Log: /home/deivi/Projetos/Android16-Kernel/laboratorio/logs/summary-20260202-200030.txt

✅ Status: BUILD COMPLETO!

📦 Localização dos artefatos:
   /home/deivi/Projetos/Android16-Kernel/laboratorio/out/

🚀 Próximos passos:
   1. Conectar device em fastboot
   2. Testar: fastboot boot /path/to/Image.gz
   3. Se funcionar: flashar em slot B
   4. Reboot e verificar dmesg

╚════════════════════════════════════════════════════════╝
```

---

## 🔧 Troubleshooting Output

### Image.gz muito pequeno (< 10MB)

**Causa provável:**
- Build incompleto
- Erros silenciosos
- Config faltando subsistemas

**Solução:**
```bash
# Verificar log de build completo
cat laboratorio/logs/build-*.log | tail -100

# Verificar se Image.gz é gzip válido
gunzip -t out/Image.gz
```

### Image.gz muito grande (> 30MB)

**Causa provável:**
- Debug symbols incluídos
- Config muito grande
- Módulos compilados como built-in

**Solução:**
```bash
# Verificar .config
grep "CONFIG_DEBUG_INFO" .config
# Se=y, kernel terá debug symbols

# Verificar módulos
grep "^CONFIG.*=y" .config | wc -l
# Se > 1000, muitos módulos built-in
```

### vmlinux não encontrado

**Causa:**
- Build falhou antes de gerar vmlinux
- Makefile modificado incorretamente

**Solução:**
```bash
# Limpar e recompilar
docker-compose exec kernel-build bash -c "
  cd /kernel && make clean && make vmlinux
"
```

---

**🦞 DevSan AGI - v1.0.0 - 2026**  
**Target Device:** POCO X5 5G (moonstone/rose)  
**Expected Output Size:** 15-25MB (Image.gz compressed)  
**Build Time (Ryzen 7 5700G):** 2-3h (1st), 30-45m (rebuild)  
**Author:** Deivison Santana (@deivisan)
