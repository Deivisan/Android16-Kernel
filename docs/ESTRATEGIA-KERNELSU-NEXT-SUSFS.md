# 🛡️ KernelSU Next + SUSFS - Estratégia de Integração

> Documentação técnica para integração de root solution avançada no kernel 5.4.302 POCO X5 5G  
> **Baseado em:** Estratégia de laboratório DevSan + Pesquisa KernelSU-Next/SUSFS

---

## 📋 OVERVIEW

### O que é KernelSU Next?

**KernelSU-Next** é uma solução de root baseada em kernel para Android, fork do KernelSU original com melhorias significativas:

| Característica | Descrição |
|----------------|-----------|
| **Arquitetura** | Kernel-based (módulo no kernel space) |
| **Suporte** | Android 4.4+ até 6.6+ (GKI e non-GKI) |
| **Módulos** | Sistema de módulos compatível com Magisk |
| **Perfis** | Controle granular de permissões por app |
| **Compatibilidade** | Kernel 5.4 = GKI 1.0 (driver built-in necessário) |

**GitHub:** https://github.com/KernelSU-Next/KernelSU-Next

### O que é SUSFS?

**SUSFS** (SuperUser FileSystem) é um conjunto de patches de kernel para ocultação avançada de root:

| Característica | Descrição |
|----------------|-----------|
| **Função** | Ocultar modificações do sistema de apps de detecção |
| **Nível** | Kernel-level (mais efetivo que userspace) |
| **Integração** | Add-on para KernelSU/KernelSU-Next |
| **Recursos** | Spoof de uname, hide mounts, syscall interception |

**GitLab:** https://gitlab.com/simonpunk/susfs4ksu

---

## 🎯 ARQUITETURA DE INTEGRAÇÃO

### Kernel 5.4.302 (POCO X5 5G) - Classificação

```
Device: POCO X5 5G (moonstone/rose)
SoC: Snapdragon 695 (SM6375)
Kernel: 5.4.302
Android: 13/14 (provável)
GKI Status: GKI 1.0 (5.4 = GKI 1.0)
```

**IMPORTANTE:** Kernel 5.4 é **GKI 1.0** - requer integração manual (driver built-in), não suporta LKM (Loadable Kernel Module).

### Fluxo de Integração

```
┌─────────────────────────────────────────────────────────────┐
│                    KERNEL SOURCE 5.4.302                     │
│                      (kernel-moonstone-devs)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
┌─────────┐   ┌─────────────┐   ┌──────────┐
│KernelSU │   │   SUSFS     │   │  Docker  │
│  Next   │   │   Patches   │   │   LXC    │
└────┬────┘   └──────┬──────┘   └────┬─────┘
     │               │               │
     └───────────────┼───────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│      KERNEL COMPILADO 5.4.302            │
│  + KernelSU Next (built-in)              │
│  + SUSFS (patches aplicados)             │
│  + Docker/LXC (configs habilitadas)      │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│           Image.gz (bootável)            │
│         AnyKernel3 ZIP (flashável)       │
└──────────────────────────────────────────┘
```

---

## 🔧 MÉTODOS DE INTEGRAÇÃO

### Método 1: Script Automático (Recomendado para teste)

```bash
# KernelSU-Next fornece script de setup
cd kernel-moonstone-devs
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/refs/heads/next/kernel/setup.sh" | bash -s next-susfs
```

**Problema com 5.4:** Script pode falhar em kernels non-GKI antigos.

### Método 2: Integração Manual (Recomendado para 5.4)

#### Passo 1: Clonar KernelSU-Next

```bash
cd ~/Projetos/android16-kernel/kernel-moonstone-devs

# Clonar KernelSU-Next na pasta correta
git clone https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU

# Ou usar submódulo (melhor para tracking)
git submodule add https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU
```

#### Passo 2: Configurar Defconfig

Editar `arch/arm64/configs/moonstone_defconfig`:

```bash
# Adicionar ao final do arquivo:
# KernelSU Support
CONFIG_KSU=y
CONFIG_KSU_DEBUG=n

# SUSFS Support (após aplicar patches)
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y
```

#### Passo 3: Modificar Makefile do Kernel

