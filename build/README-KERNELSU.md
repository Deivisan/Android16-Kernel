# 🛡️ KernelSU Next + SUSFS - Guia Rápido

> Adicione root solution com hiding avançado ao kernel 5.4.302 POCO X5 5G

---

## 🚀 Quick Start (Resumido)

### 1. Preparar Kernel

```bash
cd ~/Projetos/android16-kernel/build

# Setup KernelSU-Next (integração básica)
./setup-kernelsu-next.sh --manual

# Aplicar hooks de syscall (necessário para 5.4)
./apply-ksu-hooks.sh

# Opcional: Adicionar SUSFS (root hiding)
./setup-susfs.sh
```

### 2. Compilar

```bash
# Build completo
./build-kernelsu.sh
```

### 3. Testar

```bash
# Boot temporário
adb reboot bootloader
fastboot boot out/Image-kernelsu-*.gz

# Verificar
cd ../kernel-moonstone-devs
adb shell uname -a
```

---

## 📚 Documentação Completa

- **[ESTRATEGIA-KERNELSU-NEXT-SUSFS.md](ESTRATEGIA-KERNELSU-NEXT-SUSFS.md)** - Documentação técnica completa
- **[../../deprecated/laboratorio/README.md](../../deprecated/laboratorio/README.md)** - Estratégia de laboratório original

---

## 🔧 Scripts Disponíveis

| Script | Função | Quando Usar |
|--------|--------|-------------|
| `setup-kernelsu-next.sh` | Integra KernelSU-Next ao kernel | Primeira vez ou atualização |
| `apply-ksu-hooks.sh` | Aplica hooks manuais de syscall | Após setup-kernelsu-next |
| `setup-susfs.sh` | Adiciona SUSFS (root hiding) | Opcional, para hiding avançado |
| `build-kernelsu.sh` | Compila kernel completo | Final do processo |

### Opções dos Scripts

```bash
# Setup com opções
./setup-kernelsu-next.sh --manual    # Método manual (recomendado)
./setup-kernelsu-next.sh --auto      # Tentar automático
./setup-kernelsu-next.sh --clean     # Remover integração

# Build com variáveis
NDK_PATH=/caminho/ndk ./build-kernelsu.sh
JOBS=8 ./build-kernelsu.sh           # Limitar threads
```

---

## ⚠️ Considerações Importantes (Kernel 5.4)

### Non-GKI = Hooks Manuais Necessários

Kernel 5.4 é **GKI 1.0** (não-GKI completo). Isso significa:

- ❌ Sem suporte a LKM (Loadable Kernel Module)
- ❌ Kprobes não são confiáveis
- ✅ Requer **hooks manuais** nos arquivos core

O script `apply-ksu-hooks.sh` faz isso automaticamente modificando:
- `fs/exec.c` - Detecção de su
- `fs/open.c` - Interceptação de open
- `fs/read_write.c` - Interceptação de read/write
- `drivers/input/input.c` - Eventos de input

### Possíveis Problemas

| Problema | Solução |
|----------|---------|
| Build falha com "No hooks defined" | Executar `apply-ksu-hooks.sh` |
| Warnings tratados como erros | Já corrigido com `-Wno-error` |
| Patch SUSFS falha | Aplicar manualmente (kernel 5.4 é antigo) |

---

## 🎯 Estratégia de Laboratório Recomendada

### Fase 1: KernelSU Only (Teste Básico)

```bash
./setup-kernelsu-next.sh --manual
./apply-ksu-hooks.sh
./build-kernelsu.sh

# Testar no device
# Instalar KernelSU Manager APK
# Verificar se root funciona
```

### Fase 2: Adicionar SUSFS (Se Fase 1 OK)

```bash
./setup-susfs.sh
./build-kernelsu.sh

# Testar hiding com apps de detecção
# Instalar módulo SUSFS via KernelSU Manager
```

### Fase 3: Full Integration (Se Fase 2 OK)

```bash
# Adicionar Docker/LXC configs também
# Criar release completa
```

---

## 📦 Downloads Necessários

### KernelSU-Next Manager
```bash
# Baixar APK mais recente
https://github.com/KernelSU-Next/KernelSU-Next/releases
```

### SUSFS Module (Userspace)
```bash
# Instalar via KernelSU Manager depois de flashar kernel
https://github.com/sidex15/susfs4ksu-module/releases
```

---

## 🔍 Verificação Pós-Build

### Verificar KernelSU no Kernel

```bash
# Strings no kernel
strings arch/arm64/boot/Image.gz | grep -i "kernelsu\|ksu"

# Símbolos
cat System.map | grep "ksu_" | head -20

# Tamanho (deve aumentar ~500KB-1MB)
ls -lh arch/arm64/boot/Image.gz
```

### Verificar no Device

```bash
# Kernel version
adb shell uname -a

# KernelSU daemon
adb shell su -c "ksud --version"

# Verificar módulos
adb shell ls -la /data/adb/modules/
```

---

## 🐛 Troubleshooting

### "KernelSU: No hooks were defined"

```bash
# Solução: Aplicar hooks manuais
./apply-ksu-hooks.sh
```

### "CONFIG_KSU not found"

```bash
# Verificar se defconfig foi modificado
grep CONFIG_KSU arch/arm64/configs/moonstone_defconfig

# Se não estiver, adicionar manualmente:
echo "CONFIG_KSU=y" >> arch/arm64/configs/moonstone_defconfig
```

### Bootloop após flash

```bash
# Voltar para slot A (kernel original)
adb reboot bootloader
fastboot set_active a
fastboot reboot
```

---

## 📖 Referências

- [KernelSU-Next GitHub](https://github.com/KernelSU-Next/KernelSU-Next)
- [KernelSU Docs (Non-GKI)](https://kernelsu.org/guide/how-to-integrate-for-non-gki.html)
- [SUSFS GitLab](https://gitlab.com/simonpunk/susfs4ksu)
- [Tutorial GKI + SUSFS](https://droidbasement.com/db-blog/tutorial-kernelsu-next-with-susfs-integrated/)

---

**⚠️ AVISO:** Root modifica o sistema e pode comprometer segurança. Use por sua conta e risco!
