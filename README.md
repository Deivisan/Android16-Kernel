# 🐧 Kernel Customizado para POCO X5 5G (moonstone/rose)

**Versão Atual:** 5.4.191 (Build v12 - SUCESSO ✅)  
**Data:** 02/02/2026  
**Status:** Compilado e empacotado - Aguardando testes no dispositivo

---

## 📋 Visão Geral do Projeto

Este é um kernel customizado baseado no código-fonte oficial da Xiaomi para o POCO X5 5G, com modificações para suportar:

- 🐋 **Docker & LXC** - Containers completos no Android
- 🔧 **Kali NetHunter** - Ferramentas de segurança e testes
- 📦 **OverlayFS** - Sistema de arquivos overlay para Docker
- 🌐 **Namespaces & Cgroups** - Isolamento completo de recursos

### **Objetivo do Projeto**

Criar e manter uma base de kernel própria para o dispositivo, permitindo:
1. Atualizações incrementais de versão (5.4 → 5.10 → 5.15 → 6.6)
2. Aplicação de patches de segurança e features
3. Personalização e otimizações específicas
4. Aprendizado sobre desenvolvimento de kernel Android

---

## 🎯 Status Atual

### **✅ Conquistas:**

**Build v12 (02/02/2026) - SUCESSO!**
- ✅ Compilação bem-sucedida após 11 tentativas
- ✅ Kernel Image.gz criado (15 MB comprimido, 31 MB descomprimido)
- ✅ Package AnyKernel3 flashável criado (18 MB)
- ✅ Todas as features Docker/LXC habilitadas
- ✅ Compatibilidade NetHunter implementada

**Problemas Resolvidos:**
- ✅ Incompatibilidade GCC 15.1.0 (muito novo)
- ✅ Incompatibilidade Clang 21.1.6 (muito novo)
- ✅ Script oculto da Xiaomi bloqueando warnings (`gcc-wrapper.py`)
- ✅ Conflito de tipos em `bootinfo.h` (unsigned int → int)
- ✅ Warnings de format string em vários arquivos

### **⏳ Próximos Passos:**

1. **Testar kernel no dispositivo** (boot temporário via fastboot)
2. **Verificar funcionalidade Docker** após boot bem-sucedido
3. **Testar estabilidade** (crashes, battery drain, etc.)
4. **Coletar logs e métricas** de performance
5. **Planejar atualização para 5.10** (após estabilizar 5.4.191)

---

## 📦 Arquivos Importantes

### **Deliverables (Prontos para Uso):**

```
📦 kernel-poco-x5-5g-5.4.191-docker-nethunter.zip
   └─ Flashável via TWRP/OrangeFox
   └─ MD5: ba4fbe9f397fb80e7c65b87849c3283b
   └─ Tamanho: 18 MB

💾 compilacoes-bem-sucedidas/
   ├─ Image-v12-20260202-135708.gz (Kernel backup)
   ├─ config-v12-20260202-135708 (Configuração usada)
   └─ MD5: 5878d68818b3295aeca7d61db9f14945
```

### **Código-Fonte:**

```
🔧 kernel-source/ (3.4 GB - código modificado)
   ├─ .config (configuração final que compilou)
   ├─ arch/arm64/boot/Image.gz (kernel compilado)
   ├─ scripts/gcc-wrapper.py (MODIFICADO - crítico!)
   ├─ arch/arm64/include/asm/bootinfo.h (MODIFICADO - crítico!)
   └─ [outros arquivos modificados para corrigir warnings]

⚙️ anykernel3-moonstone/ (Package source)
   ├─ anykernel.sh (configuração do instalador)
   ├─ Image.gz (kernel)
   └─ META-INF/ (scripts de instalação recovery)
```

### **Scripts de Build:**

```
🔨 compilar-kernel.sh (script principal de compilação)
📊 build-scripts/ (scripts auxiliares)
   ├─ check-configs.sh (verificar configs Docker/LXC)
   └─ [outros scripts de verificação]
```

### **Documentação:**

```
📚 docs/
   ├─ INSTRUCOES-FLASH.md (como instalar - LEIA ANTES!)
   ├─ RELATORIO-COMPILACAO.md (detalhes técnicos do build)
   ├─ HISTORICO-COMPLETO.md (jornada completa do projeto)
   └─ CONFIGURACOES-DOCKER.md (configs habilitadas)

📝 logs/
   └─ build-v12-sucesso.log (log da compilação bem-sucedida)
```

---

## 🚀 Como Usar Este Repositório

### **1. Clonar em Outro PC:**

```bash
# Clone o repositório
git clone <seu-repo-url> android16-kernel
cd android16-kernel

# Baixar Android NDK r26d (necessário para compilar)
wget https://dl.google.com/android/repository/android-ndk-r26d-linux.tar.bz2
tar xf android-ndk-r26d-linux.tar.bz2 -C ~/Downloads/

# Verificar que tudo está ok
ls -lh kernel-poco-x5-5g-5.4.191-docker-nethunter.zip
ls -lh compilacoes-bem-sucedidas/
```

### **2. Recompilar o Kernel:**

```bash
# Usar o script de build (já configurado)
./compilar-kernel.sh

# Ou manualmente:
cd kernel-source
export NDK_PATH=~/Downloads/android-ndk-r26d
export NDK_BIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin
export PATH=$NDK_BIN:$PATH
export ARCH=arm64
export SUBARCH=arm64
export CC=$NDK_BIN/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-

make WERROR=0 -j$(nproc) Image.gz
```

