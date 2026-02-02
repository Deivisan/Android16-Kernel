#!/bin/bash
#===============================================================================
# BUILD OFICIAL - TOOLCHAIN EXATA DOS DEVS
# Android NDK r25c - Clang 14.0.7 (base r450784d1)
# Kernel: 5.4.302-moonstone
#===============================================================================

set -e

readonly KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
readonly TOOLCHAIN="/home/deivi/Projetos/Android16-Kernel/laboratorio/toolchain/google-clang-ndk"
readonly OUT_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio/out"
readonly LOG="$OUT_DIR/build-oficial-$(date +%H%M%S).log"

mkdir -p "$OUT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        🔥 BUILD OFICIAL - TOOLCHAIN DOS DEVS 🔥               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ Início: $(date '+%H:%M:%S - %d/%m/%Y')"
echo "📁 Kernel: moonstone 5.4.302"
echo "🔧 Toolchain: Android NDK r25c"
echo "⚡ Clang: $("$TOOLCHAIN/bin/clang" --version | head -1)"
echo ""

# Configurar TOOLCHAIN EXATA
cd "$KERNEL_DIR"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC="$TOOLCHAIN/bin/clang"
export CXX="$TOOLCHAIN/bin/clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export LD="$TOOLCHAIN/bin/ld.lld"
export NM="$TOOLCHAIN/bin/llvm-nm"
export OBJCOPY="$TOOLCHAIN/bin/llvm-objcopy"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CLANG_TRIPLE=aarch64-linux-android

export LLVM=1
export LLVM_IAS=1

# Flags oficiais dos devs
export KCFLAGS="-D__ANDROID_COMMON_KERNEL__ -Wno-format"
export KBUILD_BUILD_USER="deivison"
export KBUILD_BUILD_HOST="DeiviPC"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CONFIGURAÇÃO:"
echo "   CC=$CC"
echo "   LLVM=1"
echo "   ARCH=$ARCH"
echo "   KCFLAGS=$KCFLAGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
echo "🔥 INICIANDO BUILD COMPLETO..."
echo "   (2-4 horas estimado)"
echo "   Pressione Ctrl+C para cancelar"
echo ""
sleep 3

if make -j$(nproc) Image.gz 2>&1 | tee "$LOG"; then
    echo ""
    if [ -f "arch/arm64/boot/Image.gz" ]; then
        SIZE=$(ls -lh arch/arm64/boot/Image.gz | awk '{print $5}')
        SHA256=$(sha256sum arch/arm64/boot/Image.gz | cut -d' ' -f1)
        
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                    🎉 SUCESSO! 🎉                              ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "📦 Kernel: arch/arm64/boot/Image.gz"
        echo "📏 Tamanho: $SIZE"
        echo "🔐 SHA256: $SHA256"
        
        cp arch/arm64/boot/Image.gz "$OUT_DIR/"
        echo ""
        echo "✅ Copiado para: $OUT_DIR/Image.gz"
        echo ""
        echo "🚀 Testar no device:"
        echo "   adb reboot bootloader"
        echo "   fastboot boot $OUT_DIR/Image.gz"
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
