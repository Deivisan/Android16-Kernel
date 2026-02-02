#!/bin/bash
#===============================================================================
# BUILD MOONSTONE - MODO ULTRA SIMPLES E IMUNE
# Kernel: 5.4.302 - POCO X5 5G (SM6375)
# Versão: 2.0 - Rápida e Eficiente
#===============================================================================

set -e

# Diretórios
KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
OUT_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio/out"
LOG="${OUT_DIR}/build-$(date +%H%M%S).log"

# Criar out
mkdir -p "${OUT_DIR}"

echo "========================================"
echo "🚀 BUILD KERNEL MOONSTONE - MODO RÁPIDO"
echo "========================================"
echo "⏰ Início: $(date '+%H:%M:%S')"
echo "📁 Kernel: ${KERNEL_DIR}"
echo "📦 Output: ${OUT_DIR}"
echo ""

# Ir para kernel
cd "${KERNEL_DIR}"

# LIMPAR (mas manter defconfig)
echo "🧹 Limpando build anterior..."
make clean 2>/dev/null || true

# CONFIGURAR AMBIENTE
echo "⚙️ Configurando ambiente..."
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# IMPORTANTE: Usar LLVM/Clang do sistema com flags especiais
export LLVM=1
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# CRÍTICO: Ignorar warnings de formato (código da Qualcomm tem muitos)
export KCFLAGS="-D__ANDROID_COMMON_KERNEL__ -Wno-format -Wno-format-security"
export KBUILD_CFLAGS="${KCFLAGS}"

# CONFIGURAR KERNEL
echo "🔧 Carregando moonstone_defconfig..."
make moonstone_defconfig

echo ""
echo "📊 Info do kernel:"
grep "CONFIG_LOCALVERSION" .config | head -1
echo ""

# COMPILAR
echo "🔨 Compilando com $(nproc) jobs..."
echo "⏱️  Tempo estimado: 2-4 horas"
echo "   (Pressione Ctrl+C para cancelar)"
echo ""

if make -j$(nproc) Image.gz 2>&1 | tee "${LOG}"; then
    echo ""
    echo "✅ BUILD COMPLETO!"
    echo ""
    
    if [ -f "arch/arm64/boot/Image.gz" ]; then
        echo "📦 Kernel gerado:"
        ls -lh arch/arm64/boot/Image.gz
        
        # Copiar
        cp arch/arm64/boot/Image.gz "${OUT_DIR}/"
        cp .config "${OUT_DIR}/config-$(date +%H%M%S)"
        
        echo ""
        echo "📁 Arquivos em ${OUT_DIR}:"
        ls -lh "${OUT_DIR}"
        
        echo ""
        echo "🎉 SUCESSO! Use:"
        echo "   fastboot boot ${OUT_DIR}/Image.gz"
    else
        echo "❌ Kernel não encontrado"
        exit 1
    fi
else
    echo ""
    echo "❌ BUILD FALHOU!"
    echo "📝 Log: ${LOG}"
    echo ""
    echo "Últimas 20 linhas do erro:"
    tail -20 "${LOG}"
    exit 1
fi

echo ""
echo "⏰ Fim: $(date '+%H:%M:%S')"
