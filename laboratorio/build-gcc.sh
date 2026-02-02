#!/bin/bash
#===============================================================================
# BUILD COM GCC - ALTERNATIVA PARA KERNEL QUALCOMM 5.4
# GCC 15.1.0 - Mais tolerante com código legado
#===============================================================================

set -e

readonly KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
readonly OUT_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio/out"
readonly LOG="$OUT_DIR/build-gcc-$(date +%H%M%S).log"
readonly GCC_PREFIX="aarch64-linux-gnu"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🔥 BUILD COM GCC 15.1.0 🔥                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ $(date '+%H:%M:%S - %d/%m/%Y')"
echo "🔧 GCC: $(aarch64-linux-gnu-gcc --version | head -1)"
echo "📁 Kernel: $KERNEL_DIR"
echo ""

cd "$KERNEL_DIR"

# Configurar GCC
echo "⚙️  Configurando ambiente GCC..."
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE="${GCC_PREFIX}-"
export CC="${GCC_PREFIX}-gcc"
export LD="${GCC_PREFIX}-ld"
export AR="${GCC_PREFIX}-ar"
export NM="${GCC_PREFIX}-nm"
export OBJCOPY="${GCC_PREFIX}-objcopy"
export STRIP="${GCC_PREFIX}-strip"

# Desativar LLVM (usar GCC puro)
unset LLVM
unset LLVM_IAS

export KCFLAGS="-Wno-format"
export KBUILD_BUILD_USER="deivison"
export KBUILD_BUILD_HOST="DeiviPC"

echo "   CC=$CC"
echo "   CROSS_COMPILE=$CROSS_COMPILE"
echo "   ARCH=$ARCH"
echo ""

# Correções
echo "🔧 Aplicando correções..."
sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' arch/arm64/configs/moonstone_defconfig 2>/dev/null || true
echo "   ✅ FT3519T desativado"

# Limpar e configurar
echo ""
echo "🧹 Limpando build..."
make clean 2>&1 | tail -2

echo ""
echo "⚙️  Configurando kernel..."
make moonstone_defconfig 2>&1 | grep -E "configuration|written"

sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' .config 2>/dev/null || true

echo ""
echo "🔥 INICIANDO BUILD COM GCC..."
echo "   (2-4 horas estimado)"
echo ""

if make -j$(nproc) Image.gz 2>&1 | tee "$LOG"; then
    echo ""
    if [ -f "arch/arm64/boot/Image.gz" ]; then
        SIZE=$(ls -lh arch/arm64/boot/Image.gz | awk '{print $5}')
        echo "🎉 SUCESSO!"
        echo "   Kernel: arch/arm64/boot/Image.gz"
        echo "   Tamanho: $SIZE"
        cp arch/arm64/boot/Image.gz "$OUT_DIR/"
        echo "   ✅ Copiado para $OUT_DIR/Image.gz"
    else
        echo "❌ Falha - Image.gz não gerado"
        exit 1
    fi
else
    echo ""
    echo "❌ BUILD FALHOU"
    echo "📝 Log: $LOG"
    exit 1
fi