Editar `Makefile` na raiz do kernel:

```makefile
# Adicionar após as primeiras linhas de includes:
# KernelSU integration
obj-$(CONFIG_KSU) += KernelSU/kernel/
```

#### Passo 4: Aplicar Patches de Hook (Non-GKI)

Kernel 5.4 não-GKI requer patches manuais em arquivos core:

**Arquivos a modificar:**
1. `fs/exec.c` - Hook execve
2. `fs/open.c` - Hook openat
3. `fs/read_write.c` - Hook read/write
4. `fs/stat.c` - Hook stat
5. `drivers/input/input.c` - Hook input events

**Template de patch para `fs/exec.c`:**

```c
// No topo do arquivo, após includes:
#ifdef CONFIG_KSU
extern bool ksu_execveat_hook __read_mostly;
extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename,
                                        void *argv, void *envp, int *flags);
#endif

// Na função do_execveat_common (ou similar), adicionar:
#ifdef CONFIG_KSU
if (ksu_execveat_hook) {
    ksu_handle_execveat_sucompat(&fd, &filename, argv, envp, &flags);
}
#endif
```

#### Passo 5: Aplicar Patches SUSFS

```bash
# Clonar susfs4ksu
cd ~/Projetos/android16-kernel
git clone https://gitlab.com/simonpunk/susfs4ksu.git

# Copiar arquivos SUSFS para kernel
cd kernel-moonstone-devs
cp -r ../susfs4ksu/kernel_patches/fs/* fs/
cp -r ../susfs4ksu/kernel_patches/include/linux/* include/linux/

# Aplicar patch principal (verificar versão compatível)
patch -p1 < ../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android12-5.4.patch
```

**NOTA:** Patch específico para 5.4 pode não existir - requer adaptação manual.

---

## 🧪 ESTRATÉGIA DE LABORATÓRIO (Adaptada)

### Fase 1: Preparação (Isolamento)

```bash
# Criar workspace isolado
mkdir -p ~/Projetos/android16-kernel/lab-kernelsu
cd ~/Projetos/android16-kernel/lab-kernelsu

# Copiar kernel source atual (clean state)
cp -r ../kernel-moonstone-devs kernel-moonstone-ksu

# Inicializar git para tracking de mudanças
cd kernel-moonstone-ksu
git init
git add -A
git commit -m "Initial: Clean kernel 5.4.302"
```

### Fase 2: Integração Incremental

#### Teste 1: KernelSU-Next Only

```bash
# Aplicar apenas KernelSU
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/refs/heads/next/kernel/setup.sh" | bash -

# Configurar
echo "CONFIG_KSU=y" >> arch/arm64/configs/moonstone_defconfig

# Build de teste
make clean
make ARCH=arm64 moonstone_defconfig
make ARCH=arm64 -j16 Image.gz 2>&1 | tee build-ksu-only.log
```

#### Teste 2: KernelSU + SUSFS

```bash
# Aplicar SUSFS
# ... (comandos de patch)

# Build
make clean
make ARCH=arm64 moonstone_defconfig
make ARCH=arm64 -j16 Image.gz 2>&1 | tee build-ksu-susfs.log
```

#### Teste 3: Full (KSU + SUSFS + Docker)

```bash
# Merge com configs Docker existentes
cat ../configs/docker-lxc.config >> arch/arm64/configs/moonstone_defconfig

# Build final
make clean
make ARCH=arm64 moonstone_defconfig
make ARCH=arm64 -j16 Image.gz 2>&1 | tee build-full.log
```

### Fase 3: Validação

```bash
# Verificar se KSU está compilado
strings arch/arm64/boot/Image.gz | grep -i "kernelsu\|ksu"

# Verificar símbolos
cat System.map | grep -i "ksu_"

# Verificar tamanho (deve aumentar ~500KB-1MB)
ls -lh arch/arm64/boot/Image.gz
```

---

## ⚠️ DESAFIOS ESPERADOS (Kernel 5.4)

### 1. Syscall Hooks (Non-GKI)

**Problema:** Kernel 5.4 não-GKI não tem kprobes estáveis para todos os hooks.

