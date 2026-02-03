#!/bin/bash
#===============================================================================
# BUILD COM GCC - VERSÃO ULTRA PERMISSIVA
# Desativa subsistemas problemáticos e usa flags máximas de tolerância
#===============================================================================

set -e

cd /home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔥 BUILD GCC - VERSÃO ULTRA PERMISSIVA 🔥                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Configuração
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=aarch64-linux-gnu-gcc

# Flags ultra permissivas - ignorar TODOS os warnings
export KCFLAGS="-Wno-format -Wno-error -Wno-implicit-fallthrough -Wno-misleading-indentation -Wno-all -w"
export KBUILD_CFLAGS="$KCFLAGS"

echo "⚙️  Configurando kernel..."
make clean >/dev/null 2>&1
make moonstone_defconfig >/dev/null 2>&1

# Desativar TODOS os subsistemas problemáticos
echo "🔧 Desativando subsistemas problemáticos..."

# Audio problemático
sed -i 's/CONFIG_SND_SOC_WCD937X=y/CONFIG_SND_SOC_WCD937X=n/g' .config
sed -i 's/CONFIG_SND_SOC_WCD938X=y/CONFIG_SND_SOC_WCD938X=n/g' .config

# RMNET problemático (tracing)
sed -i 's/CONFIG_RMNET=y/CONFIG_RMNET=n/g' .config

# FT3519T
echo "CONFIG_TOUCHSCREEN_FT3519T=n" >> .config

echo "✅ Configurado!"
echo ""
echo "🔥 INICIANDO BUILD..."
echo ""

if make -j$(nproc) Image.gz 2>&1 | tee /tmp/build-ultra.log; then
    if [ -f "arch/arm64/boot/Image.gz" ]; then
        echo ""
        echo "🎉 SUCESSO!"
        ls -lh arch/arm64/boot/Image.gz
        cp arch/arm64/boot/Image.gz /home/deivi/Projetos/Android16-Kernel/laboratorio/out/
    fi
else
    echo "❌ Falhou"
fi