### **3. Testar no Dispositivo (SEGURO):**

```bash
# SEMPRE teste primeiro sem modificar o boot!
cd ~/Projetos/android16-kernel

# Extrair kernel do ZIP
unzip kernel-poco-x5-5g-5.4.191-docker-nethunter.zip Image.gz

# Boot temporário (NÃO modifica nada permanentemente)
adb reboot bootloader
fastboot boot Image.gz

# Se bootar com sucesso, verificar Docker:
adb shell uname -a
adb shell dmesg | grep -i docker
```

### **4. Instalação Permanente (APÓS TESTE!):**

⚠️ **LEIA `docs/INSTRUCOES-FLASH.md` COMPLETAMENTE ANTES!**

```bash
# 1. BACKUP primeiro!
adb shell dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img
adb pull /sdcard/boot_backup.img ~/backups/

# 2. Transferir ZIP
adb push kernel-poco-x5-5g-5.4.191-docker-nethunter.zip /sdcard/

# 3. Flash via recovery
adb reboot recovery
# No TWRP: Install > Selecionar ZIP > Flash
```

---

## 🔧 Informações Técnicas

### **Kernel Base:**

- **Versão:** Linux 5.4.191
- **Fonte:** Xiaomi official kernel source (POCO X5 5G)
- **SoC:** Qualcomm Snapdragon 695 5G (SM6375)
- **Arquitetura:** ARM64 (aarch64)
- **Defconfig Base:** `vendor/moonstone-qgki_defconfig`

### **Compilador Usado:**

- **Toolchain:** Android NDK r26d
- **Compilador:** Clang 17.0.2
- **Target:** aarch64-linux-gnu
- **Flags:** `-O2 -pipe -j16 WERROR=0`

### **Modificações Críticas (NÃO REVERTER!):**

```
1. scripts/gcc-wrapper.py
   └─ Desabilitado bloqueio de warnings da Xiaomi
   └─ Sem isso, build falha mesmo com WERROR=0

2. arch/arm64/include/asm/bootinfo.h
   └─ Corrigido tipo: unsigned int → int
   └─ Fix conflito get_powerup_reason() / set_powerup_reason()

3. fs/proc/meminfo.c
   └─ Adicionados casts para format strings

4. include/trace/events/psi.h
   └─ Removida flag '#' inválida de format string
```

### **Configurações Docker/LXC Habilitadas:**

Ver lista completa em: `docs/CONFIGURACOES-DOCKER.md`

---

## 📊 Histórico de Builds

| Build | Data | Compilador | Resultado | Problema |
|-------|------|------------|-----------|----------|
| v1-v6 | 02/02 | GCC 15.1.0 | ❌ | Muito novo, incompatível |
| v7-v9 | 02/02 | Clang 21.1.6 | ❌ | Muito novo, warnings |
| v10-v11 | 02/02 | NDK Clang 17 | ❌ | gcc-wrapper.py bloqueando |
| **v12** | **02/02** | **NDK Clang 17** | **✅** | **SUCESSO!** |

**Tempo total:** ~11 horas (3 sessões)  
**Taxa de sucesso:** 8.3% (1/12 builds)

---

## 🎓 Roadmap de Atualizações

### **Fase 1: Estabilização (5.4.191) - ATUAL**

- [x] Compilar kernel base com Docker/LXC
- [x] Criar package flashável
- [x] Documentar processo
- [ ] Testar em dispositivo real
- [ ] Verificar Docker funcionando
- [ ] Medir impacto em bateria/performance

### **Fase 2: Melhorias (5.4.x)**

- [ ] Aplicar patches de segurança mais recentes
- [ ] Otimizações de performance
- [ ] Reduzir consumo de bateria

### **Fase 3: Atualização LTS (5.10.x)**

- [ ] Estudar diferenças entre 5.4 → 5.10
- [ ] Portar modificações
- [ ] Testar compatibilidade drivers

### **Fase 4: Atualização LTS (5.15.x)**

- [ ] Estudar 5.10 → 5.15
- [ ] Validar features Android 13/14

### **Fase 5: Atualização LTS (6.6.x)**

- [ ] Maior salto de versão
- [ ] Features Android 15+

---

## ⚠️ Avisos Importantes

### **ANTES DE USAR:**

1. ❌ **Kernel NÃO testado em hardware real ainda**
2. 💾 **SEMPRE faça backup do boot.img original**
3. 🔧 **Teste com `fastboot boot` primeiro** (temporário, seguro)
4. 📱 **Pode causar bootloop** (recuperável com backup)

---

## 📚 Documentação Completa

Ver pasta `docs/` para guias detalhados.

---

## 📝 Changelog

### **v12 (02/02/2026) - Primeira Compilação Bem-Sucedida**

**Adicionado:**
- Suporte completo Docker & LXC
- Compatibilidade Kali NetHunter
- Package AnyKernel3 flashável

**Corrigido:**
- Script gcc-wrapper.py da Xiaomi
- Conflito de tipos em bootinfo.h
- Warnings de format string

---

**Última atualização:** 02/02/2026  
**Status:** ✅ Compilado e empacotado - Pronto para testes  

**🚀 Boa sorte com os testes! Leia a documentação com atenção!**