**Solução:** Patches manuais nos arquivos core do kernel (fs/exec.c, etc.)

**Referência:** https://github.com/KernelSU-Next/KernelSU-Next/issues/1033

### 2. Compatibilidade SUSFS

**Problema:** SUSFS patches são projetados para GKI 2.0 (5.10+).

**Solução:** Adaptar patches manualmente ou usar versões antigas do SUSFS.

### 3. SELinux

**Problema:** KernelSU modifica políticas SELinux dinamicamente.

**Solução:** Verificar se `CONFIG_SECURITY_SELINUX=y` está habilitado.

### 4. Warnings como Erros

**Problema:** KernelSU pode gerar warnings em kernel 5.4.

**Solução:** Usar flags `-Wno-error` (já implementado no build atual).

---

## 📚 RECURSOS E REFERÊNCIAS

### Documentação Oficial

| Recurso | Link |
|---------|------|
| KernelSU-Next GitHub | https://github.com/KernelSU-Next/KernelSU-Next |
| KernelSU Docs | https://kernelsu.org/guide/how-to-integrate-for-non-gki.html |
| SUSFS GitLab | https://gitlab.com/simonpunk/susfs4ksu |
| SUSFS Module | https://github.com/sidex15/susfs4ksu-module |

### Tutoriais Relevantes

1. **Tutorial GKI + SUSFS:** https://droidbasement.com/db-blog/tutorial-kernelsu-next-with-susfs-integrated/
2. **Non-GKI Integration:** https://kernelsu.org/guide/how-to-integrate-for-non-gki.html
3. **Video Tutorial:** https://www.youtube.com/watch?v=_WkYyH1QaWk

### Issues Similares

- KernelSU-Next Issue #1033: Build failure em 5.4 device
- Solução: Usar manual hooks ao invés de kprobe

---

## 🚀 PLANO DE IMPLEMENTAÇÃO

### Sprint 1: KernelSU-Next Only
- [ ] Clonar KernelSU-Next
- [ ] Aplicar patches manuais de syscall
- [ ] Configurar defconfig
- [ ] Build de teste
- [ ] Flash e teste no device

### Sprint 2: Adicionar SUSFS
- [ ] Clonar susfs4ksu
- [ ] Adaptar patches para 5.4
- [ ] Aplicar ao kernel
- [ ] Build integrado
- [ ] Teste de hiding

### Sprint 3: Integração Completa
- [ ] Merge com Docker/LXC
- [ ] Build final
- [ ] Criar AnyKernel3 ZIP
- [ ] Testes extensivos
- [ ] Documentação

---

## 📝 CHECKLIST DE CONFIGS

### Configs KernelSU Obrigatórias

```bash
# Verificar/editar no defconfig:
CONFIG_KSU=y                    # Habilitar KernelSU
CONFIG_KSU_DEBUG=n              # Debug desligado
CONFIG_OVERLAY_FS=y             # Necessário para módulos
CONFIG_TMPFS_POSIX_ACL=y        # ACL para tmpfs
```

### Configs SUSFS (após patch)

```bash
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y
CONFIG_KSU_SUSFS_SUS_MOUNT_MNT_ID=y
```

---

## 🎓 NOTAS TÉCNICAS

### Diferença GKI 1.0 vs 2.0

| Aspecto | GKI 1.0 (5.4) | GKI 2.0 (5.10+) |
|---------|---------------|-----------------|
| LKM Support | ❌ Não | ✅ Sim |
| KernelSU Mode | Built-in apenas | Built-in ou LKM |
| SUSFS | Patches manuais | Patches automáticos |
| Complexidade | Alta | Média |

### Por que 5.4 é mais difícil?

1. **Sem kprobes confiáveis** → requer hooks manuais
2. **API antiga** → algumas funções mudaram de assinatura
3. **Patches não mantidos** → SUSFS foca em versões mais novas
4. **Drivers proprietários** → Qualcomm techpacks podem conflitar

---

**📝 Criado em:** 2026-02-04  
**🎯 Kernel Target:** 5.4.302 (moonstone)  
**🛠️ Base:** Estratégia de laboratório DevSan + Pesquisa KernelSU-Next  
**👤 Autor:** DevSan AGI
