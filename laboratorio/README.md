# 🧪 LABORATÓRIO DE BUILD - KERNEL MOONSTONE (POCO X5 5G)

> Ambiente profissional e imune a erros para compilação do kernel Android
> 
> **Device:** POCO X5 5G (moonstone)  
> **SoC:** Snapdragon 695 (SM6375/Blair)  
> **Kernel:** 5.4.302-msm-android (QGKI)  
> **Author:** DevSan AGI para Deivison Santana

---

## 📁 Estrutura do Laboratório

```
laboratorio/
├── toolchain/              # Google Clang/LLVM (r416183b)
│   └── google-clang/
│       └── bin/clang       # Android Clang 14.0.6
├── build-tools/            # Android build-tools
├── kernel/                 # Link para kernel-moonstone-devs
├── out/                    # Output do build
│   ├── Image.gz            # Kernel compilado
│   └── config-*            # Config usada
├── logs/                   # Logs de build
├── build-moonstone-bulletproof.sh  # Script principal
└── README.md               # Esta documentação
```

---

## 🔧 Toolchain Correta

### ❌ ERRO CRÍTICO CORRIGIDO
**NÃO usar:** Clang do sistema Arch Linux (`/usr/bin/clang`)

**USAR:** Google Clang da Android toolchain

| Componente | Versão | Path |
|------------|--------|------|
| Clang | r416183b (14.0.6) | `toolchain/google-clang/bin/clang` |
| LLVM AR | 14.0.6 | `toolchain/google-clang/bin/llvm-ar` |
| LLVM NM | 14.0.6 | `toolchain/google-clang/bin/llvm-nm` |
| LD.LLD | 14.0.6 | `toolchain/google-clang/bin/ld.lld` |

### Download da Toolchain

```bash
# URL oficial Google
https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r416183b.tar.gz
```

---

## 🚀 Como Usar

### 1. Primeira vez (Setup)

```bash
cd /home/deivi/Projetos/Android16-Kernel/laboratorio
chmod +x build-moonstone-bulletproof.sh
./build-moonstone-bulletproof.sh
```

O script vai:
1. ✅ Criar estrutura de diretórios
2. ✅ Baixar Google Clang automaticamente
3. ✅ Verificar kernel source
4. ✅ Compilar com parâmetros corretos

### 2. Builds subsequentes

```bash
./build-moonstone-bulletproof.sh
```

---

## ⚙️ Parâmetros de Build

### Variáveis de Ambiente (Automáticas)

```bash
# Toolchain
export LLVM=1                    # Usar LLVM completo
export LLVM_IAS=1                # LLVM Integrated Assembler
export CC=clang                  # Google Clang
export LD=ld.lld                 # LLVM Linker

# Arquitetura
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu

# Kernel configs
export KCFLAGS="-D__ANDROID_COMMON_KERNEL__"
export LOCALVERSION="-qgki"
```

### Defconfig Usada

```
moonstone_defconfig
```

Local: `arch/arm64/configs/moonstone_defconfig`

---

## 🛡️ Imunidade a Erros

### Problemas Resolvidos

| Problema | Solução |
|----------|---------|
| Erros de formato (-Werror=format) | Correções aplicadas nos techpacks |
| Clang incorreto | Uso do Google Clang r416183b |
| PATH errado | Configuração absoluta no script |
| Diretório errado | `cd` explícito e verificações |
| Toolchain faltando | Download automático |

### Verificações Automáticas

- ✅ Toolchain existe?
- ✅ Kernel source existe?
- ✅ defconfig existe?
- ✅ clang funciona?
- ✅ .config gerado?
- ✅ Image.gz gerado?

---

## 📊 Tempo de Build

| Hardware | Jobs | Tempo Estimado |
|----------|------|----------------|
| Ryzen 7 5700G (16 threads) | -j16 | 2-4 horas |
| SSD NVMe | - | Leitura/escrita rápida |
| 14GB RAM | - | Suficiente |

---

## 🎁 Output

### Arquivos Gerados

```
out/
├── Image.gz              # Kernel bootável (15-25MB)
└── config-YYYYMMDD-HHMMSS # Config usada
```

### Verificação

```bash
# Verificar kernel
file out/Image.gz
strings out/Image.gz | grep "Linux version"
```

---

## 🔍 Troubleshooting

### Erro: "clang não encontrado"

**Causa:** Toolchain não baixou  
**Solução:** Script baixa automaticamente, verificar internet

### Erro: "moonstone_defconfig não encontrado"

**Causa:** Kernel source no lugar errado  
**Solução:** Verificar `kernel-moonstone-devs/`

### Erro: Build falha após limpeza

**Causa:** `make mrproper` apagou tudo  
**Solução:** Script usa `make clean` apenas

---

## 📝 Notas Técnicas

### Kernel Info

```
Version: 5.4.302
Patchlevel: 302
Extraversion: -qgki
Defconfig: moonstone_defconfig
Arch: arm64
Target: msm.lahaina
```

### Configs Importantes

| Config | Status | Descrição |
|--------|--------|-----------|
| CONFIG_ARCH_BLAIR | ✅ | SoC SM6375 |
| CONFIG_ARCH_QCOM | ✅ | Qualcomm support |
| CONFIG_SCHED_WALT | ✅ | WALT scheduler |
| CONFIG_BUILD_ARM64_DT_OVERLAY | ✅ | Device Tree Overlay |

---

## 🦞 DevSan AGI - Checklist de Qualidade

- [x] Toolchain correta (Google Clang)
- [x] Script bulletproof com verificações
- [x] Erros de formato corrigidos
- [x] Diretórios absolutos
- [x] Logging completo
- [x] Tratamento de erros robusto
- [x] Ambiente isolado (laboratorio/)

---

**Criado em:** 2025-02-02  
**Versão:** 1.0-BULLETPROOF  
**Status:** ✅ PRONTO PARA COMPILAR
